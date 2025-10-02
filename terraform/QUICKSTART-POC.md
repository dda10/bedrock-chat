# Quick Start - POC Deployment

Minimal deployment for testing Bedrock Chat with Vietnamese language support.

## What's Included

**Core Features:**
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

## Prerequisites

1. AWS CLI configured with credentials
2. Terraform >= 1.0 installed
3. Bedrock model access enabled:
   - Claude 3.5 Sonnet (or Claude 4 Sonnet)
   - Amazon Titan Embeddings v2

## Deployment Steps

### 1. Enable Bedrock Models

```bash
# Open Bedrock console and enable models
aws bedrock list-foundation-models --region us-east-1
```

### 2. Clone and Setup

```bash
cd /Users/admin/Documents/bedrock-chat/terraform

# Use POC configuration
cp main-poc.tf main.tf
cp variables-poc.tf variables.tf
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy (takes ~10-15 minutes)
terraform apply -auto-approve
```

### 4. Get Outputs

```bash
terraform output
```

You'll get:
- `frontend_url` - Access your chat application
- `api_endpoint` - REST API endpoint
- `user_pool_id` - Cognito user pool ID

### 5. Create First User

```bash
# Get user pool ID from outputs
USER_POOL_ID=$(terraform output -raw user_pool_id)

# Create user
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username admin@example.com \
  --temporary-password TempPass123! \
  --user-attributes Name=email,Value=admin@example.com

# Add to CreatingBotAllowed group
aws cognito-idp admin-add-user-to-group \
  --user-pool-id $USER_POOL_ID \
  --username admin@example.com \
  --group-name CreatingBotAllowed
```

### 6. Access Application

Open the `frontend_url` in your browser and login with the credentials created above.

## Testing Vietnamese Language

1. Create a custom bot with Vietnamese knowledge base
2. Upload Vietnamese documents (PDF, TXT)
3. Test queries in Vietnamese:
   - "Sản phẩm này có những tính năng gì?"
   - "Giá bao nhiêu?"
   - "Làm thế nào để sử dụng?"

## Cost Estimate

**Monthly Cost:** ~$20-50

Breakdown:
- DynamoDB: $5-10 (on-demand)
- OpenSearch Serverless: $10-20 (0.5 OCU)
- Lambda: $5-10 (first 1M requests free)
- S3: $1-5
- CloudFront: $1-5
- Cognito: Free (first 50K MAU)
- Bedrock: Pay per use (~$0.01-0.05 per query)

## Cleanup

```bash
terraform destroy -auto-approve
```

## Upgrade to Full Production

To add WebSocket, Bot Store, and other features:

```bash
# Restore full configuration
git checkout main.tf variables.tf

# Apply changes
terraform apply
```

## Troubleshooting

**Issue:** Bedrock model not available
```bash
# Check model access
aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?contains(modelId, `claude`)]'
```

**Issue:** Terraform state locked
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

**Issue:** OpenSearch collection creation failed
```bash
# Check service quotas
aws service-quotas get-service-quota \
  --service-code aoss \
  --quota-code L-XXXXXXXX
```

## Next Steps

1. Upload Vietnamese documents to test RAG
2. Create custom bots with specific instructions
3. Test different Claude models (3.5 vs 4.0)
4. Monitor costs in AWS Cost Explorer
5. Upgrade to full production when ready
