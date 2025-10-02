# Bedrock Chat - Complete Terraform Implementation

Complete Terraform implementation mirroring the CDK deployment of Bedrock Chat, including all features: WebSocket streaming, Bot Store, Usage Analytics, and orchestration.

## Architecture Components

### Core Modules
- **storage**: S3 buckets for documents, frontend, and large messages
- **database**: DynamoDB tables (conversations, bots, websocket sessions)
- **auth**: Cognito user pool with user groups
- **bedrock**: Knowledge Base with OpenSearch Serverless
- **api**: Lambda + API Gateway for REST API
- **frontend**: CloudFront + S3 for web application

### Advanced Modules
- **websocket**: WebSocket API for streaming responses
- **bot-store**: OpenSearch Serverless + OSIS pipelines for bot search
- **usage-analysis**: Athena + Glue for analytics
- **orchestration**: Step Functions + EventBridge Pipes for KB ingestion
- **waf**: WAF for Cognito and Published APIs
- **codebuild**: Dynamic bot creation and API publishing

## Prerequisites

1. AWS CLI configured
2. Terraform >= 1.0
3. Docker image for WebSocket Lambda pushed to ECR
4. Bedrock model access enabled (Claude 3.5 Sonnet, Titan Embeddings)

## Deployment Options

### Option 1: POC Deployment (Minimal - Recommended for Testing)

Deploys only essential modules: storage, database, auth, bedrock, api, frontend.

**Excludes:** WebSocket, Bot Store, Usage Analytics, Orchestration, WAF, CodeBuild

```bash
# Use POC configuration
cp main-poc.tf main.tf
cp variables-poc.tf variables.tf

# Initialize
terraform init

# Deploy
terraform apply
```

**Cost:** ~$20-50/month

### Option 2: Full Production Deployment

Deploys all modules with complete feature set.

```bash
# Use full configuration (default main.tf)
terraform init

# Deploy
terraform apply -var="websocket_lambda_image_uri=<ECR_IMAGE_URI>"
```

**Cost:** ~$75-200/month

## Configuration

### Required Variables
- `websocket_lambda_image_uri`: ECR image URI for WebSocket handler

### Optional Variables
- `enable_bot_store`: Enable bot store (default: true)
- `enable_bot_store_replicas`: Enable OpenSearch replicas (default: false)
- `enable_cross_region_inference`: Enable Bedrock cross-region (default: false)
- `allowed_ip_ranges`: IP ranges for Cognito WAF (default: [])
- `api_allowed_ip_ranges`: IP ranges for API WAF (default: ["0.0.0.0/0"])

## Outputs

- `websocket_url`: WebSocket API endpoint
- `bot_store_endpoint`: OpenSearch endpoint for bot search
- `usage_analysis_workgroup`: Athena workgroup name
- `state_machine_arn`: Step Functions state machine ARN
- `cognito_waf_arn`: Cognito WAF ARN
- `published_api_waf_arn`: Published API WAF ARN
- `bot_creation_project`: CodeBuild project for bot creation
- `api_publish_project`: CodeBuild project for API publishing

## Module Structure

```
terraform/
├── main.tf                    # Root orchestration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
└── modules/
    ├── storage/               # S3 buckets
    ├── database/              # DynamoDB tables
    ├── auth/                  # Cognito
    ├── bedrock/               # Knowledge Base
    ├── api/                   # REST API
    ├── frontend/              # CloudFront
    ├── websocket/             # WebSocket API
    ├── bot-store/             # Bot search (OpenSearch + OSIS)
    ├── usage-analysis/        # Analytics (Athena + Glue)
    ├── orchestration/         # Step Functions + Pipes
    ├── waf/                   # Web Application Firewall
    └── codebuild/             # Dynamic infrastructure
```

## Feature Comparison

### POC Deployment (Minimal)
✅ Basic chat functionality
✅ User authentication (Cognito)
✅ Knowledge Base (RAG)
✅ REST API
✅ Frontend (CloudFront + S3)
❌ WebSocket streaming
❌ Bot Store search
❌ Usage analytics
❌ Advanced orchestration
❌ WAF security
❌ Dynamic bot creation

### Full Production Deployment
✅ All POC features
✅ WebSocket streaming responses
✅ Bot Store with full-text search
✅ Usage analytics with Athena
✅ Knowledge Base orchestration
✅ WAF for security
✅ Dynamic bot/API creation via CodeBuild
✅ EventBridge Pipes for DynamoDB streams
✅ Step Functions for ingestion workflow
✅ Complete CDK parity (100% feature coverage)

## Cleanup

```bash
terraform destroy
```

Note: Some resources (OpenSearch collections, S3 buckets) may require manual cleanup if they contain data.
