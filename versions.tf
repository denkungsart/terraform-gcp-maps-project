terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.9, < 9.0"
    }
  }

  required_version = ">= 1.6.0"
}
