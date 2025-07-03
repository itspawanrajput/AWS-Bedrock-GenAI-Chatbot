#!/bin/bash

# AWS SAM Deployment Script for Bedrock Chatbot

set -e

# Configuration
STACK_NAME="bedrock-chatbot"
REGION="us-east-1"
ENVIRONMENT="prod"
S3_BUCKET="bedrock-chatbot-deployment-$(date +%s)"

echo "🚀 Deploying AWS Bedrock GenAI Chatbot..."
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo "Environment: $ENVIRONMENT"
echo ""

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &>/dev/null; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &>/dev/null; then
    echo "❌ AWS SAM CLI not found. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Create S3 bucket for deployment artifacts
echo "📦 Creating S3 bucket for deployment artifacts..."
aws s3 mb s3://$S3_BUCKET --region $REGION || echo "Bucket may already exist"

# Build the SAM application
echo "🔨 Building SAM application..."
sam build

# Deploy the application
echo "🚀 Deploying to AWS..."
sam deploy \
    --template-file .aws-sam/build/template.yaml \
    --stack-name $STACK_NAME \
    --s3-bucket $S3_BUCKET \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region $REGION \
    --parameter-overrides \
        Environment=$ENVIRONMENT \
        CorsOrigin="*" \
    --confirm-changeset

# Get stack outputs
echo ""
echo "📋 Deployment Outputs:"
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table

# Get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text)

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 API Endpoint: $API_ENDPOINT"
echo "📊 CloudWatch Dashboard: https://$REGION.console.aws.amazon.com/cloudwatch/home?region=$REGION#dashboards:name=BedrockChatbot-$ENVIRONMENT"
echo ""
echo "🧪 Test your API:"
echo "curl -X POST $API_ENDPOINT/chat \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"message\": \"Hello, how can you help me?\", \"domain\": \"general\"}'"
echo ""
echo "🔧 Update your frontend .env file:"
echo "REACT_APP_API_URL=$API_ENDPOINT"
echo ""

# Optional: Deploy frontend to S3 with CloudFront
read -p "🌐 Do you want to deploy the frontend to S3 + CloudFront? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🌐 Deploying frontend..."
    
    # Create frontend deployment bucket
    FRONTEND_BUCKET="$STACK_NAME-frontend-$(date +%s)"
    aws s3 mb s3://$FRONTEND_BUCKET --region $REGION
    
    # Build React app
    cd frontend
    cp .env.example .env
    echo "REACT_APP_API_URL=$API_ENDPOINT" >> .env
    npm install
    npm run build
    
    # Deploy to S3
    aws s3 sync build/ s3://$FRONTEND_BUCKET --delete
    
    # Configure S3 for static website hosting
    aws s3 website s3://$FRONTEND_BUCKET \
        --index-document index.html \
        --error-document index.html
    
    # Create CloudFront distribution (simplified)
    echo "Frontend deployed to: http://$FRONTEND_BUCKET.s3-website-$REGION.amazonaws.com"
    echo "💡 Consider setting up CloudFront for better performance and HTTPS"
fi

echo ""
echo "🎉 All done! Your Bedrock chatbot is ready to use."
