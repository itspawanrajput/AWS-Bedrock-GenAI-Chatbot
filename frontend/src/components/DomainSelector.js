import React from 'react';

const DomainSelector = ({ selectedDomain, onDomainChange }) => {
  const domains = [
    { 
      id: 'general', 
      label: 'General Assistant', 
      icon: '🤖',
      description: 'General purpose AI assistant'
    },
    { 
      id: 'hr', 
      label: 'HR Assistant', 
      icon: '👔',
      description: 'Employee policies & workplace guidelines'
    },
    { 
      id: 'medical', 
      label: 'Medical Triage', 
      icon: '🏥',
      description: 'Health information & guidance'
    },
    { 
      id: 'legal', 
      label: 'Legal Assistant', 
      icon: '⚖️',
      description: 'Legal documents & concepts'
    },
    { 
      id: 'finance', 
      label: 'Financial Advisor', 
      icon: '💰',
      description: 'Financial analysis & budgeting'
    }
  ];

  return (
    <div className="domain-selector">
      <h3>Select Domain</h3>
      <div className="domain-options">
        {domains.map((domain) => (
          <div 
            key={domain.id}
            className={`domain-option ${selectedDomain === domain.id ? 'active' : ''}`}
            onClick={() => onDomainChange(domain.id)}
          >
            <input
              type="radio"
              id={domain.id}
              name="domain"
              value={domain.id}
              checked={selectedDomain === domain.id}
              onChange={() => onDomainChange(domain.id)}
            />
            <label htmlFor={domain.id}>
              <div>
                <strong>{domain.label}</strong>
                <br />
                <small style={{color: '#666'}}>{domain.description}</small>
              </div>
            </label>
            <span>{domain.icon}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default DomainSelector;
