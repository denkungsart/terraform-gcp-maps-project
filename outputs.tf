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
