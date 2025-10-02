variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bedrock_region" {
  description = "AWS region where Bedrock is available"
  type        = string
  default     = "us-east-1"
}

variable "env_name" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = ""
}

variable "self_sign_up_enabled" {
  description = "Allow users to self sign up"
  type        = bool
  default     = true
}
