output "knowledge_base" {
  value = aws_bedrockagent_knowledge_base.main
}

output "knowledge_base_id" {
  value = aws_bedrockagent_knowledge_base.main.id
}

output "data_source_id" {
  value = aws_bedrockagent_data_source.s3.id
}

output "opensearch_collection" {
  value = aws_opensearchserverless_collection.kb
}
