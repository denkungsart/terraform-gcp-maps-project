variable "project_name" {
  description = "GCP project display name"
  type        = string
}

variable "project_id" {
  description = "GCP project ID (globally unique)"
  type        = string
}

variable "folder_id" {
  description = "GCP folder to create project in"
  type        = string
}

variable "billing_account" {
  description = "GCP billing account ID"
  type        = string
}

variable "client_key_allowed_referrers" {
  description = "Browser referrer restrictions for client API key"
  type        = list(string)
}
