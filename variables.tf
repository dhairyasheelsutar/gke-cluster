################### Define Variables here #####################

variable "project" {
  type        = string
  description = "Project ID where the resources will get deployed"
}

variable "vpc" {
  type        = string
  description = "Self link of VPC to use. If not provided new VPC will be provisioned"
  default     = null
}

variable "region" {
  type        = string
  description = "Region where the GKE cluster will be provisioned. If not provided, us-central1 will be used"
  default     = "us-central1"
}

variable "subnet" {
  type        = string
  description = "Self link of Subnet to use. If not provided new subnet will be provisioned"
  default     = null
}

variable "ip_range_pods" {
    type = string
    description = "Secondary CIDR Range for pods. If not provided, new range will be provisioned"
    default = null
}


variable "ip_range_services" {
    type = string
    description = "Secondary CIDR Range for services. If not provided, new range will be provisioned"
    default = null
}