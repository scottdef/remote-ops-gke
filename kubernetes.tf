terraform {
  backend "gcs" {
    bucket = "terraform-state-awx"
    prefix = "gke-terraform/state"
  }
}

provider "google" {
  project = "v2-dev-volusion"
  region  = "us-central1"
}

variable "location" {
  default     = "us-central-1"
  description = "region (us-central1) or zone ()"
  type        = "string"
}

resource "google_container_cluster" "k8s-cluster" {
  name                     = "remote-ops"
  remove_default_node_pool = true

  location = "${var.location}"

  master_auth {
    username = ""
    password = ""
  }

  logging_service    = "none"
  monitoring_service = "none"

  addons_config {
    http_load_balancing {
      disabled = true
    }
  }

  initial_node_count = 1
}

resource "google_container_node_pool" "worker" {
  name       = "worker"
  location   = "${var.location}"
  cluster    = "${google_container_cluster.k8s-cluster.name}"
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n2-standard-8"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

output "cluster_name" {
  value = "${google_container_cluster.k8s-cluster.name}"
}

output "location" {
  value = "${google_container_cluster.k8s-cluster.location}"
}
resource "google_storage_bucket" "image-store" {
  name     = "vault1234"
  location = "US"
}