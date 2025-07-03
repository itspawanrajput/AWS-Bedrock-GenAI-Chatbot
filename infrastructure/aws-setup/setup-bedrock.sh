#!/bin/bash

# AWS Bedrock Setup Script
# Make sure you have AWS CLI configured with appropriate permissions

echo "🚀 Setting up AWS Bedrock GenAI Chatbot Infrastructure..."

# Variables
REGION="us-east-1"
ROLE_NAME="BedrockChatbotRole"
POLICY_NAME="BedrockChatbotPolicy"
LAMBDA_FUNCTION_NAME="bedrock-chatbot-handler"
API_NAME="bedrock-chatbot-api"
DYNAMODB_TABLE="bedrock-chat-history"
S3_BUCKET="bedrock-chat-logs-$(date +%s)"

# 1. Enable Bedrock model access (Manual step - needs to be done in console)
echo "📋 MANUAL STEP: Enable Bedrock model access in AWS Console"
echo "   - Go to AWS Bedrock Console"
echo "   - Navigate to 'Foundation Models' -> 'Model Access'"
echo "   - Request access for: Anthropic Claude, Meta Llama, AI21 Jurassic"
echo "   - Wait for approval (usually immediate for most models)"
echo ""

# 2. Create IAM Policy
echo "📝 Creating IAM Policy..."
aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://bedrock-policy.json \
    --region $REGION

# 3. Create IAM Role for Lambda
echo "🔑 Creating IAM Role..."
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://trust-policy.json

# 4. Attach policies to role
echo "🔗 Attaching policies to role..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/$POLICY_NAME

aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# 5. Create DynamoDB Table
echo "📊 Creating DynamoDB Table..."
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions \
        AttributeName=session_id,AttributeType=S \
        AttributeName=timestamp,AttributeType=S \
    --key-schema \
        AttributeName=session_id,KeyType=HASH \
        AttributeName=timestamp,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION

# 6. Create S3 Bucket for logs
echo "📦 Creating S3 Bucket..."
aws s3 mb s3://$S3_BUCKET --region $REGION

# 7. List available Bedrock models
echo "🤖 Available Bedrock Models:"
aws bedrock list-foundation-models --region $REGION --query 'modelSummaries[?contains(modelId, `anthropic`) || contains(modelId, `meta`) || contains(modelId, `ai21`)].{ModelId:modelId, ModelName:modelName}' --output table

echo ""
echo "✅ Setup complete! Next steps:"
echo "   1. Deploy Lambda function"
echo "   2. Create API Gateway"
echo "   3. Build frontend"
echo ""
echo "📋 Resource ARNs:"
echo "   Role ARN: arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
echo "   DynamoDB: arn:aws:dynamodb:$REGION:$ACCOUNT_ID:table/$DYNAMODB_TABLE"
echo "   S3 Bucket: arn:aws:s3:::$S3_BUCKET"
