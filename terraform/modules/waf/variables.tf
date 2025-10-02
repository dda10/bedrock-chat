variable "env_prefix" {
  type = string
}

variable "create_cognito_waf" {
  type    = bool
  default = false
}

variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}

variable "api_allowed_ip_ranges" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
