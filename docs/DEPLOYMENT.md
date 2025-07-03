# 🚀 Deployment Guide

This guide covers deploying the AWS Bedrock GenAI Chatbot to production.

## 📋 Prerequisites

### Required Tools
- [AWS CLI](https://aws.amazon.com/cli/) - configured with appropriate permissions
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
- [Node.js 18+](https://nodejs.org/)
- [Python 3.11+](https://python.org/)

### AWS Permissions Required
Your AWS user/role needs the following permissions:
- **Bedrock**: `bedrock:*`
- **Lambda**: `lambda:*`
- **API Gateway**: `apigateway:*`
- **CloudFormation**: `cloudformation:*`
- **IAM**: `iam:CreateRole`, `iam:AttachRolePolicy`, etc.
- **S3**: `s3:*`
- **DynamoDB**: `dynamodb:*`
- **CloudFront**: `cloudfront:*`
- **CloudWatch**: `logs:*`, `cloudwatch:*`

## 🔧 Step-by-Step Deployment

### 1. Enable Bedrock Model Access

⚠️ **IMPORTANT**: This must be done manually in the AWS Console.

1. Go to [AWS Bedrock Console](https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess)
2. Click "Manage model access"
3. Enable access for:
   - ✅ Anthropic Claude 3 Haiku
   - ✅ Anthropic Claude 3 Sonnet
   - ✅ Meta Llama 3 models
   - ✅ AI21 Jurassic models
4. Click "Save changes"
5. Wait for approval (usually immediate)

### 2. Deploy Backend Infrastructure

```bash
# Make scripts executable
chmod +x scripts/deploy.sh

# Deploy backend
./scripts/deploy.sh
```

This creates:
- Lambda functions for AI processing
- API Gateway with REST endpoints
- DynamoDB table for chat history
- S3 bucket for logs
- IAM roles with proper permissions
- CloudWatch dashboards

### 3. Deploy Frontend to Production

```bash
# Deploy frontend with CDN
./scripts/deploy-frontend-prod.sh
```

This creates:
- S3 bucket for static hosting
- CloudFront distribution for global CDN
- Optimized React production build
- HTTPS enabled via CloudFront

### 4. Verify Deployment

```bash
# Test API endpoints
./scripts/test-api.sh

# Monitor CloudFront deployment
./scripts/check-cloudfront.sh
```

## 🌐 Production URLs

After deployment, you'll have:
- **API Backend**: `https://your-api-id.execute-api.us-east-1.amazonaws.com/prod`
- **Frontend (S3)**: `http://your-bucket.s3-website-us-east-1.amazonaws.com`
- **Frontend (CDN)**: `https://your-id.cloudfront.net`

## 📊 Infrastructure Overview

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   CloudFront    │    │ API Gateway  │    │ AWS Bedrock     │
│   (Global CDN)  │    │ (REST API)   │    │ (AI Models)     │
└─────────┬───────┘    └──────┬───────┘    └─────────┬───────┘
          │                   │                      │
          │                   │                      │
┌─────────▼───────┐    ┌──────▼───────┐    ┌─────────▼───────┐
│   S3 Bucket     │    │   Lambda     │    │   DynamoDB      │
│ (Static Files)  │    │ (Functions)  │    │ (Chat History)  │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

## 🔄 Update Deployments

### Update Backend Only
```bash
sam build
sam deploy --no-confirm-changeset
```

### Update Frontend Only
```bash
./scripts/deploy-frontend-prod.sh
```

### Update Everything
```bash
./scripts/deploy.sh
./scripts/deploy-frontend-prod.sh
```

## 🛠️ Troubleshooting

### Common Issues

**1. Bedrock Access Denied**
- Solution: Enable model access in AWS Console
- Check: IAM permissions for Bedrock service

**2. CloudFront Not Accessible**
- Wait: 10-15 minutes for global propagation
- Check: Distribution status with `./scripts/check-cloudfront.sh`

**3. API CORS Errors**
- Check: Lambda function handles OPTIONS requests
- Verify: API Gateway CORS configuration

**4. Lambda Timeout**
- Increase: Function timeout in `template.yaml`
- Check: Bedrock model availability in region

### Monitoring

**CloudWatch Dashboards**
- Lambda execution metrics
- API Gateway request counts
- DynamoDB read/write capacity
- Error rates and response times

**Cost Monitoring**
- Set up billing alerts in AWS Console
- Monitor token usage per model
- Track request patterns

## 🔐 Security Best Practices

### Production Security
- [ ] Enable API Gateway API keys
- [ ] Set up WAF for CloudFront
- [ ] Configure VPC endpoints for internal traffic
- [ ] Enable CloudTrail for audit logging
- [ ] Rotate IAM credentials regularly

### Environment Variables
- [ ] Use AWS Systems Manager Parameter Store
- [ ] Encrypt sensitive configuration
- [ ] Separate dev/staging/prod environments

## 💰 Cost Optimization

### Monitoring Costs
```bash
# Set up cost alerts
aws budgets create-budget --account-id YOUR_ACCOUNT_ID \
  --budget file://budget-config.json
```

### Optimization Tips
1. **Use cheaper models for simple queries** (Claude 3 Haiku)
2. **Implement response caching** for common questions
3. **Set request rate limits** to prevent runaway costs
4. **Monitor token usage** per model and domain
5. **Use reserved capacity** for DynamoDB if usage is predictable

## 📈 Scaling Considerations

### High Traffic
- **Lambda**: Increase concurrency limits
- **DynamoDB**: Enable auto-scaling
- **API Gateway**: Configure throttling
- **CloudFront**: Use multiple cache behaviors

### Multi-Region
- Deploy backend in multiple AWS regions
- Use Route 53 for DNS failover
- Replicate DynamoDB tables across regions

## 🔄 CI/CD Pipeline

### GitHub Actions Example
```yaml
name: Deploy Bedrock Chatbot
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy Backend
        run: ./scripts/deploy.sh
      - name: Deploy Frontend
        run: ./scripts/deploy-frontend-prod.sh
```

### Automated Testing
- Unit tests for Lambda functions
- Integration tests for API endpoints
- End-to-end tests for frontend
- Load testing for production readiness
