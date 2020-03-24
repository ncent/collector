output "psql_connection_string" {
  value = "${module.vpc_firehose_redshift.psql_connection_string}"
}
