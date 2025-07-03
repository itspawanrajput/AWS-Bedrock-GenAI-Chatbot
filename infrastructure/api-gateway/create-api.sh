#!/bin/bash

# Create API Gateway for Bedrock Chatbot

API_NAME="bedrock-chatbot-api"
FUNCTION_NAME="bedrock-chatbot-handler"
REGION="us-east-1"
STAGE_NAME="prod"

# Get account ID and function ARN
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
FUNCTION_ARN="arn:aws:lambda:$REGION:$ACCOUNT_ID:function:$FUNCTION_NAME"

echo "🚀 Creating API Gateway..."

# Create REST API
API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --description "GenAI Chatbot API using AWS Bedrock" \
    --region $REGION \
    --query 'id' \
    --output text)

echo "API ID: $API_ID"

# Get root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id $API_ID \
    --region $REGION \
    --query 'items[0].id' \
    --output text)

# Create /chat resource
CHAT_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "chat" \
    --region $REGION \
    --query 'id' \
    --output text)

# Create POST method for /chat
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE \
    --region $REGION

# Create OPTIONS method for CORS
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method OPTIONS \
    --authorization-type NONE \
    --region $REGION

# Set up Lambda integration for POST
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method POST \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$FUNCTION_ARN/invocations" \
    --region $REGION

# Set up CORS integration for OPTIONS
aws apigateway put-integration \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method OPTIONS \
    --type MOCK \
    --integration-http-method OPTIONS \
    --request-templates '{"application/json": "{\"statusCode\": 200}"}' \
    --region $REGION

# Set up method response for POST
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method POST \
    --status-code 200 \
    --response-models '{"application/json": "Empty"}' \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin": false}' \
    --region $REGION

# Set up method response for OPTIONS
aws apigateway put-method-response \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": false,
        "method.response.header.Access-Control-Allow-Methods": false,
        "method.response.header.Access-Control-Allow-Origin": false
    }' \
    --region $REGION

# Set up integration response for POST
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method POST \
    --status-code 200 \
    --response-parameters '{"method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'"}' \
    --region $REGION

# Set up integration response for OPTIONS
aws apigateway put-integration-response \
    --rest-api-id $API_ID \
    --resource-id $CHAT_RESOURCE_ID \
    --http-method OPTIONS \
    --status-code 200 \
    --response-parameters '{
        "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"'"'",
        "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,PUT,DELETE,OPTIONS'"'"'",
        "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'"
    }' \
    --region $REGION

# Create /models resource for listing available models
MODELS_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id $API_ID \
    --parent-id $ROOT_RESOURCE_ID \
    --path-part "models" \
    --region $REGION \
    --query 'id' \
    --output text)

# Create GET method for /models
aws apigateway put-method \
    --rest-api-id $API_ID \
    --resource-id $MODELS_RESOURCE_ID \
    --http-method GET \
    --authorization-type NONE \
    --region $REGION

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
    --function-name $FUNCTION_NAME \
    --statement-id apigateway-invoke \
    --action lambda:InvokeFunction \
    --principal apigateway.amazonaws.com \
    --source-arn "arn:aws:execute-api:$REGION:$ACCOUNT_ID:$API_ID/*/*" \
    --region $REGION

# Deploy API
aws apigateway create-deployment \
    --rest-api-id $API_ID \
    --stage-name $STAGE_NAME \
    --description "Production deployment" \
    --region $REGION

# Output API endpoint
API_ENDPOINT="https://$API_ID.execute-api.$REGION.amazonaws.com/$STAGE_NAME"
echo ""
echo "✅ API Gateway created successfully!"
echo "🌐 API Endpoint: $API_ENDPOINT"
echo "📋 Test with:"
echo "   curl -X POST $API_ENDPOINT/chat \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"message\": \"Hello, how can you help me?\", \"domain\": \"general\"}'"
echo ""
echo "📝 Save these details:"
echo "   API ID: $API_ID"
echo "   API Endpoint: $API_ENDPOINT"
