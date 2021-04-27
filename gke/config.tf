provider "google" {
  credentials = file("account.json")
  project     = var.projectid
  region      = var.region
}

data "google_client_config" "default" {
}

