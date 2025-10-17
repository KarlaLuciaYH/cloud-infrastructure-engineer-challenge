

variable "aws_region" {
  description = "The AWS region to create things in."
  type        = string
  default     = "us-east-1"
}

variable "stage_name" {
  type    = string
  default = "dev"
}

## local
variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "cloud-infra-challenge"
}
