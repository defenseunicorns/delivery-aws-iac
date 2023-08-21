output "lambda_password_function_arn" {
  description = "Arn for lambda password function"
  value       = module.password_lambda[0].lambda_function_arn
}
