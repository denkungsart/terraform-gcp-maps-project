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

variable "daily_request_caps" {
  description = "Requests per day the apps' Maps API methods accept: Maps JavaScript map loads, geocodes, all requests to the legacy Places API, and Autocomplete and Place Details requests to Places API (New). Requests over a cap fail until the quota resets at midnight Pacific time. The defaults leave room above the busiest installation's day from mid-October to late November 2026 (514 legacy Places requests, 896 geocodes, 106 Maps JavaScript loads), except filmmakers' 7,865 legacy Places requests."
  type = object({
    maps_javascript     = optional(number, 1000)
    geocoding           = optional(number, 3000)
    places_legacy       = optional(number, 3000)
    places_autocomplete = optional(number, 3000)
    places_details      = optional(number, 1000)
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for cap in values(var.daily_request_caps) : cap > 0 && floor(cap) == cap])
    error_message = "daily_request_caps must be positive whole numbers."
  }
}

variable "daily_request_cap_alert_email" {
  description = "Email address alerted when a Maps API rejects requests over its daily cap. Set to null to disable the alert."
  type        = string
  default     = null

  validation {
    condition     = var.daily_request_cap_alert_email == null || can(regex("^[^@[:space:]]+@[^@[:space:]]+$", var.daily_request_cap_alert_email))
    error_message = "daily_request_cap_alert_email must be a valid email address or null."
  }
}
