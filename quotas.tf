# Daily request caps are the hard limit on what the keys can cost: requests over
# a cap fail until the quota resets at midnight Pacific time, instead of being
# billed. They also limit a leaked or misused key.
#
# The keys allow whole APIs, not single methods, and the APIs' per-day quotas
# are unlimited or high by default. So every one of them is set here: the
# methods the apps call get `var.daily_request_caps`, the others 0, which
# rejects all their requests. The Maps Embed API is free and has no cap.
locals {
  daily_request_caps = {
    "maps-backend.googleapis.com/BillableDefaultPerDayPerProject"           = var.daily_request_caps.maps_javascript
    "maps-backend.googleapis.com/3DBillableDefaultPerDayPerProject"         = 0
    "maps-backend.googleapis.com/MapsGroundingWidgetPerDayPerProject"       = 0
    "geocoding-backend.googleapis.com/BillableDefaultPerDayPerProject"      = var.daily_request_caps.geocoding
    "geocoding-backend.googleapis.com/V4GeocodeAddressPerDayPerProject"     = 0
    "geocoding-backend.googleapis.com/V4GeocodeLocationPerDayPerProject"    = 0
    "geocoding-backend.googleapis.com/V4GeocodePlacePerDayPerProject"       = 0
    "geocoding-backend.googleapis.com/V4SearchDestinationsPerDayPerProject" = 0
    "places-backend.googleapis.com/BillableDefaultPerDayPerProject"         = var.daily_request_caps.places_legacy
    "places-backend.googleapis.com/BillableReviewswidgetPerDayPerProject"   = 0
    "places.googleapis.com/AutocompletePlacesRequestPerDayPerProject"       = var.daily_request_caps.places_autocomplete
    "places.googleapis.com/GetPlaceRequestPerDayPerProject"                 = var.daily_request_caps.places_details
    "places.googleapis.com/GetPhotoMediaRequestPerDayPerProject"            = 0
    "places.googleapis.com/LookupMediaRequestPerDayPerProject"              = 0
    "places.googleapis.com/LookupReviewPostsRequestPerDayPerProject"        = 0
    "places.googleapis.com/LookupUserContentSummaryRequestPerDayPerProject" = 0
    "places.googleapis.com/SearchMediaRequestPerDayPerProject"              = 0
    "places.googleapis.com/SearchNearbyRequestPerDayPerProject"             = 0
    "places.googleapis.com/SearchReviewPostsRequestPerDayPerProject"        = 0
    "places.googleapis.com/SearchTextRequestPerDayPerProject"               = 0
  }

  daily_request_cap_services = distinct([for quota in keys(local.daily_request_caps) : split("/", quota)[0]])
}

resource "google_project_service" "cloud_quotas_api" {
  project            = google_project.this.project_id
  service            = "cloudquotas.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloud_quotas_quota_preference" "daily_requests" {
  for_each = local.daily_request_caps

  parent   = "projects/${google_project.this.project_id}"
  service  = split("/", each.key)[0]
  quota_id = split("/", each.key)[1]

  quota_config {
    preferred_value = tostring(each.value)
  }

  # The caps lower an unlimited quota, which Google otherwise refuses as a
  # decrease of more than 10%.
  ignore_safety_checks = "QUOTA_DECREASE_PERCENTAGE_TOO_HIGH"

  depends_on = [
    google_project_service.cloud_quotas_api,
    google_project_service.geocoding_api,
    google_project_service.maps_javascript_api,
    google_project_service.places_api,
    google_project_service.places_api_new
  ]
}
