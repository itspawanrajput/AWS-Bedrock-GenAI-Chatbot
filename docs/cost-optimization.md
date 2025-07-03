# 💰 AWS Bedrock Chatbot - Cost Optimization Guide

## Cost Breakdown by Service

### 🤖 AWS Bedrock (Primary Cost Driver)
**Pricing Model**: Pay-per-token (input + output tokens)

| Model | Input Tokens (per 1K) | Output Tokens (per 1K) | Performance |
|-------|----------------------|------------------------|-------------|
| Claude 3 Haiku | $0.00025 | $0.00125 | Fastest, cheapest |
| Claude 3 Sonnet | $0.003 | $0.015 | Balanced |
| Llama 3 70B | $0.00265 | $0.0035 | Open source |
| Jurassic-2 Ultra | $0.0125 | $0.0125 | Premium |

**Monthly Estimates** (based on usage):
- **Light usage** (1K messages/month): $10-50
- **Medium usage** (10K messages/month): $100-500  
- **Heavy usage** (100K messages/month): $1K-5K

### ⚡ AWS Lambda
- **Pricing**: $0.20 per 1M requests + $0.0000166667 per GB-second
- **Monthly estimate**: $5-20 for typical usage
- **Optimization**: Use ARM-based Graviton2 processors (20% cost reduction)

### 📊 Amazon DynamoDB
- **Pricing**: Pay-per-request model
- **Read**: $0.25 per million requests
- **Write**: $1.25 per million requests
- **Monthly estimate**: $5-15 for chat history storage

### 🌐 API Gateway
- **Pricing**: $3.50 per million API calls
- **Monthly estimate**: $3-10 for typical usage

### 📦 Amazon S3
- **Pricing**: $0.023 per GB stored + request charges
- **Monthly estimate**: $1-5 for logs and static assets

## 🎯 Cost Optimization Strategies

### 1. Model Selection Strategy
```python
# Smart model routing based on query complexity
def select_optimal_model(query, domain):
    query_length = len(query.split())
    
    if query_length < 10 and domain in ['hr', 'general']:
        return 'anthropic.claude-3-haiku-20240307-v1:0'  # Cheapest
    elif query_length < 50:
        return 'anthropic.claude-3-sonnet-20240229-v1:0'  # Balanced
    else:
        return 'meta.llama3-70b-instruct-v1:0'  # Cost-effective for complex
```

### 2. Caching Implementation
```python
# Add to Lambda function
import hashlib
from datetime import datetime, timedelta

def get_cache_key(message, domain, model_id):
    return hashlib.md5(f"{message}:{domain}:{model_id}".encode()).hexdigest()

def check_cache(cache_key):
    # Check DynamoDB for cached responses (24hr TTL)
    try:
        table = dynamodb.Table('bedrock-cache')
        response = table.get_item(
            Key={'cache_key': cache_key},
            ProjectionExpression='response, created_at'
        )
        
        if 'Item' in response:
            created_at = datetime.fromisoformat(response['Item']['created_at'])
            if datetime.utcnow() - created_at < timedelta(hours=24):
                return response['Item']['response']
    except:
        pass
    return None
```

### 3. Token Optimization
```python
# Optimize prompts to reduce token usage
def optimize_prompt(message, chat_history):
    # Limit chat history to last 3 exchanges
    recent_history = chat_history[-3:] if len(chat_history) > 3 else chat_history
    
    # Compress system prompts
    compressed_prompts = {
        'hr': "HR assistant. Help with policies, benefits, workplace guidelines.",
        'medical': "Medical assistant. General health info. Advise consulting doctors.",
        'legal': "Legal assistant. Explain concepts. Advise consulting attorneys.",
        'finance': "Financial assistant. Analysis & budgeting. No investment advice."
    }
    
    return build_optimized_prompt(compressed_prompts, recent_history, message)
```

### 4. Request Throttling & Rate Limiting
```python
# Add to API Gateway
{
    "ThrottleSettings": {
        "RateLimit": 100,  # requests per second
        "BurstLimit": 200
    },
    "QuotaSettings": {
        "Limit": 10000,  # requests per month
        "Period": "MONTH"
    }
}
```

### 5. Auto-scaling & Resource Management
```yaml
# CloudWatch Alarms for cost monitoring
CostAlarm:
  Type: AWS::CloudWatch::Alarm
  Properties:
    AlarmName: BedrockCostAlarm
    MetricName: EstimatedCharges
    Namespace: AWS/Billing
    Statistic: Maximum
    Period: 86400
    EvaluationPeriods: 1
    Threshold: 100  # Alert at $100/month
    ComparisonOperator: GreaterThanThreshold
```

## 📊 Cost Monitoring Dashboard

### CloudWatch Metrics to Track
1. **Bedrock Token Usage**: Custom metric per model
2. **Lambda Invocations**: Monitor request patterns
3. **DynamoDB Consumption**: Read/write capacity
4. **API Gateway Requests**: Total calls per day
5. **Error Rates**: Failed requests waste money

### Sample Cost Tracking Lambda
```python
import boto3

def track_bedrock_costs(model_id, input_tokens, output_tokens):
    cloudwatch = boto3.client('cloudwatch')
    
    pricing = {
        'anthropic.claude-3-haiku-20240307-v1:0': {'input': 0.00025, 'output': 0.00125},
        'anthropic.claude-3-sonnet-20240229-v1:0': {'input': 0.003, 'output': 0.015},
        # Add other models...
    }
    
    if model_id in pricing:
        cost = (input_tokens * pricing[model_id]['input'] / 1000) + \
               (output_tokens * pricing[model_id]['output'] / 1000)
        
        cloudwatch.put_metric_data(
            Namespace='BedrockChatbot/Costs',
            MetricData=[
                {
                    'MetricName': 'TokenCost',
                    'Dimensions': [
                        {'Name': 'ModelId', 'Value': model_id}
                    ],
                    'Value': cost,
                    'Unit': 'None'
                }
            ]
        )
```

## 🏢 Production Cost Controls

### 1. Environment-based Limits
```python
# Different limits per environment
LIMITS = {
    'dev': {'max_tokens': 1000, 'rate_limit': 10},
    'staging': {'max_tokens': 2000, 'rate_limit': 50},
    'prod': {'max_tokens': 4000, 'rate_limit': 100}
}
```

### 2. User-based Quotas
```python
# Implement user quotas
async def check_user_quota(user_id):
    daily_usage = get_daily_usage(user_id)
    user_tier = get_user_tier(user_id)
    
    limits = {
        'free': 50,      # 50 messages/day
        'premium': 500,  # 500 messages/day  
        'enterprise': 5000  # 5000 messages/day
    }
    
    return daily_usage < limits.get(user_tier, 50)
```

### 3. Automated Cost Alerts
```bash
# AWS CLI command to set up billing alerts
aws cloudwatch put-metric-alarm \
    --alarm-name "BedrockMonthlyCost" \
    --alarm-description "Alert when monthly Bedrock costs exceed $500" \
    --metric-name EstimatedCharges \
    --namespace AWS/Billing \
    --statistic Maximum \
    --period 86400 \
    --threshold 500 \
    --comparison-operator GreaterThanThreshold \
    --evaluation-periods 1 \
    --alarm-actions arn:aws:sns:us-east-1:ACCOUNT:billing-alerts
```

## 💡 Best Practices Summary

1. **Start with Claude 3 Haiku** for development and testing
2. **Implement response caching** for common queries
3. **Use conversation history limits** (3-5 exchanges max)
4. **Set up cost alerts** at $50, $100, $500 thresholds
5. **Monitor token usage** per model and optimize accordingly
6. **Implement rate limiting** to prevent runaway costs
7. **Use reserved capacity** for DynamoDB if usage is predictable
8. **Enable S3 lifecycle policies** to archive old logs

## 📈 ROI Considerations

### Cost vs. Value Calculation
- **Customer support automation**: 80% reduction in tickets
- **Employee self-service**: 50% reduction in HR inquiries  
- **Document processing**: 90% faster than manual review
- **24/7 availability**: No overtime costs

### Break-even Analysis
For most organizations:
- **Investment**: $5K-15K development + $100-1K/month operating
- **Savings**: $10K-50K/month in reduced support costs
- **ROI**: 200-400% within 6 months

This makes the Bedrock chatbot highly cost-effective for medium to large organizations.
