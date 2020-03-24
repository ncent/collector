output "psql_connection_string" {
  value = "postgresql://${aws_redshift_cluster.ncent_redshift_cluster.master_username}:${aws_redshift_cluster.ncent_redshift_cluster.master_password}@${aws_redshift_cluster.ncent_redshift_cluster.endpoint}/${aws_redshift_cluster.ncent_redshift_cluster.database_name}:${aws_redshift_cluster.ncent_redshift_cluster.port}"
}
