variable "name" {
  type        = string
  description = "Name for various resources"
}

variable "log_retention_in_days" {
  type        = number
  description = "Days to keep logs"
  default     = 7
}

variable "permission_boundary" {
  type        = string
  description = "IAM Role Permission Boundary Policy"
  default     = null
}

variable "cron_schedule" {
  type        = string
  description = "Cron schedule for the target manager function"
  default     = "cron(0/5 * * * ? *)"
}

variable "fqdn_tag" {
  type        = string
  description = "Tag to use for FQDNs"
  default     = "FQDN"
}