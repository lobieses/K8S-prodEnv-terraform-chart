# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "aws_access_key" {
  description = "access key from aws"
  type        = string
  default     = ""
}

variable "aws_secret_key" {
  description = "secret key from aws"
  type        = string
  default     = ""
}

variable "aws_route53_hosted_zone_id" {
  description = "AWS Route53 Hosted zone ID"
  type        = string
  default     = ""
}

variable "deployment_prefix" {
  description = "Prefix of the deployment."
  type        = string
  default     = ""
}