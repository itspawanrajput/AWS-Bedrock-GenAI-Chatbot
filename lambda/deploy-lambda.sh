#!/bin/bash

# Deploy Lambda Function Script

FUNCTION_NAME="bedrock-chatbot-handler"
ROLE_NAME="BedrockChatbotRole"
REGION="us-east-1"
RUNTIME="python3.11"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"

echo "📦 Packaging Lambda function..."

# Create deployment package
mkdir -p package
pip install -r requirements.txt -t package/
cp bedrock_handler.py package/
cd package
zip -r ../bedrock-handler.zip .
cd ..

echo "🚀 Deploying Lambda function..."

# Create or update Lambda function
aws lambda create-function \
    --function-name $FUNCTION_NAME \
    --runtime $RUNTIME \
    --role $ROLE_ARN \
    --handler bedrock_handler.lambda_handler \
    --zip-file fileb://bedrock-handler.zip \
    --timeout 60 \
    --memory-size 512 \
    --environment Variables='{
        "CHAT_HISTORY_TABLE":"bedrock-chat-history",
        "LOGS_BUCKET":"bedrock-chat-logs-'$(date +%s)'"
    }' \
    --region $REGION || \
aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --zip-file fileb://bedrock-handler.zip \
    --region $REGION

# Update function configuration
aws lambda update-function-configuration \
    --function-name $FUNCTION_NAME \
    --timeout 60 \
    --memory-size 512 \
    --environment Variables='{
        "CHAT_HISTORY_TABLE":"bedrock-chat-history",
        "LOGS_BUCKET":"bedrock-chat-logs"
    }' \
    --region $REGION

echo "✅ Lambda function deployed successfully!"
echo "Function ARN: arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME"

# Cleanup
rm -rf package bedrock-handler.zip
