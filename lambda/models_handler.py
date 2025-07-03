import json
import boto3
import logging
from typing import Dict, Any

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize Bedrock client
bedrock_client = boto3.client('bedrock')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler for listing available Bedrock models
    """
    try:
        # List foundation models
        response = bedrock_client.list_foundation_models()
        
        # Filter and format models
        models = []
        for model in response.get('modelSummaries', []):
            model_id = model.get('modelId', '')
            
            # Filter for supported models
            if any(provider in model_id.lower() for provider in ['anthropic', 'meta', 'ai21']):
                models.append({
                    'model_id': model_id,
                    'model_name': model.get('modelName', ''),
                    'provider_name': model.get('providerName', ''),
                    'input_modalities': model.get('inputModalities', []),
                    'output_modalities': model.get('outputModalities', []),
                    'response_streaming_supported': model.get('responseStreamingSupported', False)
                })
        
        # Sort models by provider
        models.sort(key=lambda x: (x['provider_name'], x['model_name']))
        
        return create_response(200, {
            'models': models,
            'total_count': len(models)
        })
        
    except Exception as e:
        logger.error(f"Error listing models: {str(e)}")
        return create_response(500, {'error': 'Failed to retrieve models'})

def create_response(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create API Gateway response with CORS headers
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
