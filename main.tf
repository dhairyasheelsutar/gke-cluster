################### Define Resources here #####################

locals {
  apis = ["container.googleapis.com", "compute.googleapis.com"]
}

# Enabling the APIs
resource "google_project_service" "apis" {
  project                    = var.project
  count                      = length(local.apis)
  service                    = local.apis[count.index]
  disable_dependent_services = true
}

# Create VPC & Subnet if required
module "vpc" {
  source       = "terraform-google-modules/network/google"
  version      = "6.0.0"
  count        = var.vpc == null ? 1 : 0
  project_id   = var.project
  network_name = "gke-vpc"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name           = "gke-subnet-uc1-01"
      subnet_ip             = "10.0.0.0/24"
      subnet_region         = "us-central1"
      subnet_private_access = true
    }
  ]

  secondary_ranges = {
    gke-subnet-uc1-01 = [
      {
        range_name    = "gke-subnet-uc1-01-pods-01"
        ip_cidr_range = "100.64.0.0/17"
      },
      {
        range_name    = "gke-subnet-uc1-01-services-01"
        ip_cidr_range = "100.64.128.0/23"
      },
    ]
  }

  depends_on = [
    google_project_service.apis
  ]
}

module "cloud-nat" {
  source        = "terraform-google-modules/cloud-nat/google"
  count         = var.vpc == null ? 1 : 0
  version       = "2.2.1"
  project_id    = var.project
  region        = var.region
  create_router = true
  router        = "gke-nat-router-uc1-01"
  network       = module.vpc[0].network_id
}

data "http" "cloud-shell-ip" {
  method = "GET"
  url = "http://ipinfo.io/ip"
}

# Deploy private gke cluster
module "gke_vpc" {
  source                             = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  count = var.vpc == null ? 1 : 0
  name                               = "gke-cluster-uc1-01"
  project_id                         = var.project
  regional                           = true
  region                             = var.region
  network_project_id                 = ""
  network                            = module.vpc[0].network_name
  subnetwork                         = "gke-subnet-uc1-01"
  ip_range_pods                      = "gke-subnet-uc1-01-pods-01"
  ip_range_services                  = "gke-subnet-uc1-01-services-01"
  http_load_balancing                = true
  enable_resource_consumption_export = true
  horizontal_pod_autoscaling         = true
  network_policy                     = true
  enable_private_nodes               = true
  enable_private_endpoint            = false
  master_ipv4_cidr_block             = "172.16.0.0/28"
  grant_registry_access              = true
  master_authorized_networks         = [{cidr_block = "${data.http.cloud-shell-ip.response_body}/32", display_name = "cloud-shell"}]
  create_service_account             = false
  node_pools = [
    {
      name            = "node-pool-1"
      machine_type    = "n1-standard-1"
      min_count       = 1
      max_count       = 3
      disk_size_gb    = 50
      image_type      = "COS_CONTAINERD"
      disk_type       = "pd-standard"
      preemptible     = false
      service_account = ""
      autoscaling     = true
    }
  ]

  depends_on = [
    module.vpc
  ]

}

module "gke_no_vpc" {
  source                             = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  count = var.vpc == null ? 0 : 1
  name                               = "gke-cluster-uc1-01"
  project_id                         = var.project
  regional                           = true
  region                             = var.region
  network_project_id                 = ""
  network                            = var.vpc
  subnetwork                         = var.subnet
  ip_range_pods                      = var.ip_range_pods
  ip_range_services                  = var.ip_range_services
  http_load_balancing                = true
  enable_resource_consumption_export = true
  horizontal_pod_autoscaling         = true
  network_policy                     = true
  enable_private_nodes               = true
  enable_private_endpoint            = false
  master_ipv4_cidr_block             = "172.16.0.0/28"
  grant_registry_access              = true
  master_authorized_networks         = [{cidr_block = "${data.http.cloud-shell-ip.response_body}/32", display_name = "cloud-shell"}]
  create_service_account             = false
  node_pools = [
    {
      name            = "node-pool-1"
      machine_type    = "n1-standard-1"
      min_count       = 1
      max_count       = 3
      disk_size_gb    = 50
      image_type      = "COS_CONTAINERD"
      disk_type       = "pd-standard"
      preemptible     = false
      service_account = ""
      autoscaling     = true
    }
  ]
}
