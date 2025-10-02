variable "env_prefix" {
  type = string
}

variable "account_id" {
  type = string
}

variable "self_sign_up_enabled" {
  type    = bool
  default = true
}

variable "cloudfront_domain" {
  type = string
}

variable "additional_callback_urls" {
  type    = list(string)
  default = ["http://localhost:5173"]
}

variable "additional_logout_urls" {
  type    = list(string)
  default = ["http://localhost:5173"]
}
