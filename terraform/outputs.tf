output "cluster_uri" {
  description = "URL of the managed service db"
  value       = ovh_cloud_project_database.db_eductive03.endpoints.0.uri
}

output "database_user" {
  description = "user of the managed service db"
  value       = ovh_cloud_project_database_user.eductive03.name
}

output "database_password" {
  description = "password of the managed service db"
  value       = ovh_cloud_project_database_user.eductive03.password
  sensitive   = true
}
