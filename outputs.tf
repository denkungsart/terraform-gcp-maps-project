output "project_id" {
  description = "The GCP project ID"
  value       = google_project.this.project_id
}

output "server_key_string" {
  description = "Server API key string"
  value       = google_apikeys_key.server.key_string
  sensitive   = true
}

output "client_key_string" {
  description = "Client API key string"
  value       = google_apikeys_key.client.key_string
  sensitive   = true
}

output "geocoding_usage_alert_policy_name" {
  description = "Resource name of the optional Geocoding usage alert policy"
  value       = try(google_monitoring_alert_policy.geocoding_usage[0].name, null)
}
