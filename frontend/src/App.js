import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import ChatInterface from './components/ChatInterface';
import DomainSelector from './components/DomainSelector';
import ModelSelector from './components/ModelSelector';
import ChatHistory from './components/ChatHistory';
import './App.css';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'https://your-api-id.execute-api.us-east-1.amazonaws.com/prod';

function App() {
  const [selectedDomain, setSelectedDomain] = useState('general');
  const [selectedModel, setSelectedModel] = useState('anthropic.claude-3-sonnet-20240229-v1:0');
  const [sessionId, setSessionId] = useState(null);
  const [chatHistory, setChatHistory] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    // Generate session ID on app load
    const newSessionId = generateSessionId();
    setSessionId(newSessionId);
  }, []);

  const generateSessionId = () => {
    return 'session_' + Math.random().toString(36).substr(2, 9) + '_' + Date.now();
  };

  const sendMessage = async (message) => {
    if (!message.trim()) return;

    const userMessage = {
      id: Date.now(),
      type: 'user',
      content: message,
      timestamp: new Date().toISOString()
    };

    setChatHistory(prev => [...prev, userMessage]);
    setIsLoading(true);

    try {
      const response = await fetch(`${API_BASE_URL}/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: message,
          session_id: sessionId,
          domain: selectedDomain,
          model_id: selectedModel
        })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      const botMessage = {
        id: Date.now() + 1,
        type: 'bot',
        content: data.response,
        timestamp: new Date().toISOString(),
        model_used: data.model_used,
        domain: data.domain
      };

      setChatHistory(prev => [...prev, botMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = {
        id: Date.now() + 1,
        type: 'error',
        content: 'Sorry, I encountered an error. Please try again.',
        timestamp: new Date().toISOString()
      };
      setChatHistory(prev => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const clearChat = () => {
    setChatHistory([]);
    setSessionId(generateSessionId());
  };

  const changeDomain = (domain) => {
    setSelectedDomain(domain);
    // Optionally clear chat when changing domains
    if (chatHistory.length > 0) {
      const shouldClear = window.confirm('Changing domain will start a new conversation. Continue?');
      if (shouldClear) {
        clearChat();
      }
    }
  };

  return (
    <Router>
      <div className="App">
        <header className="App-header">
          <h1>🤖 AWS Bedrock GenAI Chatbot</h1>
          <p>Powered by foundation models from Anthropic, Meta, and AI21</p>
        </header>
        
        <div className="app-container">
          <div className="sidebar">
            <DomainSelector 
              selectedDomain={selectedDomain}
              onDomainChange={changeDomain}
            />
            <ModelSelector 
              selectedModel={selectedModel}
              onModelChange={setSelectedModel}
            />
            <div className="session-info">
              <small>Session: {sessionId?.substring(0, 12)}...</small>
            </div>
          </div>

          <div className="main-content">
            <Routes>
              <Route path="/" element={
                <ChatInterface 
                  chatHistory={chatHistory}
                  onSendMessage={sendMessage}
                  isLoading={isLoading}
                  onClearChat={clearChat}
                  selectedDomain={selectedDomain}
                  selectedModel={selectedModel}
                />
              } />
              <Route path="/history" element={
                <ChatHistory 
                  chatHistory={chatHistory}
                  sessionId={sessionId}
                />
              } />
            </Routes>
          </div>
        </div>
      </div>
    </Router>
  );
}

export default App;
