#!/bin/bash

# AWS Cognito Setup for Bedrock Chatbot
REGION="us-east-1"
USER_POOL_NAME="bedrock-chatbot-users"
CLIENT_NAME="bedrock-chatbot-client"

echo "🔐 Setting up AWS Cognito User Pool..."

# Create User Pool
USER_POOL_ID=$(aws cognito-idp create-user-pool \
    --pool-name $USER_POOL_NAME \
    --region $REGION \
    --policies '{
        "PasswordPolicy": {
            "MinimumLength": 8,
            "RequireUppercase": true,
            "RequireLowercase": true,
            "RequireNumbers": true,
            "RequireSymbols": false
        }
    }' \
    --auto-verified-attributes email \
    --username-attributes email \
    --query 'UserPool.Id' \
    --output text)

echo "User Pool ID: $USER_POOL_ID"

# Create User Pool Client
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id $USER_POOL_ID \
    --client-name $CLIENT_NAME \
    --region $REGION \
    --generate-secret \
    --explicit-auth-flows ADMIN_NO_SRP_AUTH ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
    --query 'UserPoolClient.ClientId' \
    --output text)

echo "Client ID: $CLIENT_ID"

# Get Client Secret
CLIENT_SECRET=$(aws cognito-idp describe-user-pool-client \
    --user-pool-id $USER_POOL_ID \
    --client-id $CLIENT_ID \
    --region $REGION \
    --query 'UserPoolClient.ClientSecret' \
    --output text)

echo "Client Secret: $CLIENT_SECRET"

# Create Identity Pool
IDENTITY_POOL_ID=$(aws cognito-identity create-identity-pool \
    --identity-pool-name "bedrock-chatbot-identity" \
    --allow-unauthenticated-identities \
    --cognito-identity-providers ProviderName=cognito-idp.$REGION.amazonaws.com/$USER_POOL_ID,ClientId=$CLIENT_ID \
    --region $REGION \
    --query 'IdentityPoolId' \
    --output text)

echo "Identity Pool ID: $IDENTITY_POOL_ID"

echo ""
echo "✅ Cognito setup complete!"
echo ""
echo "📋 Configuration Details:"
echo "User Pool ID: $USER_POOL_ID"
echo "Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"
echo "Identity Pool ID: $IDENTITY_POOL_ID"
echo "Region: $REGION"
echo ""
echo "🔧 Update your frontend .env file with these values:"
echo "REACT_APP_USER_POOL_ID=$USER_POOL_ID"
echo "REACT_APP_CLIENT_ID=$CLIENT_ID"
echo "REACT_APP_IDENTITY_POOL_ID=$IDENTITY_POOL_ID"
echo "REACT_APP_REGION=$REGION"
