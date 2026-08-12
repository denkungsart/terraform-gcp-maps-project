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

variable "geocoding_usage_alert" {
  description = "Optional Geocoding usage anomaly alert configuration. Set to null to disable the alert."
  type = object({
    email_address           = string
    multiplier              = optional(number, 3)
    minimum_hourly_requests = optional(number, 100)
    maximum_hourly_requests = optional(number, 1000)
  })
  default = null

  validation {
    condition = var.geocoding_usage_alert == null || try(
      can(regex("^[^@[:space:]]+@[^@[:space:]]+$", var.geocoding_usage_alert.email_address)) &&
      var.geocoding_usage_alert.multiplier > 1 &&
      var.geocoding_usage_alert.minimum_hourly_requests > 0 &&
      var.geocoding_usage_alert.maximum_hourly_requests >= var.geocoding_usage_alert.minimum_hourly_requests,
      false
    )
    error_message = "geocoding_usage_alert must contain a valid email address, a multiplier greater than 1, and positive thresholds with maximum_hourly_requests greater than or equal to minimum_hourly_requests."
  }
}
