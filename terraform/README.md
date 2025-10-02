# Bedrock Chat - Test Branch (POC Deployment)

Minimal deployment for testing Vietnamese language support with Bedrock Chat.

## Features

**Included:**
- ✅ Chat interface (React frontend)
- ✅ User authentication (Cognito)
- ✅ Knowledge Base with RAG (Bedrock + OpenSearch)
- ✅ REST API (Lambda + API Gateway)
- ✅ Document storage (S3)
- ✅ Conversation history (DynamoDB)

**Not Included (to reduce cost):**
- ❌ WebSocket streaming
- ❌ Bot Store search
- ❌ Usage analytics
- ❌ WAF
- ❌ Advanced orchestration
- ❌ CodeBuild

## Cost

**Monthly:** ~$20-50

## Prerequisites

1. AWS CLI configured
2. Terraform >= 1.0
3. HCP Terraform account
4. Bedrock model access (Claude 3.5 Sonnet, Titan Embeddings)

## Deployment

### 1. Configure HCP Terraform

Update `backend.tf` with your organization:
```hcl
organization = "your-org-name"
```

### 2. Create Workspace

Create workspace `bedrock-chat-test` in HCP Terraform UI

### 3. Set Variables

In HCP Terraform workspace, set:
```hcl
workspace_name       = "bedrock-chat-test"
aws_region          = "us-east-1"
bedrock_region      = "us-east-1"
env_name            = "test"
self_sign_up_enabled = true
```

### 4. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## Outputs

- `frontend_url` - Access your chat application
- `api_endpoint` - REST API endpoint
- `user_pool_id` - Cognito user pool ID
- `document_bucket` - S3 bucket for documents
- `knowledge_base_id` - Bedrock Knowledge Base ID

## Testing Vietnamese

1. Upload Vietnamese documents to S3 bucket
2. Create custom bot with Vietnamese instructions
3. Test queries in Vietnamese

## Upgrade to Production

Switch to `v3` branch for full production deployment with all features.

```bash
git checkout v3
```

## Cleanup

```bash
terraform destroy
```
