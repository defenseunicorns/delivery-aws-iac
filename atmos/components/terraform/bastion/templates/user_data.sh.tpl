#!/usr/bin/env bash
set -x

# TODO: Make this work in more AMIs than just Amazon Linux 2 (for example, on RHEL the amazon-cloudwatch-agent package doesn't exist)
echo "installing tools"

for i in {1..10}; do
  sudo yum update -y
  sudo yum install -y \
    amazon-cloudwatch-agent \
    docker \
    git \
    jq \
    unzip \
    wget
  if [ $? -eq 0 ]; then
    break
  else
    echo "Attempt $i failed. Retrying..."
  fi
done

# Install newer version of aws cli
sudo yum remove awscli -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo chmod -R 755 /usr/local/aws-cli/

export PATH="$PATH:/usr/local/bin"
echo 'export PATH=$PATH:/usr/local/bin' >> /root/.bashrc

##
## Enable SSM & SSH
##

THROW_AWAY_PASSWORD_DONT_USE_THIS_IN_PRODUCTION=${ssh_password}
SECRETS_MANAGER_SECRET_ID=${secrets_manager_secret_id}

cat <<"__EOF__" > /home/${ssh_user}/.ssh/config
Host *
    StrictHostKeyChecking no
__EOF__

if [  "${ssm_enabled}" = "true" ]
then
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
    systemctl status amazon-ssm-agent
    sudo sed -i '/PasswordAuthentication no/s/^/#/g' /etc/ssh/sshd_config
    sudo sed -i '/PasswordAuthentication yes/s/^#//g' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    if [[ -n "$${THROW_AWAY_PASSWORD_DONT_USE_THIS_IN_PRODUCTION}" ]]
    then
        echo "${ssh_user}:$${THROW_AWAY_PASSWORD_DONT_USE_THIS_IN_PRODUCTION}" | sudo chpasswd
    fi
    if [[ -n "$${SECRETS_MANAGER_SECRET_ID}" ]]
    then
        echo "Fetching password from Secrets Manager"
        aws secretsmanager get-secret-value --secret-id "$${SECRETS_MANAGER_SECRET_ID}" --query SecretString --output text | jq -r '."${ssh_user}"' | sudo passwd --stdin ${ssh_user} && echo "Password set for ${ssh_user} successfully" || echo "Failed to set password for ${ssh_user}"
    fi
else
    systemctl disable amazon-ssm-agent
    systemctl stop amazon-ssm-agent
    systemctl status amazon-ssm-agent
    chmod 600 /home/${ssh_user}/.ssh/config
    chown ${ssh_user}:${ssh_user} /home/${ssh_user}/.ssh/config
fi

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install flux
curl -s https://fluxcd.io/install.sh | sudo bash

# Download zarf binary and init package
wget -O /home/${ssh_user}/zarf https://github.com/defenseunicorns/zarf/releases/download/${zarf_version}/zarf_${zarf_version}_Linux_amd64
wget -O /home/${ssh_user}/zarf-init-amd64-${zarf_version}.tar.zst https://github.com/defenseunicorns/zarf/releases/download/${zarf_version}/zarf-init-amd64-${zarf_version}.tar.zst
chmod +x /home/${ssh_user}/zarf
cp /home/${ssh_user}/zarf /usr/bin/zarf
cp /home/${ssh_user}/zarf-init-amd64-${zarf_version}.tar.zst /usr/bin/zarf-init-amd64-${zarf_version}.tar.zst
chown -R ${ssh_user}:${ssh_user} /home/${ssh_user}/

# Download uds binary
wget -O /home/${ssh_user}/uds https://github.com/defenseunicorns/uds-cli/releases/download/${uds_cli_version}/uds-cli_${uds_cli_version}_Linux_amd64
chmod +x /home/${ssh_user}/uds
cp /home/${ssh_user}/uds /usr/bin/uds

# Create the /usr/share/collectd directory and types.db file
sudo mkdir -p /usr/share/collectd
sudo touch /usr/share/collectd/types.db

if [ "${enable_log_to_cloudwatch}" = "true" ]; then
  if aws ssm get-parameter --name "AmazonCloudWatch-linux-${ssm_parameter_name}" --output text &> /dev/null; then
    # Fetch the configuration from the SSM parameter store
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:AmazonCloudWatch-linux-${ssm_parameter_name} -s
  fi
fi

###StartUpScript###

sudo cat << '_EOF_' > /etc/profile.d/startupscript.sh
#!/bin/bash

{
    trap '' 2  #disable ctrl+c

    ###Script to check if exceeded maximum Session Manager Sessions and takes action
    {
        ###Configuration Options
        MAX_SESSIONS=${max_ssm_connections}  #Number of maximum sessions allowed
        TERMINATE_SESSIONS=true #This will terminate the sessions starting from the oldest; if set to false, it will list out the sessions IDs, but not terminate them
        TERMINATE_OLDEST=${terminate_oldest_ssm_connection_first} #true/false - if true, script will terminate the oldest session first. if false, the newest session will be terminated.
        #Terminating the newest session may result in poor experiance as there will be no message provided to the user.


        ###Logic
        MESSAGE="" #clears out message variable (mainly for debugging purposes in case script is run multiple times)

        ##Configure Reverse Logic
        REVERSE_LOGIC='| reverse'
        if [[ "$TERMINATE_OLDEST" = false ]]
        then
            REVERSE_LOGIC=''
        fi

        ##Get Instance details and configure aws region

        EC2_INSTANCE_ID=$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" )
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id )

        REGION=$(TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" )
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/region )
        aws configure set default.region $REGION


        ##Get All sessions for the instance and group by owner

        SESSION_INFO=$(aws ssm describe-sessions --state "Active" --filter "key=Target,value=$EC2_INSTANCE_ID" 2>&1)

        if [[ $? -gt 0 ]]  #An error has occured
        then
            MESSAGE="An Error has occured; ExitCode: $?, Details: $SESSION_INFO"
        else
            SESSIONS=$(jq '.Sessions | group_by(.Owner)' <<< $SESSION_INFO)
            SESSIONS_GROUP=$(jq 'length' <<< $SESSIONS)

            if [[ $SESSIONS_GROUP -gt 0 ]]
            then
                COUNTER=0
                MESSAGE_HEADER="Too many sessions found:"
                while [ $COUNTER -lt $SESSIONS_GROUP ]
                do
                    SESSION_COUNT=$(jq ".[$COUNTER] | length" <<< $SESSIONS)
                    if [ $SESSION_COUNT -gt $MAX_SESSIONS ]
                    then
                        SORTED=$(jq ".[$COUNTER] | sort_by(.StartDate) $REVERSE_LOGIC" <<< $SESSIONS)
                        while [ $SESSION_COUNT -gt $MAX_SESSIONS ]
                        do
                            TERMINATE_ROW=$(($SESSION_COUNT-1))
                            TERMINATE_SESSION=$(jq -r ".[$TERMINATE_ROW].SessionId" <<< $SORTED)

                            if [[ "$TERMINATE_SESSIONS" = true ]]
                            then
                                TERMINATOR=$(aws ssm terminate-session --session-id $TERMINATE_SESSION 2>&1)
                                echo "new line 233"
                                if [[ $? -gt 0 ]]  #An error has occured
                                then
                                    MESSAGE="An Error has occured; ExitCode: $?, Details: $TERMINATOR"
                                    break 2
                                fi
                                MESSAGE="$MESSAGE\n Terminated Session $TERMINATE_SESSION"
                            else
                                MESSAGE="$MESSAGE\n$TERMINATE_SESSION"
                            fi


                            SESSION_COUNT=$(($SESSION_COUNT-1))
                        done
                    fi
                    COUNTER=$((COUNTER+1))
                done
                if [[ ! -z "$MESSAGE" ]]
                then
                    MESSAGE=$MESSAGE_HEADER$MESSAGE
                fi
            else
                MESSAGE="No active sessions for this instance"
            fi
        fi
    }
    trap 2  #enable ctrl+c
    clear && echo -e $MESSAGE


}



_EOF_
sudo chmod +x /etc/profile.d/startupscript.sh

#Adjusting SSHD Config

sudo cat << '_EOF_' > /etc/ssh/sshd_config
#     $OpenBSD: sshd_config,v 1.100 2016/08/15 12:32:04 naddy Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

# If you want to change the port on a SELinux system, you have to tell
# SELinux about this change.
# semanage port -a -t ssh_port_t -p tcp #PORTNUMBER
#
#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
# HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
SyslogFacility AUTHPRIV
#LogLevel INFO

# Authentication:

LoginGraceTime 15m
#PermitRootLogin yes
StrictModes yes
MaxAuthTries 3
MaxSessions ${max_ssh_sessions}
MaxStartups 1:100:100
#PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile .ssh/authorized_keys

#AuthorizedPrincipalsFile none


# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
IgnoreUserKnownHosts yes
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
#PermitEmptyPasswords no
#PasswordAuthentication no

# Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes
ChallengeResponseAuthentication no

# Kerberos options
KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no
#KerberosUseKuserok yes

# GSSAPI options
GSSAPIAuthentication no
GSSAPICleanupCredentials no
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no
#GSSAPIEnablek5users no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
# WARNING: 'UsePAM no' is not supported in Red Hat Enterprise Linux and may cause several
# problems.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding no
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
PrintLastLog yes
#TCPKeepAlive yes
#UseLogin no
UsePrivilegeSeparation sandbox
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#ShowPatchLevel no
#UseDNS yes
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

# override default of no subsystems
Subsystem sftp  /usr/libexec/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server

AuthorizedKeysCommand /opt/aws/bin/eic_run_authorized_keys %u %f
AuthorizedKeysCommandUser ec2-instance-connect
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
# RhostsRSAAuthentication no
Compression no
X11UseLocalhost yes
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
ClientAliveInterval 14400
ClientAliveCountMax 0


_EOF_

#Restart SSHD

sudo service sshd restart

# Export ssh_user and zarf_version for use in additional user-data script
export ssh_user=${ssh_user}
export zarf_version=${zarf_version}

# Append addition user-data script
${additional_user_data_script}
