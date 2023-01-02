output "sops_policy_arn" {
  description = "ARN of the SOPS policy"
  value       = aws_iam_policy.sops_policy.arn
}
  
