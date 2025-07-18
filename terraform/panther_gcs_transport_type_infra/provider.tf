terraform {
  required_version = ">= 1.1.7, < 2.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.16.0, < 5.0.0"
    }
  }
}
