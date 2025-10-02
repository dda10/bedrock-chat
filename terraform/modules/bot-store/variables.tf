variable "env_prefix" {
  type = string
}

variable "bot_table_arn" {
  type = string
}

variable "conversation_table_arn" {
  type = string
}

variable "enable_replicas" {
  type    = bool
  default = false
}
