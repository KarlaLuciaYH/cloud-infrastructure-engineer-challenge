# variable "vpc_id" {
#   type    = string
#   default = ""
# }

# variable "subnet_ids" {
#   type    = list(any)
#   default = []
# }

variable "instance_class" {
  type    = string
  default = "db.m5.large"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  type    = number
  default = 100
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "multi_az" {
  type    = bool
  default = false
}
variable "dbname" {
  type    = string
  default = "postgres"
}

variable "engine" {
  type    = string
  default = "postgres"
}

variable "engine_version" {
  type    = string
  default = "17.2"
}

variable "username" {
  type    = string
  default = "postgres"
}


# variable "tags" {
#   type        = map(string)
#   description = "Tags default"
#   default = {
#   }
# }
