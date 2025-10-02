output "workgroup_name" {
  value = aws_athena_workgroup.usage.name
}

output "database_name" {
  value = aws_glue_catalog_database.usage.name
}

output "ddb_export_bucket" {
  value = aws_s3_bucket.ddb_export.bucket
}
