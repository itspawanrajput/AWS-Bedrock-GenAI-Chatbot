import json
import boto3
import uuid
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import os

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
bedrock_client = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# Environment variables
CHAT_HISTORY_TABLE = os.environ.get('CHAT_HISTORY_TABLE', 'bedrock-chat-history')
LOGS_BUCKET = os.environ.get('LOGS_BUCKET', 'bedrock-chat-logs')

# Domain-specific system prompts
DOMAIN_PROMPTS = {
    'hr': """You are an HR assistant. Help with employee policies, benefits, 
    leave requests, and workplace guidelines. Be professional and empathetic.""",
    
    'medical': """You are a medical triage assistant. Provide general health 
    information and guidance. Always remind users to consult healthcare professionals 
    for serious concerns. Do not provide specific medical diagnoses.""",
    
    'legal': """You are a legal document assistant. Help explain legal concepts 
    and documents in plain language. Always remind users to consult qualified 
    attorneys for legal advice.""",
    
    'finance': """You are a financial analysis assistant. Help with financial 
    reports, budgeting, and basic financial concepts. Do not provide specific 
    investment advice.""",
    
    'general': """You are a helpful AI assistant. Provide accurate, helpful, 
    and professional responses to user queries."""
}

# Model configurations
MODEL_CONFIGS = {
    'anthropic.claude-3-sonnet-20240229-v1:0': {
        'max_tokens': 4000,
        'temperature': 0.7,
        'top_p': 1.0
    },
    'anthropic.claude-3-haiku-20240307-v1:0': {
        'max_tokens': 4000,
        'temperature': 0.7,
        'top_p': 1.0
    },
    'meta.llama3-70b-instruct-v1:0': {
        'max_gen_len': 2048,
        'temperature': 0.7,
        'top_p': 0.9
    },
    'ai21.j2-ultra-v1': {
        'maxTokens': 2048,
        'temperature': 0.7,
        'topP': 1.0
    }
}

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for Bedrock chatbot
    """
    try:
        # Handle CORS preflight request
        if event.get('httpMethod') == 'OPTIONS':
            return create_response(200, {'message': 'CORS preflight successful'})
        
        # Parse request
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        # Extract parameters
        message = body.get('message', '')
        session_id = body.get('session_id', str(uuid.uuid4()))
        domain = body.get('domain', 'general')
        model_id = body.get('model_id', 'anthropic.claude-3-sonnet-20240229-v1:0')
        
        if not message:
            return create_response(400, {'error': 'Message is required'})
        
        # Get chat history
        chat_history = get_chat_history(session_id)
        
        # Prepare prompt
        system_prompt = DOMAIN_PROMPTS.get(domain, DOMAIN_PROMPTS['general'])
        full_prompt = build_conversation_prompt(system_prompt, chat_history, message)
        
        # Invoke Bedrock model
        response = invoke_bedrock_model(model_id, full_prompt)
        
        # Save to chat history
        save_chat_message(session_id, message, response, domain, model_id)
        
        # Log to S3
        log_interaction(session_id, message, response, domain, model_id)
        
        return create_response(200, {
            'response': response,
            'session_id': session_id,
            'domain': domain,
            'model_used': model_id
        })
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return create_response(500, {'error': 'Internal server error'})

def invoke_bedrock_model(model_id: str, prompt: str) -> str:
    """
    Invoke specific Bedrock model with appropriate formatting
    """
    try:
        if model_id.startswith('anthropic.claude'):
            return invoke_claude_model(model_id, prompt)
        elif model_id.startswith('meta.llama'):
            return invoke_llama_model(model_id, prompt)
        elif model_id.startswith('ai21'):
            return invoke_ai21_model(model_id, prompt)
        else:
            raise ValueError(f"Unsupported model: {model_id}")
            
    except Exception as e:
        logger.error(f"Error invoking model {model_id}: {str(e)}")
        raise

def invoke_claude_model(model_id: str, prompt: str) -> str:
    """
    Invoke Anthropic Claude model
    """
    config = MODEL_CONFIGS.get(model_id, MODEL_CONFIGS['anthropic.claude-3-sonnet-20240229-v1:0'])
    
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": config['max_tokens'],
        "temperature": config['temperature'],
        "top_p": config['top_p'],
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ]
    }
    
    response = bedrock_client.invoke_model(
        body=json.dumps(body),
        modelId=model_id
    )
    
    response_body = json.loads(response.get('body').read())
    return response_body['content'][0]['text']

def invoke_llama_model(model_id: str, prompt: str) -> str:
    """
    Invoke Meta Llama model
    """
    config = MODEL_CONFIGS.get(model_id, MODEL_CONFIGS['meta.llama3-70b-instruct-v1:0'])
    
    body = {
        "prompt": prompt,
        "max_gen_len": config['max_gen_len'],
        "temperature": config['temperature'],
        "top_p": config['top_p']
    }
    
    response = bedrock_client.invoke_model(
        body=json.dumps(body),
        modelId=model_id
    )
    
    response_body = json.loads(response.get('body').read())
    return response_body['generation']

def invoke_ai21_model(model_id: str, prompt: str) -> str:
    """
    Invoke AI21 Jurassic model
    """
    config = MODEL_CONFIGS.get(model_id, MODEL_CONFIGS['ai21.j2-ultra-v1'])
    
    body = {
        "prompt": prompt,
        "maxTokens": config['maxTokens'],
        "temperature": config['temperature'],
        "topP": config['topP']
    }
    
    response = bedrock_client.invoke_model(
        body=json.dumps(body),
        modelId=model_id
    )
    
    response_body = json.loads(response.get('body').read())
    return response_body['completions'][0]['data']['text']

def build_conversation_prompt(system_prompt: str, chat_history: list, current_message: str) -> str:
    """
    Build conversation prompt with history
    """
    prompt = f"{system_prompt}\n\n"
    
    # Add chat history
    for entry in chat_history[-5:]:  # Last 5 messages for context
        prompt += f"Human: {entry['user_message']}\n"
        prompt += f"Assistant: {entry['bot_response']}\n\n"
    
    # Add current message
    prompt += f"Human: {current_message}\n"
    prompt += "Assistant: "
    
    return prompt

def get_chat_history(session_id: str) -> list:
    """
    Retrieve chat history from DynamoDB
    """
    try:
        table = dynamodb.Table(CHAT_HISTORY_TABLE)
        response = table.query(
            KeyConditionExpression='session_id = :session_id',
            ExpressionAttributeValues={':session_id': session_id},
            ScanIndexForward=True,
            Limit=10
        )
        return response.get('Items', [])
    except Exception as e:
        logger.error(f"Error retrieving chat history: {str(e)}")
        return []

def save_chat_message(session_id: str, user_message: str, bot_response: str, domain: str, model_id: str):
    """
    Save chat message to DynamoDB
    """
    try:
        table = dynamodb.Table(CHAT_HISTORY_TABLE)
        timestamp = datetime.utcnow().isoformat()
        
        table.put_item(
            Item={
                'session_id': session_id,
                'timestamp': timestamp,
                'user_message': user_message,
                'bot_response': bot_response,
                'domain': domain,
                'model_id': model_id
            }
        )
    except Exception as e:
        logger.error(f"Error saving chat message: {str(e)}")

def log_interaction(session_id: str, user_message: str, bot_response: str, domain: str, model_id: str):
    """
    Log interaction to S3 for analytics
    """
    try:
        log_data = {
            'session_id': session_id,
            'timestamp': datetime.utcnow().isoformat(),
            'user_message': user_message,
            'bot_response': bot_response,
            'domain': domain,
            'model_id': model_id
        }
        
        key = f"logs/{datetime.utcnow().strftime('%Y/%m/%d')}/{session_id}_{uuid.uuid4().hex[:8]}.json"
        
        s3_client.put_object(
            Bucket=LOGS_BUCKET,
            Key=key,
            Body=json.dumps(log_data),
            ContentType='application/json'
        )
    except Exception as e:
        logger.error(f"Error logging to S3: {str(e)}")

def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create API Gateway response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        },
        'body': json.dumps(body)
    }
