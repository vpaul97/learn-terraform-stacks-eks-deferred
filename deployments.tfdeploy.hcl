# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

identity_token "aws" {
  audience = ["aws.workload.identity"]
}

# Commented to destroy cluster and prepare for next demo
# deployment "development" {
#   inputs = {
#     cluster_name        = "stacks-demo"
#     kubernetes_version  = "1.31"
#     region              = "us-west-2"
#     role_arn            = "arn:aws:iam::060795911201:role/stacks-vpaul_test-tfpolicy-with-stacks"
#     identity_token      = identity_token.aws.jwt
#     default_tags        = { stacks-preview-example = "eks-deferred-stack" }
#   }
# }