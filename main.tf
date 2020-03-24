provider "aws" {
  region  = var.region
  profile = var.profile
}

module "s3" {
  source       = "./modules/s3"
  stage        = var.stage
  json_path    = "./JSONPaths.json"
  default_tags = var.default_tags
}

module "vpc_firehose_redshift" {
  source           = "./modules/vpc_firehose_redshift"
  stage            = var.stage
  region           = var.region
  bucket_arn       = module.s3.bucket_arn
  bucket_name      = module.s3.bucket_name
  json_paths_key   = module.s3.json_paths_key
  redshift_passwd  = var.redshift_passwd
  redshift_queries = "./redshift_queries.sql"
  default_tags     = var.default_tags
}
