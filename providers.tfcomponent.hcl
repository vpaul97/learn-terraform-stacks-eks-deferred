# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Provider configuration for EKS Stack with Kubernetes 1.32
# AWS Provider 6.62.0 verified from Terraform Registry

required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 6.62.0"
  }
  kubernetes = {
    source  = "hashicorp/kubernetes"
    version = "~> 2.32.0"
  }
  random = {
    source = "hashicorp/random"
    version = "~> 3.6.2"
  }
}

provider "aws" "main" {
  config {
    region = var.region

    assume_role_with_web_identity {
      role_arn           = var.role_arn
      web_identity_token = var.identity_token
    }

    default_tags {
      tags = var.default_tags
    }
  }
}

provider "kubernetes" "main" {
  config {
    host                   = component.cluster.cluster_url
    cluster_ca_certificate = component.cluster.cluster_ca
    token                  = component.cluster.cluster_token
  }
}

provider "random" "main" {}