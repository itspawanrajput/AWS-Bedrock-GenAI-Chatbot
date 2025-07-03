#!/bin/bash

set -e

# Production Frontend Deployment Script
echo "🚀 Deploying Frontend to Production..."
echo "======================================"

# Configuration
REGION="us-east-1"
FRONTEND_BUCKET="bedrock-chatbot-frontend-$(date +%s)"

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

# Get API endpoint from existing stack
echo_step "Getting API endpoint..."
API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name bedrock-chatbot \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
    --output text)

if [ -z "$API_ENDPOINT" ]; then
    echo_error "❌ Could not find API endpoint. Make sure backend is deployed."
    exit 1
fi

echo_success "Found API endpoint: $API_ENDPOINT"

# Step 1: Build React App for Production
echo_step "Building React app for production..."
cd frontend

# Create production environment file
cat > .env.production.local << EOF
REACT_APP_API_URL=$API_ENDPOINT
REACT_APP_ENVIRONMENT=production
GENERATE_SOURCEMAP=false
EOF

# Install dependencies and build
npm install
npm run build

echo_success "React app built successfully"

# Step 2: Create S3 bucket for frontend hosting
echo_step "Creating S3 bucket for frontend hosting..."

# Create unique bucket name
aws s3 mb s3://$FRONTEND_BUCKET --region $REGION

# Disable public access blocks for static website hosting
aws s3api put-public-access-block \
    --bucket $FRONTEND_BUCKET \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

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

echo_success "S3 bucket configured for static hosting"

# Step 3: Upload frontend to S3
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
    "CustomErrorResponses": {
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

# Step 5: Test frontend
echo_step "Testing frontend..."
S3_URL="http://$FRONTEND_BUCKET.s3-website-$REGION.amazonaws.com"

# Test S3 direct access
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$S3_URL")
if [ "$HTTP_STATUS" = "200" ]; then
    echo_success "S3 website is accessible"
else
    echo_warning "S3 website returned status: $HTTP_STATUS"
fi

# Cleanup temporary files
rm -f bucket-policy.json cloudfront-config.json .env.production.local

# Step 6: Output summary
echo ""
echo "🎉 Frontend Production Deployment Complete!"
echo "==========================================="
echo ""
echo "📊 Deployment Summary:"
echo "   Backend API: $API_ENDPOINT"
echo "   S3 Bucket: $FRONTEND_BUCKET"
echo "   CloudFront Distribution: $DISTRIBUTION_ID"
echo ""
echo "🌐 Access URLs:"
echo "   🚀 Production Site: https://$CLOUDFRONT_DOMAIN"
echo "   📦 S3 Direct: $S3_URL"
echo ""
echo "📱 AWS Console Links:"
echo "   S3 Bucket: https://s3.console.aws.amazon.com/s3/buckets/$FRONTEND_BUCKET"
echo "   CloudFront: https://console.aws.amazon.com/cloudfront/home#distribution-settings:$DISTRIBUTION_ID"
echo ""
echo "⏳ Note: CloudFront deployment may take 10-15 minutes to be fully available globally."
echo ""
echo "🎯 Your production chatbot will be available at:"
echo "   ✅ https://$CLOUDFRONT_DOMAIN"

# Save deployment info
cat > deployment-info.json << EOF
{
  "deployment_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "region": "$REGION",
  "api_endpoint": "$API_ENDPOINT",
  "frontend_bucket": "$FRONTEND_BUCKET",
  "s3_website_url": "$S3_URL",
  "cloudfront_domain": "$CLOUDFRONT_DOMAIN",
  "cloudfront_distribution_id": "$DISTRIBUTION_ID",
  "production_url": "https://$CLOUDFRONT_DOMAIN"
}
EOF

echo_success "Deployment info saved to deployment-info.json"
echo ""
echo "🚀 Production deployment successful!"
echo "🌟 Your chatbot is going live at: https://$CLOUDFRONT_DOMAIN"
