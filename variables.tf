
variable "profile" {
  type        = "string"
  description = "Profile from AWS credentials file (ex.: default)"
}

variable "stage" {
  type        = "string"
  description = "The stage of the infrastructure (ex.: development)"
}

variable "region" {
  type        = "string"
  description = "Region to deploy (ex.: us-west-2)"
}

variable "redshift_passwd" {
  type = "string"
}

variable "default_tags" {
  type = "map"
  default = {
    Terraformed = true
  }
}
