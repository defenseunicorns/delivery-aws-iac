import boto3
import string
import os
import json
import logging
from botocore.exceptions import WaiterError
from botocore.exceptions import ClientError
import random
import http.client
import json

ssm_client = boto3.client('ssm')
ec2_client = boto3.client('ec2')
secrets_manager_client = boto3.client('secretsmanager')
sts_client = boto3.client("sts")

AWS_REGION = os.environ['AWS_REGION']


# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def is_windows_instance(instance):
    response = ec2_client.describe_images(ImageIds=[instance['ImageId']])
    image = response['Images'][0]
    platform_details = image.get('PlatformDetails')

    if platform_details is not None and 'windows' in platform_details.lower():
        return True
    else:
        return False


def does_user_exist(instance, username):
    logger.info(f"Verifying user '{username}' exists on instance {instance['InstanceId']}")
    is_windows = is_windows_instance(instance)
    if is_windows:
        ssm_command = f"Invoke-Command -ScriptBlock {{ Get-WmiObject -Class Win32_UserAccount | Where-Object {{$_.Name -eq '{username}'}} }}"
        document_name = 'AWS-RunPowerShellScript'
    else:
        ssm_command = f"getent passwd {username}"
        document_name = 'AWS-RunShellScript'

    response = ssm_client.send_command(
        InstanceIds=[instance['InstanceId']],
        DocumentName=document_name,
        Parameters={'commands': [ssm_command]},
    )

    command_id = response['Command']['CommandId']

    waiter = ssm_client.get_waiter('command_executed')
    try:
        waiter.wait(CommandId=command_id, InstanceId=instance['InstanceId'])
    except WaiterError as e:
        error_message = str(e)
        if 'terminal failure state' in error_message:
            logger.error(f"SSM command execution failed potentially due to user not being found on instance: {error_message}")
            return False
        else:
            raise e

    response = ssm_client.get_command_invocation(
        CommandId=command_id,
        InstanceId=instance['InstanceId'],
    )

    if response['Status'] == 'Success':
        if is_windows:
            user_exists = response['StandardOutputContent'].strip() != ""
        else:
            user_exists = response['StandardOutputContent'].strip() != ""
        if user_exists:
            logger.info(f"User {username} exists on instance {instance['InstanceId']}")
        else:
            logger.info(f"User {username} DOES NOT exist on instance {instance['InstanceId']}")
        return user_exists
    else:
        error_message = response.get('ErrorMessage', 'Unknown error')
        logger.error(f"SSM command execution failed: {error_message}")
        return False


def change_user_password(instance, username, new_password):
    logger.info(f"Changing password for user '{username}' on instance {instance['InstanceId']}")
    is_windows = is_windows_instance(instance)

    if is_windows:
        ssm_command_parameter_name = f"CommandWindows"
        ssm_command_template = "net user {username} '{new_password}'"
        document_name = 'AWS-RunPowerShellScript'
    else:
        ssm_command_parameter_name = f"CommandLinux"
        ssm_command_template = "echo '{new_password}' | passwd {username} --stdin"
        document_name = 'AWS-RunShellScript'

    ssm_client = boto3.client('ssm')

    ssm_command = retrieve_ssm_command_from_parameter_store(ssm_command_parameter_name, {'new_password': new_password, 'username': username})

    if ssm_command is None:
        # SSM command not found in Parameter Store, create and store it
        ssm_command = ssm_command_template.format(new_password=new_password, username=username)
        store_ssm_command_in_parameter_store(ssm_command_parameter_name, ssm_command)
    else:
        # Update the existing parameter with the new command
        ssm_command = ssm_command_template.format(new_password=new_password, username=username)
        update_ssm_command_in_parameter_store(ssm_command_parameter_name, ssm_command)

    response = ssm_client.send_command(
        InstanceIds=[instance['InstanceId']],
        DocumentName=document_name,
        Parameters={'commands': [ssm_command]},
    )

    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        logger.error(f"Error executing password change command on instance {instance['InstanceId']}")
        return False
    else:
        logger.info(f"Password changed successfully for user {username} on instance {instance['InstanceId']}")
        return True


def store_ssm_command_in_parameter_store(parameter_name, ssm_command):
    ssm_client = boto3.client('ssm')

    response = ssm_client.put_parameter(
        Name=parameter_name,
        Description='SSM command for EC2 instance',
        Value=ssm_command,
        Type='SecureString',
        Overwrite=True
    )

    print(f"Parameter '{parameter_name}' created or updated successfully.")


def update_ssm_command_in_parameter_store(parameter_name, ssm_command):
    ssm_client = boto3.client('ssm')

    response = ssm_client.put_parameter(
        Name=parameter_name,
        Description='SSM command for EC2 instance',
        Value=ssm_command,
        Type='SecureString',
        Overwrite=True
    )

    print(f"Parameter '{parameter_name}' updated successfully.")


def retrieve_ssm_command_from_parameter_store(parameter_name, parameters):
    ssm_client = boto3.client('ssm')

    try:
        response = ssm_client.get_parameter(Name=parameter_name, WithDecryption=True)
        ssm_command = response['Parameter']['Value']
    except ssm_client.exceptions.ParameterNotFound:
        ssm_command = None

    return ssm_command

def create_instance_secrets(instance, passwords):
    secret_name = f"{instance['InstanceId']}"
    secret_value = {}

    for username, password in passwords.items():
        secret_value[username] = password

    secret_arn = None

    try:
        # Check if the secret exists
        response = secrets_manager_client.describe_secret(SecretId=secret_name)
        secret_arn = response['ARN']

        # Update the existing secret
        secrets_manager_client.update_secret(
            SecretId=secret_name,
            SecretString=json.dumps(secret_value)
        )

        logger.info(f"Instance secrets updated for {instance['InstanceId']}")
    except secrets_manager_client.exceptions.ResourceNotFoundException:
        # Secret does not exist, create a new one
        secrets_manager_client.create_secret(
            Name=secret_name,
            SecretString=json.dumps(secret_value)
        )

    logger.info(f"Instance secrets created for {instance['InstanceId']}")



def send_to_slack(response_message):
    slack_webhook_url = os.environ.get('slack_webhook_url')
    slack_notification_enabled = os.environ.get('slack_notification_enabled', 'false').lower() == 'true'

    if not slack_notification_enabled:
        logger.info("Slack notifications are disabled.")
        return

    if not slack_webhook_url:
        logger.error("SLACK_WEBHOOK_URL is not set.")
        return
    # Ensure the URL is properly formatted
    if "://" not in slack_webhook_url:
        logger.error(f"Invalid webhook URL format: {slack_webhook_url}")
        return

    parts = slack_webhook_url.split("://", 1)
    if "/" in parts[1]:
        domain, path = parts[1].split("/", 1)
    else:
        domain = parts[1]
        path = ""

    headers = {
        'Content-Type': 'application/json',
    }

    body = {
        "text": response_message
    }

    connection = http.client.HTTPSConnection(domain)
    connection.request("POST", "/" + path, json.dumps(body), headers)
    response = connection.getresponse()

    if response.status != 200:
        logger.error(f"Failed to send message to Slack. Status: {response.status}, Reason: {response.reason}")
    else:
        logger.info("Message sent to Slack successfully!")

def get_instance_name(instance):
    """Return the Name of the instance from its Tags, or its ID if Name is not found."""
    tags = instance.get('Tags', [])
    for tag in tags:
        if tag.get('Key') == 'Name':
            return tag.get('Value')
    return instance.get('InstanceId')


def lambda_handler(event, context):

    users = os.environ.get('users', '').split(',')
    instance_ids = os.environ.get('instance_ids', '').split(',')
    successful_rotations = []

    for instance_id in instance_ids:
        try:
            instance = ec2_client.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'][0]
            passwords = {}

            for user in users:
                if does_user_exist(instance, user):
                    length = 14
                    uppercase_letters = string.ascii_uppercase
                    lowercase_letters = string.ascii_lowercase
                    digits = string.digits
                    special_characters = "!@#$%&*+=-<?"

                    # Ensure at least one character from each set is included in the password
                    new_password = (
                        random.choice(uppercase_letters)
                        + random.choice(lowercase_letters)
                        + random.choice(digits)
                        + random.choice(special_characters)
                    )

                    # Fill the remaining characters randomly from all character sets
                    new_password += ''.join(
                        random.choice(uppercase_letters + lowercase_letters + digits + special_characters)
                        for _ in range(length - 4)
                    )

                    # Shuffle the characters to make the password more random
                    new_password = ''.join(random.sample(new_password, len(new_password)))

                    if change_user_password(instance, user, new_password):
                        passwords[user] = new_password

            if passwords:
                create_instance_secrets(instance, passwords)

                instance_name = next((tag['Value'] for tag in instance['Tags'] if tag['Key'] == 'Name'), instance_id)
                success_message = f"Password was rotated successfully for instance {instance_name}."
                successful_rotations.append(success_message)

        except ClientError as e:
            if e.response['Error']['Code'] == 'InvalidInstanceId':
                error_message = f"Error: Cannot connect to SSM agent on the instance {instance_id}. Ensure the SSM agent is running and the instance is in a valid state."
                logger.error(error_message)
                send_to_slack(error_message)
            else:
                # Handle other boto3 exceptions
                error_message = f"Unexpected error: {e}"
                logger.error(error_message)
                send_to_slack(error_message)

    try:
        if successful_rotations:
            slack_message = "\n\n".join(successful_rotations)
            send_to_slack(slack_message)
        else:
            send_to_slack(f"No password rotations were successful in region {AWS_REGION}.")
    except Exception as e:
        error_message = f"Error during password rotation: {e}"
        logger.error(error_message)
        send_to_slack(error_message)  # Send an error message to Slack
        return {
            'statusCode': 500,
            'body': error_message
        }

    return {
        'statusCode': 200,
        'body': f"Password rotation successful for region {AWS_REGION}."
    }
