import React from 'react';
import ReactMarkdown from 'react-markdown';

const ChatHistory = ({ chatHistory, sessionId }) => {
  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleString();
  };

  const exportChatHistory = () => {
    const exportData = {
      sessionId,
      exportDate: new Date().toISOString(),
      messages: chatHistory
    };

    const dataStr = JSON.stringify(exportData, null, 2);
    const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
    
    const exportFileDefaultName = `chat-history-${sessionId?.substring(0, 8)}-${new Date().toISOString().split('T')[0]}.json`;
    
    const linkElement = document.createElement('a');
    linkElement.setAttribute('href', dataUri);
    linkElement.setAttribute('download', exportFileDefaultName);
    linkElement.click();
  };

  const getMessageStats = () => {
    const userMessages = chatHistory.filter(msg => msg.type === 'user').length;
    const botMessages = chatHistory.filter(msg => msg.type === 'bot').length;
    const errorMessages = chatHistory.filter(msg => msg.type === 'error').length;
    
    return { userMessages, botMessages, errorMessages };
  };

  const stats = getMessageStats();

  return (
    <div className="chat-history">
      <div className="history-header">
        <h2>Chat History</h2>
        <div className="history-stats">
          <div className="stat">
            <span className="stat-number">{stats.userMessages}</span>
            <span className="stat-label">User Messages</span>
          </div>
          <div className="stat">
            <span className="stat-number">{stats.botMessages}</span>
            <span className="stat-label">Bot Responses</span>
          </div>
          {stats.errorMessages > 0 && (
            <div className="stat error">
              <span className="stat-number">{stats.errorMessages}</span>
              <span className="stat-label">Errors</span>
            </div>
          )}
        </div>
        <div className="history-actions">
          <button 
            onClick={exportChatHistory}
            disabled={chatHistory.length === 0}
            className="export-btn"
          >
            📥 Export History
          </button>
        </div>
      </div>

      <div className="history-content">
        {chatHistory.length === 0 ? (
          <div className="empty-history">
            <p>No chat history available. Start a conversation to see messages here.</p>
          </div>
        ) : (
          <div className="history-messages">
            {chatHistory.map((message, index) => (
              <div key={message.id || index} className={`history-message ${message.type}`}>
                <div className="message-header">
                  <span className="message-type">
                    {message.type === 'user' ? '👤 You' : 
                     message.type === 'bot' ? '🤖 Assistant' : 
                     '❌ Error'}
                  </span>
                  <span className="message-timestamp">
                    {formatTimestamp(message.timestamp)}
                  </span>
                </div>
                
                <div className="message-content">
                  {message.type === 'bot' ? (
                    <ReactMarkdown>{message.content}</ReactMarkdown>
                  ) : (
                    <p>{message.content}</p>
                  )}
                </div>

                {message.model_used && (
                  <div className="message-metadata">
                    <small>Model: {message.model_used}</small>
                    {message.domain && (
                      <small> • Domain: {message.domain}</small>
                    )}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      <style jsx>{`
        .chat-history {
          background: rgba(255, 255, 255, 0.95);
          border-radius: 15px;
          padding: 2rem;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
          backdrop-filter: blur(10px);
          max-height: 80vh;
          overflow-y: auto;
        }

        .history-header {
          border-bottom: 2px solid #e0e0e0;
          padding-bottom: 1.5rem;
          margin-bottom: 1.5rem;
        }

        .history-header h2 {
          color: #333;
          margin-bottom: 1rem;
        }

        .history-stats {
          display: flex;
          gap: 2rem;
          margin-bottom: 1rem;
        }

        .stat {
          text-align: center;
        }

        .stat-number {
          display: block;
          font-size: 2rem;
          font-weight: bold;
          color: #667eea;
        }

        .stat.error .stat-number {
          color: #ff6b6b;
        }

        .stat-label {
          font-size: 0.9rem;
          color: #666;
        }

        .history-actions {
          margin-top: 1rem;
        }

        .export-btn {
          background: #667eea;
          color: white;
          border: none;
          padding: 0.75rem 1.5rem;
          border-radius: 10px;
          cursor: pointer;
          font-size: 0.9rem;
          transition: background 0.2s ease;
        }

        .export-btn:hover:not(:disabled) {
          background: #5a6fd8;
        }

        .export-btn:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        .empty-history {
          text-align: center;
          color: #666;
          font-style: italic;
          padding: 3rem;
        }

        .history-messages {
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
        }

        .history-message {
          border: 1px solid #e0e0e0;
          border-radius: 10px;
          padding: 1.5rem;
          background: white;
        }

        .history-message.user {
          border-left: 4px solid #667eea;
        }

        .history-message.bot {
          border-left: 4px solid #4caf50;
        }

        .history-message.error {
          border-left: 4px solid #ff6b6b;
          background: #fff5f5;
        }

        .message-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 1rem;
          font-size: 0.9rem;
        }

        .message-type {
          font-weight: bold;
          color: #333;
        }

        .message-timestamp {
          color: #666;
        }

        .message-content {
          color: #333;
          line-height: 1.6;
        }

        .message-metadata {
          margin-top: 1rem;
          padding-top: 0.5rem;
          border-top: 1px solid #f0f0f0;
          color: #666;
          font-size: 0.8rem;
        }

        .message-metadata small {
          margin-right: 1rem;
        }
      `}</style>
    </div>
  );
};

export default ChatHistory;
