locals {
  geocoding_request_metric = <<-PROMQL
    {"maps.googleapis.com/service/v2/request_count", monitored_resource="maps.googleapis.com/Api", service="geocoding-backend.googleapis.com"}
  PROMQL
}

resource "google_project_service" "monitoring_api" {
  count = var.geocoding_usage_alert == null && var.daily_request_cap_alert_email == null ? 0 : 1

  project            = google_project.this.project_id
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_monitoring_notification_channel" "geocoding_usage_email" {
  count = var.geocoding_usage_alert == null ? 0 : 1

  project      = google_project.this.project_id
  display_name = "Geocoding usage alerts"
  type         = "email"

  labels = {
    email_address = var.geocoding_usage_alert.email_address
  }

  depends_on = [google_project_service.monitoring_api]
}

resource "google_monitoring_alert_policy" "geocoding_usage" {
  count = var.geocoding_usage_alert == null ? 0 : 1

  project               = google_project.this.project_id
  display_name          = "Geocoding usage anomaly"
  combiner              = "OR"
  severity              = "WARNING"
  notification_channels = [google_monitoring_notification_channel.geocoding_usage_email[0].name]

  conditions {
    display_name = "Hourly usage exceeds its baseline or ceiling"

    condition_prometheus_query_language {
      query = <<-PROMQL
        (
          (
            sum(increase(${trimspace(local.geocoding_request_metric)}[1h]))
              > ${var.geocoding_usage_alert.multiplier}
                * (
                  (sum(increase(${trimspace(local.geocoding_request_metric)}[23h] offset 1h)) or vector(0))
                    / 23
                )
          )
          and
          (
            sum(increase(${trimspace(local.geocoding_request_metric)}[1h]))
              > ${var.geocoding_usage_alert.minimum_hourly_requests}
          )
        )
        or
        (
          sum(increase(${trimspace(local.geocoding_request_metric)}[1h]))
            > ${var.geocoding_usage_alert.maximum_hourly_requests}
        )
      PROMQL

      duration            = "0s"
      evaluation_interval = "300s"
      alert_rule          = "GeocodingUsageAnomaly"
      rule_group          = "google-maps-cost-guardrails"
    }
  }

  documentation {
    mime_type = "text/markdown"
    subject   = "Geocoding usage anomaly in ${google_project.this.project_id}"
    content   = <<-MARKDOWN
      Geocoding usage in `${google_project.this.project_id}` crossed a cost guardrail. It either:

      - exceeded ${var.geocoding_usage_alert.multiplier}x the hourly average of the preceding 23 hours while above ${var.geocoding_usage_alert.minimum_hourly_requests} requests/hour; or
      - exceeded the absolute ceiling of ${var.geocoding_usage_alert.maximum_hourly_requests} requests/hour.

      Check Google Maps Platform metrics for the responsible credential and method. Pause the triggering job or reduce the Geocoding API quota if the traffic is unintended.
    MARKDOWN
  }

  depends_on = [google_project_service.monitoring_api]
}

# Google sends nothing when a daily request cap is reached: the API keeps
# rejecting requests until the quota resets.
resource "google_monitoring_notification_channel" "daily_request_cap_email" {
  count = var.daily_request_cap_alert_email == null ? 0 : 1

  project      = google_project.this.project_id
  display_name = "Daily request cap alerts"
  type         = "email"

  labels = {
    email_address = var.daily_request_cap_alert_email
  }

  depends_on = [google_project_service.monitoring_api]
}

resource "google_monitoring_alert_policy" "daily_request_cap" {
  count = var.daily_request_cap_alert_email == null ? 0 : 1

  project               = google_project.this.project_id
  display_name          = "Daily request cap reached"
  combiner              = "OR"
  severity              = "ERROR"
  notification_channels = [google_monitoring_notification_channel.daily_request_cap_email[0].name]

  conditions {
    display_name = "A Maps API rejected requests over a quota"

    condition_threshold {
      filter          = "resource.type = \"consumer_quota\" AND metric.type = \"serviceruntime.googleapis.com/quota/exceeded\" AND resource.labels.service = one_of(${join(", ", [for service in local.daily_request_cap_services : "\"${service}\""])})"
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_COUNT_TRUE"
      }

      trigger {
        count = 1
      }
    }
  }

  alert_strategy {
    auto_close = "86400s"
  }

  documentation {
    mime_type = "text/markdown"
    subject   = "Daily request cap reached in ${google_project.this.project_id}"
    content   = <<-MARKDOWN
      A Maps API in `${google_project.this.project_id}` rejected requests over a quota. Usually a daily request cap was reached: the API rejects further requests until the quota resets at midnight Pacific time, and maps, place inputs or geocoding fail for the installation until then.

      A method the apps don't use, such as Text Search, has a cap of 0, so a single request to it alerts too. Nothing of ours calls those methods: suspect a leaked key. A per-minute quota (Google's default rate limits) also alerts when it is exceeded.

      Check Google Maps Platform metrics for the API, method and credential. If the traffic is legitimate, raise the installation's `daily_request_caps`; if not, find and stop its source, and rotate the key if it leaked.
    MARKDOWN
  }

  depends_on = [google_project_service.monitoring_api]
}
