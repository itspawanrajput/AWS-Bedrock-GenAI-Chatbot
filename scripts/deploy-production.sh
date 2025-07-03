#!/bin/bash

set -e

# Production Deployment Script for AWS Bedrock Chatbot
echo "🚀 Deploying AWS Bedrock Chatbot to Production..."
echo "================================================="

# Configuration
STACK_NAME="bedrock-chatbot"  # Use existing stack
REGION="us-east-1"
ENVIRONMENT="prod"
FRONTEND_BUCKET="bedrock-chatbot-frontend-$(date +%s)"
DOMAIN_NAME="" # Set this if you have a custom domain

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${BLUE}📋 Step: $1${NC}"
}

echo_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

echo_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo_step "Checking prerequisites..."
if ! command -v aws &> /dev/null; then
    echo_error "AWS CLI not found. Please install it first."
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo_error "AWS SAM CLI not found. Please install it first."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo_error "npm not found. Please install Node.js first."
    exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    echo_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo_success "Prerequisites check passed"

# Get current API endpoint
CURRENT_API=$(aws cloudformation describe-stacks \
    --stack-name bedrock-chatbot \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text 2>/dev/null || echo "")

if [ -z "$CURRENT_API" ]; then
    echo_warning "No existing backend found. Deploying fresh infrastructure..."
    API_ENDPOINT=""
else
    echo_success "Found existing API: $CURRENT_API"
    API_ENDPOINT="$CURRENT_API"
fi

# Step 1: Deploy/Update Backend Infrastructure
echo_step "Deploying backend infrastructure..."
sam build

# Use existing deployment bucket or create one
DEPLOYMENT_BUCKET="bedrock-chatbot-deployment-$(date +%s)"
if aws s3 ls s3://bedrock-chatbot-deployment-1751544491 &>/dev/null; then
    DEPLOYMENT_BUCKET="bedrock-chatbot-deployment-1751544491"
    echo_success "Using existing deployment bucket: $DEPLOYMENT_BUCKET"
else
    aws s3 mb s3://$DEPLOYMENT_BUCKET --region $REGION
    echo_success "Created deployment bucket: $DEPLOYMENT_BUCKET"
fi

sam deploy \
    --template-file .aws-sam/build/template.yaml \
    --stack-name $STACK_NAME \
    --s3-bucket $DEPLOYMENT_BUCKET \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region $REGION \
    --parameter-overrides \
        Environment=$ENVIRONMENT \
        CorsOrigin="*" \
    --no-confirm-changeset

# Get API endpoint from deployment
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text)

echo_success "Backend deployed. API Endpoint: $API_ENDPOINT"

# Step 2: Build React App for Production
echo_step "Building React app for production..."
cd frontend

# Create production environment file
cat > .env.production << EOF
REACT_APP_API_URL=$API_ENDPOINT
REACT_APP_ENVIRONMENT=production
GENERATE_SOURCEMAP=false
EOF

# Install dependencies and build
npm ci --production=false
npm run build

echo_success "React app built successfully"

# Step 3: Create S3 bucket for frontend hosting
echo_step "Creating S3 bucket for frontend hosting..."

# Create unique bucket name
aws s3 mb s3://$FRONTEND_BUCKET --region $REGION

# Enable static website hosting
aws s3 website s3://$FRONTEND_BUCKET \
    --index-document index.html \
    --error-document index.html

# Set bucket policy for public read access
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$FRONTEND_BUCKET/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket $FRONTEND_BUCKET \
    --policy file://bucket-policy.json

# Upload built files to S3
echo_step "Uploading frontend to S3..."
aws s3 sync build/ s3://$FRONTEND_BUCKET \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "*.html" \
    --exclude "service-worker.js"

# Upload HTML files with no-cache headers
aws s3 sync build/ s3://$FRONTEND_BUCKET \
    --delete \
    --cache-control "no-cache" \
    --include "*.html" \
    --include "service-worker.js"

echo_success "Frontend uploaded to S3"

# Step 4: Create CloudFront Distribution
echo_step "Creating CloudFront distribution..."

# Create CloudFront distribution configuration
cat > cloudfront-config.json << EOF
{
    "CallerReference": "bedrock-chatbot-$(date +%s)",
    "Comment": "CloudFront distribution for Bedrock Chatbot",
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$FRONTEND_BUCKET",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
            "Enabled": false,
            "Quantity": 0
        },
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        },
        "MinTTL": 0,
        "DefaultTTL": 86400,
        "MaxTTL": 31536000,
        "Compress": true
    },
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$FRONTEND_BUCKET",
                "DomainName": "$FRONTEND_BUCKET.s3-website-$REGION.amazonaws.com",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only"
                }
            }
        ]
    },
    "CustomErrorPages": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponsePagePath": "/index.html",
                "ResponseCode": "200",
                "ErrorCachingMinTTL": 300
            }
        ]
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100"
}
EOF

# Create CloudFront distribution
DISTRIBUTION_ID=$(aws cloudfront create-distribution \
    --distribution-config file://cloudfront-config.json \
    --query 'Distribution.Id' \
    --output text)

echo_success "CloudFront distribution created: $DISTRIBUTION_ID"

# Get CloudFront domain name
CLOUDFRONT_DOMAIN=$(aws cloudfront get-distribution \
    --id $DISTRIBUTION_ID \
    --query 'Distribution.DomainName' \
    --output text)

echo_success "CloudFront domain: $CLOUDFRONT_DOMAIN"

# Step 5: Update CORS settings for production domain
echo_step "Updating CORS settings..."
cd ..

# Update SAM template with CloudFront domain for CORS
sam deploy \
    --template-file .aws-sam/build/template.yaml \
    --stack-name $STACK_NAME \
    --s3-bucket $DEPLOYMENT_BUCKET \
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
    --region $REGION \
    --parameter-overrides \
        Environment=$ENVIRONMENT \
        CorsOrigin="https://$CLOUDFRONT_DOMAIN" \
    --no-confirm-changeset

echo_success "CORS updated for production domain"

# Step 6: Test deployment
echo_step "Testing deployment..."

# Wait a moment for CloudFront to deploy
echo "⏳ Waiting for CloudFront distribution to deploy (this may take 10-15 minutes)..."
echo "💡 You can check status at: https://console.aws.amazon.com/cloudfront/home#distribution-settings:$DISTRIBUTION_ID"

# Test API endpoint
API_TEST=$(curl -s -X POST $API_ENDPOINT/chat \
    -H 'Content-Type: application/json' \
    -d '{"message": "Production test", "domain": "general"}' | jq -r '.response' 2>/dev/null || echo "API test failed")

if [[ "$API_TEST" != *"failed"* ]]; then
    echo_success "API test passed"
else
    echo_warning "API test failed - check Bedrock model access"
fi

# Cleanup temporary files
rm -f bucket-policy.json cloudfront-config.json frontend/.env.production

# Step 7: Output summary
echo ""
echo "🎉 Production Deployment Complete!"
echo "=================================="
echo ""
echo "📊 Deployment Summary:"
echo "   Backend API: $API_ENDPOINT"
echo "   Frontend S3: http://$FRONTEND_BUCKET.s3-website-$REGION.amazonaws.com"
echo "   CloudFront: https://$CLOUDFRONT_DOMAIN"
echo "   CloudFormation Stack: $STACK_NAME"
echo ""
echo "📱 Access URLs:"
echo "   Production Site: https://$CLOUDFRONT_DOMAIN"
echo "   S3 Direct: http://$FRONTEND_BUCKET.s3-website-$REGION.amazonaws.com"
echo ""
echo "📋 AWS Console Links:"
echo "   CloudFormation: https://console.aws.amazon.com/cloudformation/home?region=$REGION#/stacks/stackinfo?stackId=$STACK_NAME"
echo "   CloudFront: https://console.aws.amazon.com/cloudfront/home#distribution-settings:$DISTRIBUTION_ID"
echo "   S3 Bucket: https://s3.console.aws.amazon.com/s3/buckets/$FRONTEND_BUCKET"
echo ""
echo "⏳ Note: CloudFront deployment may take 10-15 minutes to be fully available globally."
echo ""
echo "🎯 Your production chatbot will be available at: https://$CLOUDFRONT_DOMAIN"

# Save deployment info
cat > deployment-info.json << EOF
{
  "deployment_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "stack_name": "$STACK_NAME",
  "region": "$REGION",
  "api_endpoint": "$API_ENDPOINT",
  "frontend_bucket": "$FRONTEND_BUCKET",
  "cloudfront_domain": "$CLOUDFRONT_DOMAIN",
  "cloudfront_distribution_id": "$DISTRIBUTION_ID",
  "production_url": "https://$CLOUDFRONT_DOMAIN"
}
EOF

echo_success "Deployment info saved to deployment-info.json"
echo ""
echo "🚀 Production deployment successful!"
