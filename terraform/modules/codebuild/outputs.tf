output "bot_creation_project_name" {
  value = aws_codebuild_project.bot_creation.name
}

output "api_publish_project_name" {
  value = aws_codebuild_project.api_publish.name
}
