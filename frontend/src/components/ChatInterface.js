import React, { useState, useRef, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';

const ChatInterface = ({ 
  chatHistory, 
  onSendMessage, 
  isLoading, 
  onClearChat, 
  selectedDomain, 
  selectedModel 
}) => {
  const [inputMessage, setInputMessage] = useState('');
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);

  // Domain info for display
  const domainInfo = {
    'hr': { name: 'HR Assistant', icon: '👔', description: 'Employee policies, benefits, and workplace guidelines' },
    'medical': { name: 'Medical Triage', icon: '🏥', description: 'General health information and guidance' },
    'legal': { name: 'Legal Assistant', icon: '⚖️', description: 'Legal document explanation and concepts' },
    'finance': { name: 'Financial Advisor', icon: '💰', description: 'Financial analysis and budgeting help' },
    'general': { name: 'General Assistant', icon: '🤖', description: 'General purpose AI assistant' }
  };

  // Model display names
  const modelNames = {
    'anthropic.claude-3-sonnet-20240229-v1:0': 'Claude 3 Sonnet',
    'anthropic.claude-3-haiku-20240307-v1:0': 'Claude 3 Haiku',
    'meta.llama3-70b-instruct-v1:0': 'Llama 3 70B',
    'ai21.j2-ultra-v1': 'Jurassic-2 Ultra'
  };

  // Auto-scroll to bottom when new messages arrive
  useEffect(() => {
    scrollToBottom();
  }, [chatHistory]);

  // Focus input when component mounts
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.focus();
    }
  }, []);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (inputMessage.trim() && !isLoading) {
      onSendMessage(inputMessage);
      setInputMessage('');
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };

  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleTimeString();
  };

  const currentDomain = domainInfo[selectedDomain] || domainInfo['general'];

  return (
    <div className="chat-interface">
      <div className="chat-header">
        <h3>
          <span>{currentDomain.icon}</span> {currentDomain.name}
        </h3>
        <p>{currentDomain.description}</p>
        <p style={{ fontSize: '0.8rem', marginTop: '0.25rem' }}>
          Using: {modelNames[selectedModel] || selectedModel}
        </p>
        <div className="chat-actions">
          <button 
            className="clear-chat-btn" 
            onClick={onClearChat}
            disabled={chatHistory.length === 0}
          >
            Clear Chat
          </button>
        </div>
      </div>

      <div className="chat-messages">
        {chatHistory.length === 0 && (
          <div className="welcome-message">
            <h4>Welcome to {currentDomain.name}! 👋</h4>
            <p>Ask me anything about {currentDomain.description.toLowerCase()}.</p>
            
            {selectedDomain === 'hr' && (
              <div className="example-questions">
                <p><strong>Try asking:</strong></p>
                <ul>
                  <li>"What are the company vacation policies?"</li>
                  <li>"How do I submit a leave request?"</li>
                  <li>"What benefits are available to employees?"</li>
                </ul>
              </div>
            )}
            
            {selectedDomain === 'medical' && (
              <div className="example-questions">
                <p><strong>Try asking:</strong></p>
                <ul>
                  <li>"What are the symptoms of common cold?"</li>
                  <li>"When should I see a doctor?"</li>
                  <li>"Basic first aid for minor cuts?"</li>
                </ul>
              </div>
            )}
            
            {selectedDomain === 'legal' && (
              <div className="example-questions">
                <p><strong>Try asking:</strong></p>
                <ul>
                  <li>"Explain this contract clause"</li>
                  <li>"What is intellectual property?"</li>
                  <li>"Basic tenant rights overview"</li>
                </ul>
              </div>
            )}
            
            {selectedDomain === 'finance' && (
              <div className="example-questions">
                <p><strong>Try asking:</strong></p>
                <ul>
                  <li>"Help me understand this financial report"</li>
                  <li>"Basic budgeting principles"</li>
                  <li>"What is compound interest?"</li>
                </ul>
              </div>
            )}
          </div>
        )}

        {chatHistory.map((message) => (
          <div key={message.id} className={`message ${message.type}`}>
            <div className="message-content">
              {message.type === 'bot' ? (
                <ReactMarkdown>{message.content}</ReactMarkdown>
              ) : (
                message.content
              )}
            </div>
            <div className="message-meta">
              {formatTimestamp(message.timestamp)}
              {message.model_used && (
                <span> • {modelNames[message.model_used] || message.model_used}</span>
              )}
            </div>
          </div>
        ))}

        {isLoading && (
          <div className="message bot">
            <div className="loading">Thinking</div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      <form className="chat-input" onSubmit={handleSubmit}>
        <div className="input-group">
          <input
            ref={inputRef}
            type="text"
            value={inputMessage}
            onChange={(e) => setInputMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder={`Ask ${currentDomain.name.toLowerCase()} a question...`}
            disabled={isLoading}
          />
          <button 
            type="submit" 
            className="send-btn"
            disabled={!inputMessage.trim() || isLoading}
          >
            {isLoading ? 'Sending...' : 'Send'}
          </button>
        </div>
      </form>
    </div>
  );
};

export default ChatInterface;
