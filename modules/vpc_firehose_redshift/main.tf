locals {
  # Maps regions and IPs for RedShift access
  redshift_ips_regions_map = {
    us-east-1 = "52.70.63.192/27"  # US East (N. Virginia)
    us-east-2 = "13.58.135.96/27"  # US East (Ohio)
    us-west-1 = "13.57.135.192/27" # US West (N. California)
    us-west-2 = "52.89.255.224/27" # US West (Oregon)
  }
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "ncent_stream_log_group" {
  name              = "${var.firehose_log_group_name}_${var.stage}"
  retention_in_days = 0
}

resource "aws_cloudwatch_log_stream" "ncent_stream_log_redshift_stream" {
  name           = "RedshiftDelivery"
  log_group_name = "${aws_cloudwatch_log_group.ncent_stream_log_group.name}"

}

resource "aws_cloudwatch_log_stream" "ncent_stream_log_s3_stream" {
  name           = "S3Delivery"
  log_group_name = "${aws_cloudwatch_log_group.ncent_stream_log_group.name}"
}


resource "aws_iam_role" "firehose_role" {
  name = "firehose_ncent_role_${var.stage}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "firehose.amazonaws.com",
          "redshift.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = var.default_tags
}

resource "aws_iam_role_policy" "firehose_role_policy" {
  name   = "firehose_ncent_role_policy_${var.stage}"
  role   = "${aws_iam_role.firehose_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "${var.bucket_arn}",
        "${var.bucket_arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
        "Resource": [
        "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.ncent_stream_log_group.name}:log-stream:*"
      ]
    }
  ]
}
EOF
}

module "vpc" {
  source                 = "terraform-aws-modules/vpc/aws"
  name                   = "ncent-redshift"
  cidr                   = var.vpc_cidr
  azs                    = ["${var.region}a"]
  public_subnets         = var.vpc_public_subnets
  enable_public_redshift = true
  tags                   = var.default_tags
}

# Obtains public ip in order to allow run queries on provisioning
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "aws_redshift_subnet_group" "redshift" {
  name        = "ncent-redshift-${var.stage}"
  description = "Redshift subnet group"
  subnet_ids  = module.vpc.public_subnets
  tags        = var.default_tags
}

module "sg" {
  source              = "terraform-aws-modules/security-group/aws//modules/redshift"
  name                = "ncent-redshift-${var.stage}"
  vpc_id              = "${module.vpc.vpc_id}"
  ingress_cidr_blocks = ["${lookup(local.redshift_ips_regions_map, var.region)}", "${chomp(data.http.myip.body)}/32"]
  egress_rules        = ["all-all"]
  tags                = var.default_tags
}

resource "aws_redshift_cluster" "ncent_redshift_cluster" {
  cluster_identifier        = "ncent-cluster-${var.stage}"
  database_name             = "ncentdb"
  master_username           = "ncentuser"
  master_password           = "${var.redshift_passwd}"
  node_type                 = "dc2.large"
  cluster_type              = "single-node"
  cluster_subnet_group_name = "${aws_redshift_subnet_group.redshift.name}"
  vpc_security_group_ids    = ["${module.sg.this_security_group_id}"]
  skip_final_snapshot       = true
  publicly_accessible       = true
  iam_roles                 = ["${aws_iam_role.firehose_role.arn}"]

  provisioner "local-exec" {
    command = "psql \"postgresql://${self.master_username}:${self.master_password}@${self.endpoint}/${self.database_name}\" -f ${var.redshift_queries}"
  }

  tags = var.default_tags
}

resource "aws_kinesis_firehose_delivery_stream" "ncent_stream_to_redshift" {
  name        = "ncent_stream_to_redshift_${var.stage}"
  destination = "redshift"

  s3_configuration {
    role_arn        = "${aws_iam_role.firehose_role.arn}"
    bucket_arn      = "${var.bucket_arn}"
    buffer_interval = 60

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${aws_cloudwatch_log_group.ncent_stream_log_group.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.ncent_stream_log_s3_stream.name}"
    }
  }

  redshift_configuration {
    role_arn        = "${aws_iam_role.firehose_role.arn}"
    cluster_jdbcurl = "jdbc:redshift://${aws_redshift_cluster.ncent_redshift_cluster.endpoint}/${aws_redshift_cluster.ncent_redshift_cluster.database_name}"
    username        = "${aws_redshift_cluster.ncent_redshift_cluster.master_username}"
    password        = "${aws_redshift_cluster.ncent_redshift_cluster.master_password}"
    data_table_name = "${var.redshift_table_name}"
    copy_options    = "json 's3://${var.bucket_name}/${var.json_paths_key}'"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${aws_cloudwatch_log_group.ncent_stream_log_group.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.ncent_stream_log_redshift_stream.name}"
    }
  }

  tags = var.default_tags
}

