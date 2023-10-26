# 12. centralized logging strategy

Date: 2023-10-25

## Status

Draft

## Context
https://github.com/defenseunicorns/delivery-aws-iac/discussions/223

https://github.com/defenseunicorns/delivery-aws-iac/issues/113

https://github.com/defenseunicorns/terraform-aws-uds-bastion/issues/60

Gathered from previous discussions:
- "We previously had a session_log and access_logs bucket in the bastion but I think only one of them did something and we planned to deprecated the other."
- "I think we need one centralized logging bucket per account that we retain for 30 days then rotate to glacier for 13 months. Everything is shipped there. "
- "We may want a cli logging bucket for the bastion to capture both cloudtrail events for when a platform admin authenticates with SSM and when / what cli commands are executed just to have it easily accessible. (this would only need 30 days to audit when changes were made to the environment."
- "We also have a logging bucket that gets created when someone deploys the cloudtrail module and a logging.tf in the delivery-aws-iac repo example. We may also be duplicating some functionality in the bastion example (edited)"
- "Update: actually it looks like the ssh logs changed to cloudwatch only in the bastion (i.e. we effectively deprecated the logging buckets functionality"

### Bucket References (7 modules)

`delivery-aws-iac/examples/complete/access-logging.tf`
```
resource "aws_s3_bucket" "access_log_bucket"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fdelivery-aws-iac+%22resource+%5C%22aws_s3_bucket%5C%22%22&type=code

---


`terraform-aws-uds-bastion/s3-buckets.tf`
```
resource "aws_s3_bucket" "session_logs_bucket"
```
`terraform-aws-uds-bastion/examples/complete/main.tf`
```
resource "aws_s3_bucket" "access_log_bucket"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-bastion%20%22resource%20%5C%22aws_s3_bucket%5C%22%22&type=code

---


`terraform-aws-uds-cloudtrail/s3-buckets.tf`
```
resource "aws_s3_bucket" "this"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-cloudtrail%20%22resource%20%5C%22aws_s3_bucket%5C%22%22&type=code

---


`terraform-aws-uds-eks/examples/complete/access-logging.tf`
```
resource "aws_s3_bucket" "access_log_bucket"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-eks%20%22resource%20%5C%22aws_s3_bucket%5C%22%22&type=code

---


`terraform-aws-uds-lambda/examples/complete/main.tf`
```
resource "aws_s3_bucket" "access_log_bucket"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-lambda%20%22resource%20%5C%22aws_s3_bucket%5C%22%22&type=code

---


`terraform-aws-uds-s3/main.tf`
```
resource "aws_s3_bucket_logging" "logging"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-s3%20aws_s3_bucket&type=code

---


`terraform-aws-uds-s3-irsa/s3-irsa/main.tf`
```
resource "aws_s3_bucket_logging" "logging"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-s3-irsa%20aws_s3_bucket_logging&type=code

---

### CloudWatch References (2 modules)

`terraform-aws-uds-bastion/logging.tf`
```
resource "aws_cloudwatch_log_group" "ssh_access_log_group"
resource "aws_cloudwatch_log_group" "ec2_cloudwatch_logs"
resource "aws_cloudwatch_log_group" "session_manager_log_group"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-bastion%20%22resource%20%5C%22aws_cloudwatch_log_group%5C%22%22&type=code

---

`terraform-aws-uds-cloudtrail/cloudwatch.tf`
```
resource "aws_cloudwatch_log_group" "this"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-cloudtrail%20%22resource%20%5C%22aws_cloudwatch_log_group%5C%22%22&type=code

---

### CloudTrail References (1 module)
`terraform-aws-uds-cloudtrail/main.tf`
```
resource "aws_cloudtrail" "this"
```
https://github.com/search?q=repo%3Adefenseunicorns%2Fterraform-aws-uds-cloudtrail%20%22resource%20%5C%22aws_cloudtrail%5C%22%22&type=code

---


* Do we want to move any redundancies (if there are any) to its own module?
* Do we have explicit requirements of what should be logged and at what level?
* Cluster level logs? (see https://github.com/defenseunicorns/delivery-aws-iac/issues/113)
* Retention policies and cost?
* Should everything be sent to a destination in S3?
* CloudWatch, CloudTrail as a middleman?
* Use of (extend beyond password rotation) lambda module for log transfers to S3?
* Other ideas?

## Decision

## Consequences

