output "opensearch_endpoint" {
  value = aws_opensearchserverless_collection.bot_store.collection_endpoint
}

output "collection_arn" {
  value = aws_opensearchserverless_collection.bot_store.arn
}
