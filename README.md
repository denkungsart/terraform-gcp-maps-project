# GCP Maps project module

Creates a Google Cloud project with the Maps, Geocoding, Places and Places (New) APIs, restricted server and browser API keys, and daily request caps.

## Geocoding cost guardrail

Set `geocoding_usage_alert` to create an email notification channel and a Cloud Monitoring alert:

```hcl
geocoding_usage_alert = {
  email_address = "alerts@example.com"

  # Optional defaults:
  multiplier              = 3
  minimum_hourly_requests = 100
  maximum_hourly_requests = 1000
}
```

The policy is evaluated every five minutes. It alerts when the rolling one-hour Geocoding request count is above both `minimum_hourly_requests` and `multiplier` times the hourly average of the preceding 23 hours. The current hour is left out of that baseline so a burst does not raise its own threshold; with no traffic in the preceding 23 hours, any hour above `minimum_hourly_requests` alerts. The absolute `maximum_hourly_requests` ceiling also alerts independently, preventing sustained high traffic from becoming the new baseline.

This is an alert, not a hard usage or spending cap. Set an appropriate Geocoding API quota separately if requests should be rejected after a fixed limit.

## Daily request caps

Google Cloud has no spending cap, so the module caps the requests per day of the billed Maps APIs. Requests over a cap fail until the quota resets at midnight Pacific time instead of being billed, which also limits a leaked or misused key. The Maps Embed API is free and has no cap.

The keys allow whole APIs, not single methods, and each API has several per-day quotas, unlimited or high by default: Places API (New) has one per method (Autocomplete, Place Details, Text Search, Nearby Search, photos, ...), the Geocoding API has its v4 methods, the Maps JavaScript API its 3D maps. `quotas.tf` sets all of them. The methods the apps call get `daily_request_caps`:

```hcl
daily_request_caps = {
  # Defaults:
  maps_javascript     = 1000 # map loads
  geocoding           = 3000 # Geocoding API (v3)
  places_legacy       = 3000 # all requests to the legacy Places API
  places_autocomplete = 3000 # Places API (New): Autocomplete
  places_details      = 1000 # Places API (New): Place Details
}

daily_request_cap_alert_email = "alerts@example.com"
```

All other per-day quotas are set to 0, which rejects every request to those methods. A new method the apps start calling needs its cap in `quotas.tf` first.

The defaults leave room above the busiest installation's day from mid-October to late November 2026: 514 legacy Places requests, 896 geocodes and 106 Maps JavaScript loads. filmmakers had 7,865 legacy Places requests on its busiest day and sets higher caps. The place inputs averaged about 6 suggestion requests per picked place, so Place Details gets a lower cap than Autocomplete.

Google sends nothing when a cap is reached. Set `daily_request_cap_alert_email` to get an email when a Maps API rejects requests over a quota. That includes any request to a method capped at 0, which nothing of ours calls, and requests over Google's per-minute limits.

If a project already has a quota preference for one of these quotas, set by hand in the console, import it before applying: `terraform import 'module.<name>.google_cloud_quotas_quota_preference.daily_requests["<service>/<quota ID>"]' projects/<project>/locations/global/quotaPreferences/<id>`.
