#!/bin/bash

DISTRIBUTION_ID="E24KZ4DETX6J9R"
CLOUDFRONT_URL="https://dwchjvymg5dvs.cloudfront.net"

echo "🔍 Checking CloudFront deployment status..."
echo "Distribution ID: $DISTRIBUTION_ID"
echo ""

while true; do
    STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text 2>/dev/null)
    
    if [ "$STATUS" = "Deployed" ]; then
        echo "✅ CloudFront is deployed!"
        echo "🌐 Testing CloudFront URL..."
        
        # Test if CloudFront is accessible
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CLOUDFRONT_URL" 2>/dev/null)
        
        if [ "$HTTP_STATUS" = "200" ]; then
            echo "🎉 SUCCESS! Your production chatbot is now available at:"
            echo "   $CLOUDFRONT_URL"
            break
        else
            echo "⏳ CloudFront deployed but not yet accessible (HTTP $HTTP_STATUS)"
            echo "   This is normal - DNS propagation can take a few more minutes"
            echo "   You can still use: http://bedrock-chatbot-frontend-1751548447.s3-website-us-east-1.amazonaws.com"
        fi
    else
        echo "⏳ CloudFront Status: $STATUS (waiting...)"
        echo "📅 $(date): Still deploying to edge locations worldwide"
    fi
    
    echo "   Current access: http://bedrock-chatbot-frontend-1751548447.s3-website-us-east-1.amazonaws.com"
    echo ""
    sleep 30  # Check every 30 seconds
done

echo ""
echo "🚀 Your AWS Bedrock chatbot is fully deployed and accessible!"
echo "🌍 CloudFront URL: $CLOUDFRONT_URL"
echo "📦 S3 Direct URL: http://bedrock-chatbot-frontend-1751548447.s3-website-us-east-1.amazonaws.com"
