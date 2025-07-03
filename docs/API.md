# 📡 API Documentation

Complete API reference for the AWS Bedrock GenAI Chatbot.

## 🌐 Base URL

```
https://your-api-id.execute-api.us-east-1.amazonaws.com/prod
```

## 🔐 Authentication

Currently, the API uses CORS for web access. For production, consider adding:
- API Gateway API Keys
- AWS Cognito authentication
- Custom authorizers

## 📋 Endpoints

### 💬 POST /chat

Send a message to the chatbot and receive an AI response.

#### Request

```bash
POST /chat
Content-Type: application/json
```

**Body Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | string | Yes | The user's message to the chatbot |
| `session_id` | string | No | Session ID for conversation context |
| `domain` | string | No | Domain specialization (default: "general") |
| `model_id` | string | No | AI model to use (default: Claude 3 Sonnet) |

**Domain Options:**
- `general` - General purpose assistant
- `hr` - HR policies and workplace guidelines
- `medical` - Health information and guidance
- `legal` - Legal document explanation
- `finance` - Financial analysis and budgeting

**Model Options:**
- `anthropic.claude-3-haiku-20240307-v1:0` - Fast, cost-effective
- `anthropic.claude-3-sonnet-20240229-v1:0` - Balanced performance
- `anthropic.claude-3-opus-20240229-v1:0` - Most capable
- `meta.llama3-70b-instruct-v1:0` - Open source alternative
- `ai21.j2-ultra-v1` - AI21 Labs model

#### Example Request

```bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/prod/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "What are the company vacation policies?",
    "domain": "hr",
    "model_id": "anthropic.claude-3-haiku-20240307-v1:0",
    "session_id": "user-session-123"
  }'
```

#### Response

```json
{
  "response": "Our company offers 15 days of paid vacation per year for full-time employees...",
  "session_id": "user-session-123",
  "domain": "hr",
  "model_used": "anthropic.claude-3-haiku-20240307-v1:0"
}
```

#### Error Responses

**400 Bad Request**
```json
{
  "error": "Message is required"
}
```

**500 Internal Server Error**
```json
{
  "error": "Internal server error"
}
```

### 🤖 GET /models

Get list of available AI models.

#### Request

```bash
GET /models
```

#### Response

```json
{
  "models": [
    {
      "model_id": "anthropic.claude-3-haiku-20240307-v1:0",
      "model_name": "Claude 3 Haiku",
      "provider_name": "Anthropic",
      "input_modalities": ["TEXT"],
      "output_modalities": ["TEXT"],
      "response_streaming_supported": true
    }
  ],
  "total_count": 38
}
```

## 📝 Usage Examples

### JavaScript/React

```javascript
const sendMessage = async (message, domain = 'general') => {
  try {
    const response = await fetch('/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message,
        domain,
        session_id: sessionId
      })
    });
    
    const data = await response.json();
    return data.response;
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
};
```

### Python

```python
import requests

def send_message(message, domain='general', api_url=''):
    payload = {
        'message': message,
        'domain': domain,
        'session_id': 'python-client-session'
    }
    
    response = requests.post(f'{api_url}/chat', json=payload)
    
    if response.status_code == 200:
        return response.json()['response']
    else:
        raise Exception(f"API Error: {response.status_code}")

# Usage
api_url = "https://your-api-id.execute-api.us-east-1.amazonaws.com/prod"
response = send_message("Hello!", "general", api_url)
print(response)
```

### cURL Examples

**Basic Chat:**
```bash
curl -X POST $API_URL/chat \
  -H 'Content-Type: application/json' \
  -d '{"message": "Hello!"}'
```

**HR Domain:**
```bash
curl -X POST $API_URL/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "What is our sick leave policy?",
    "domain": "hr"
  }'
```

**Medical Domain:**
```bash
curl -X POST $API_URL/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "I have a headache, what should I do?",
    "domain": "medical"
  }'
```

**Specific Model:**
```bash
curl -X POST $API_URL/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "message": "Explain quantum computing",
    "model_id": "anthropic.claude-3-opus-20240229-v1:0"
  }'
```

## 📊 Response Times

Typical response times by model:

| Model | Avg Response Time | Use Case |
|-------|------------------|----------|
| Claude 3 Haiku | 1-3 seconds | Quick questions, simple tasks |
| Claude 3 Sonnet | 2-5 seconds | Balanced performance |
| Claude 3 Opus | 3-8 seconds | Complex reasoning, analysis |
| Llama 3 70B | 2-6 seconds | Code generation, math |
| Jurassic-2 Ultra | 2-5 seconds | Creative writing, analysis |

## 🔄 Session Management

Sessions maintain conversation context:

```javascript
// Create a session
const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

// Use throughout conversation
const messages = [
  { message: "Hello", session_id: sessionId },
  { message: "Tell me about AI", session_id: sessionId },
  { message: "Can you explain more?", session_id: sessionId }
];
```

## 🚫 Rate Limiting

Current limits (configurable):
- **100 requests per second** per API key
- **10,000 requests per month** per user
- **No concurrent request limit**

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1640995200
```

## 🔍 Error Handling

### Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| 400 | Bad Request | Check request format and required fields |
| 403 | Forbidden | Verify API key or CORS settings |
| 429 | Rate Limited | Implement exponential backoff |
| 500 | Server Error | Check Bedrock model access and retry |
| 502 | Bad Gateway | Temporary AWS issue, retry |
| 503 | Service Unavailable | Lambda cold start or scaling |

### Retry Logic

```javascript
const retryWithBackoff = async (fn, maxRetries = 3) => {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (error.status === 429 || error.status >= 500) {
        const delay = Math.pow(2, i) * 1000; // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }
      throw error;
    }
  }
  throw new Error('Max retries exceeded');
};
```

## 📈 Monitoring

### CloudWatch Metrics

Available metrics:
- `APIGateway/4XXError` - Client errors
- `APIGateway/5XXError` - Server errors
- `APIGateway/Latency` - Response times
- `Lambda/Duration` - Function execution time
- `Lambda/Errors` - Function errors
- `DynamoDB/ConsumedReadCapacityUnits` - Database reads
- `DynamoDB/ConsumedWriteCapacityUnits` - Database writes

### Custom Metrics

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

def track_api_usage(domain, model_id, response_time):
    cloudwatch.put_metric_data(
        Namespace='BedrockChatbot/API',
        MetricData=[
            {
                'MetricName': 'ResponseTime',
                'Dimensions': [
                    {'Name': 'Domain', 'Value': domain},
                    {'Name': 'Model', 'Value': model_id}
                ],
                'Value': response_time,
                'Unit': 'Seconds'
            }
        ]
    )
```

## 🔐 Security Best Practices

### Input Validation
- Sanitize all user inputs
- Limit message length (max 4000 characters)
- Validate domain and model parameters
- Rate limit per session/IP

### Output Filtering
- Filter sensitive information in responses
- Implement content moderation
- Log security events

### API Security
```javascript
// Example secure request
const secureRequest = async (message) => {
  // Input validation
  if (!message || message.length > 4000) {
    throw new Error('Invalid message');
  }
  
  // Sanitize input
  const sanitized = message.replace(/<script.*?>.*?<\/script>/gi, '');
  
  // Make request with timeout
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 30000);
  
  try {
    const response = await fetch('/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ message: sanitized }),
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);
    return response.json();
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
};
```
