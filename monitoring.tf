locals {
  geocoding_request_metric = <<-PROMQL
    {"maps.googleapis.com/service/v2/request_count", monitored_resource="maps.googleapis.com/Api", service="geocoding-backend.googleapis.com"}
  PROMQL
}

resource "google_project_service" "monitoring_api" {
  count = var.geocoding_usage_alert == null ? 0 : 1

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
    display_name = "Hourly usage exceeds its rolling baseline"

    condition_prometheus_query_language {
      query = <<-PROMQL
        (
          sum(increase(${trimspace(local.geocoding_request_metric)}[1h]))
            > ${var.geocoding_usage_alert.multiplier}
              * (sum(increase(${trimspace(local.geocoding_request_metric)}[24h])) / 24)
        )
        and
        (
          sum(increase(${trimspace(local.geocoding_request_metric)}[1h]))
            > ${var.geocoding_usage_alert.minimum_hourly_requests}
        )
      PROMQL

      duration            = "0s"
      evaluation_interval = "300s"
      alert_rule          = "GeocodingUsageAboveBaseline"
      rule_group          = "google-maps-cost-guardrails"
    }
  }

  conditions {
    display_name = "Hourly usage exceeds its absolute ceiling"

    condition_prometheus_query_language {
      query = <<-PROMQL
        sum(increase(${trimspace(local.geocoding_request_metric)}[1h]))
          > ${var.geocoding_usage_alert.maximum_hourly_requests}
      PROMQL

      duration            = "0s"
      evaluation_interval = "300s"
      alert_rule          = "GeocodingUsageAboveCeiling"
      rule_group          = "google-maps-cost-guardrails"
    }
  }

  documentation {
    mime_type = "text/markdown"
    subject   = "Geocoding usage anomaly in ${google_project.this.project_id}"
    content   = <<-MARKDOWN
      Geocoding usage in `${google_project.this.project_id}` crossed a cost guardrail. It either:

      - exceeded ${var.geocoding_usage_alert.multiplier}x its trailing 24-hour hourly average while above ${var.geocoding_usage_alert.minimum_hourly_requests} requests/hour; or
      - exceeded the absolute ceiling of ${var.geocoding_usage_alert.maximum_hourly_requests} requests/hour.

      Check Google Maps Platform metrics for the responsible credential and method. Pause the triggering job or reduce the Geocoding API quota if the traffic is unintended.
    MARKDOWN
  }

  depends_on = [google_project_service.monitoring_api]
}
