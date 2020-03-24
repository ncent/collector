variable "stage" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "bucket_arn" {
  type = "string"
}

variable "bucket_name" {
  type = "string"
}

variable "json_paths_key" {
  type = "string"
}

variable "redshift_passwd" {
  type = "string"
}

variable "redshift_queries" {
  type = "string"
}

variable "default_tags" {
  type = "map"
}

### VARS WITH DEFAULT VALUES

variable "firehose_log_group_name" {
  type    = "string"
  default = "/aws/kinesisfirehose/ncent_stream_to_redshift"
}

variable "redshift_table_name" {
  type    = "string"
  default = "challenge_usage_quota"
}

variable "vpc_cidr" {
  type    = "string"
  default = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  type    = "list"
  default = ["10.0.1.0/24"]
}
