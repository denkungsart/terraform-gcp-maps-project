# GCP Maps project module

Creates a Google Cloud project with the Maps, Geocoding, and Places APIs and restricted server and browser API keys.

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
