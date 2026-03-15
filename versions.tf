terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.5"
    }
  }

  required_version = ">= 1.6.0"
}
