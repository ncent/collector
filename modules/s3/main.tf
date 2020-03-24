resource "aws_s3_bucket" "bucket" {
  bucket        = "ncent-challenge-quota-${var.stage}"
  acl           = "private"
  force_destroy = true
  tags          = var.default_tags
}

resource "aws_s3_bucket_object" "json_paths_config" {
  bucket = "${aws_s3_bucket.bucket.bucket}"
  key    = "JSONPaths.json"
  source = var.json_path
  tags   = var.default_tags
}
