resource "google_project" "this" {
  name            = var.project_name
  project_id      = var.project_id
  folder_id       = var.folder_id
  billing_account = var.billing_account
}

resource "google_project_iam_audit_config" "all_services" {
  project = google_project.this.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_project_service" "geocoding_api" {
  project                    = google_project.this.project_id
  service                    = "geocoding-backend.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "maps_javascript_api" {
  project                    = google_project.this.project_id
  service                    = "maps-backend.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "maps_embed_api" {
  project                    = google_project.this.project_id
  service                    = "maps-embed-backend.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "translate_api" {
  project                    = google_project.this.project_id
  service                    = "translate.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "places_api" {
  project                    = google_project.this.project_id
  service                    = "places-backend.googleapis.com"
  disable_dependent_services = true
}

resource "google_apikeys_key" "server" {
  display_name = "server"
  name         = "server"
  project      = google_project.this.project_id

  depends_on = [
    google_project_service.geocoding_api,
    google_project_service.maps_javascript_api,
    google_project_service.translate_api,
    google_project_service.places_api
  ]

  restrictions {
    api_targets {
      service = "translate.googleapis.com"
    }

    api_targets {
      service = "geocoding-backend.googleapis.com"
    }

    api_targets {
      service = "maps-backend.googleapis.com"
    }

    api_targets {
      service = "places-backend.googleapis.com"
    }
  }
}

resource "google_apikeys_key" "client" {
  display_name = "client"
  name         = "client"
  project      = google_project.this.project_id

  depends_on = [
    google_project_service.places_api,
    google_project_service.maps_javascript_api,
    google_project_service.maps_embed_api
  ]

  restrictions {
    api_targets {
      service = "maps-backend.googleapis.com"
    }

    api_targets {
      service = "maps-embed-backend.googleapis.com"
    }

    api_targets {
      service = "places-backend.googleapis.com"
    }

    browser_key_restrictions {
      allowed_referrers = var.client_key_allowed_referrers
    }
  }
}
