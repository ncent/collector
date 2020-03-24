output "bucket_arn" {
  value = "${aws_s3_bucket.bucket.arn}"
}

output "bucket_name" {
  value = "${aws_s3_bucket.bucket.bucket}"
}

output "json_paths_key" {
  value = "${aws_s3_bucket_object.json_paths_config.key}"
}
