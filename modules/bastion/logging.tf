# Create a log group for ssh access
resource "aws_cloudwatch_log_group" "ssh_access_log_group" {
  name              = "/aws/events/${var.name}-ssh-access"
  retention_in_days = 365
  kms_key_id        = data.aws_kms_key.default.arn
}

resource "aws_cloudwatch_event_rule" "ssh_access" {
  name        = "${var.name}-ssh-access"
  description = "filters ssm access logs and sends usable data to a cloudwatch log group"

  event_pattern = <<EOF
{
  "source": ["aws.ssm"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["ssm.amazonaws.com"],
    "eventName": ["IAMUser","StartSession"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "ssm_target" {
  rule      = aws_cloudwatch_event_rule.ssh_access.name
  target_id = "${var.name}-ssh-access-target"
  arn       = aws_cloudwatch_log_group.ssh_access_log_group.arn
}

# Create a cloudwatch agent configuration file and log group
resource "aws_ssm_parameter" "cloudwatch_configuration_file" {
  # checkov:skip=CKV_AWS_337: "Ensure SSM parameters are using KMS CMK" -- There is no sensitive data in this SSM parameter
  name      = "AmazonCloudWatch-linux-${var.name}"
  type      = "SecureString"
  overwrite = true
  value = jsonencode({
    "agent" : {
      "metrics_collection_interval" : 60,
      "run_as_user" : "root"
    },
    "logs" : {
      "logs_collected" : {
        "files" : {
          "collect_list" : [
            {
              "file_path" : "/root/.bash_history",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "root-user-commands",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/home/ec2-user/.bash_history",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "ec2-user-commands",
              "retention_in_days" : 60
            },

            {
              "file_path" : "/var/log/secure",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "logins",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/home/ssm-user/.bash_history",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "ssm-user-commands",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/var/log/messages",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "Syslog",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/var/log/boot.log*",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "Syslog",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/var/log/secure",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "Syslog",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/var/log/messages",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "Syslog",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/var/log/cron*",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "Syslog",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/var/log/cloud-init-output.log",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "Syslog",
              "retention_in_days" : 60
            },
            {
              "file_path" : "/var/log/dmesg",
              "log_group_name" : aws_cloudwatch_log_group.ec2_cloudwatch_logs.name,
              "log_stream_name" : "Syslog",
              "retention_in_days" : 60
            },
          ]
        }
      }
    },
    "metrics" : {
      "aggregation_dimensions" : [
        [
          "InstanceId"
        ]
      ],

      "metrics_collected" : {
        "collectd" : {
          "metrics_aggregation_interval" : 60
        },
        "cpu" : {
          "measurement" : [
            "cpu_usage_idle",
            "cpu_usage_iowait",
            "cpu_usage_user",
            "cpu_usage_system"
          ],
          "metrics_collection_interval" : 60,
          "resources" : [
            "*"
          ],
          "totalcpu" : false
        },
        "disk" : {
          "measurement" : [
            "used_percent",
            "inodes_free"
          ],
          "metrics_collection_interval" : 60,
          "resources" : [
            "*"
          ]
        },
        "diskio" : {
          "measurement" : [
            "io_time"
          ],
          "metrics_collection_interval" : 60,
          "resources" : [
            "*"
          ]
        },
        "mem" : {
          "measurement" : [
            "mem_used_percent"
          ],
          "metrics_collection_interval" : 60
        },
        "statsd" : {
          "metrics_aggregation_interval" : 60,
          "metrics_collection_interval" : 10,
          "service_address" : ":8125"
        },
        "swap" : {
          "measurement" : [
            "swap_used_percent"
          ],
          "metrics_collection_interval" : 60
        }
      }
    }
  })
}

resource "aws_cloudwatch_log_group" "ec2_cloudwatch_logs" {
  name              = "ec2-cloudwatch-logging-${var.name}"
  retention_in_days = 365
  kms_key_id        = data.aws_kms_key.default.arn
}

# Create cloudwatch log group for ssm
resource "aws_cloudwatch_log_group" "session_manager_log_group" {
  count             = var.enable_log_to_cloudwatch ? 1 : 0
  name_prefix       = "${var.cloudwatch_log_group_name}-"
  retention_in_days = var.cloudwatch_logs_retention
  kms_key_id        = data.aws_kms_key.default.arn

  tags = var.tags
}
