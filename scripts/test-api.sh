#!/bin/bash

echo "🧪 Testing AWS Bedrock Chatbot API..."
echo ""

# Test the chat endpoint
echo "Testing /chat endpoint:"
curl -X POST https://9ml2il3c92.execute-api.us-east-1.amazonaws.com/prod/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello! Please respond with just \"Bedrock is working!\"", "domain": "general"}'

echo ""
echo ""

# Test the models endpoint  
echo "Testing /models endpoint:"
curl -X GET https://9ml2il3c92.execute-api.us-east-1.amazonaws.com/prod/models

echo ""
echo ""
echo "✅ If you see a proper response above, your chatbot is working!"
echo "🌐 Frontend URL: http://localhost:3001"
