import React from 'react';

const ModelSelector = ({ selectedModel, onModelChange }) => {
  const models = [
    {
      id: 'anthropic.claude-3-sonnet-20240229-v1:0',
      name: 'Claude 3 Sonnet',
      provider: 'Anthropic',
      description: 'Balanced performance and speed',
      capabilities: ['Text', 'Analysis', 'Reasoning']
    },
    {
      id: 'anthropic.claude-3-haiku-20240307-v1:0',
      name: 'Claude 3 Haiku',
      provider: 'Anthropic',
      description: 'Fast and efficient',
      capabilities: ['Text', 'Quick responses']
    },
    {
      id: 'meta.llama3-70b-instruct-v1:0',
      name: 'Llama 3 70B',
      provider: 'Meta',
      description: 'Open source, instruction-tuned',
      capabilities: ['Text', 'Code', 'Reasoning']
    },
    {
      id: 'ai21.j2-ultra-v1',
      name: 'Jurassic-2 Ultra',
      provider: 'AI21',
      description: 'Advanced language understanding',
      capabilities: ['Text', 'Analysis', 'Writing']
    }
  ];

  const selectedModelInfo = models.find(model => model.id === selectedModel);

  return (
    <div className="model-selector">
      <h3>Foundation Model</h3>
      <select 
        value={selectedModel} 
        onChange={(e) => onModelChange(e.target.value)}
      >
        {models.map((model) => (
          <option key={model.id} value={model.id}>
            {model.name} ({model.provider})
          </option>
        ))}
      </select>
      
      {selectedModelInfo && (
        <div className="model-info" style={{marginTop: '1rem', fontSize: '0.9rem', color: '#666'}}>
          <p><strong>{selectedModelInfo.name}</strong></p>
          <p>{selectedModelInfo.description}</p>
          <p>
            <strong>Capabilities:</strong> {selectedModelInfo.capabilities.join(', ')}
          </p>
        </div>
      )}
    </div>
  );
};

export default ModelSelector;
