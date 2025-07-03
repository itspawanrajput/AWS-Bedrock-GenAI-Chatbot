# 🎯 AWS Bedrock Chatbot Use Cases & Examples

## 1. 👔 HR FAQ Bot

### Use Case Overview
Automate employee inquiries about policies, benefits, leave requests, and workplace guidelines.

### Sample Interactions

**Employee**: "What's our work from home policy?"

**HR Bot**: "Our hybrid work policy allows employees to work from home up to 3 days per week. Here are the key points:

- **Eligibility**: All full-time employees after 90-day probation
- **Schedule**: Must maintain consistent schedule (same days each week)
- **Equipment**: Company laptop and VPN access required
- **Meetings**: Must be available for in-person meetings with 24hr notice
- **Performance**: Productivity metrics will be monitored monthly

To set up your WFH schedule, please submit a request through the HR portal or speak with your manager."

---

**Employee**: "How do I request vacation time?"

**HR Bot**: "Here's how to request vacation time:

**📝 Process:**
1. Log into the HR portal (portal.company.com)
2. Navigate to "Time Off" → "Request Vacation"
3. Select dates and provide reason
4. Submit for manager approval

**⏰ Timeline:**
- Submit at least 2 weeks in advance
- 30 days advance notice for requests over 1 week
- Holiday periods require 60 days notice

**📋 Requirements:**
- Minimum 4-hour increments
- Maximum 2 consecutive weeks without VP approval
- Cannot exceed available balance

**✅ Approval:**
Your manager has 3 business days to approve. You'll receive email confirmation once approved."

### Integration with Company Systems
```python
# Example integration with HR systems
def get_employee_info(employee_id):
    return {
        'vacation_balance': 120,  # hours
        'hire_date': '2023-01-15',
        'department': 'Engineering',
        'manager': 'Sarah Johnson'
    }

# Enhanced HR prompt with employee context
hr_system_prompt = f"""
You are an HR assistant for TechCorp. Employee ID: {employee_id}
Current vacation balance: {vacation_balance} hours
Department: {department}
Manager: {manager}

Provide personalized responses based on employee data. Always remind them to check the employee handbook for detailed policies.
"""
```

---

## 2. 🏥 Medical Triage Assistant

### Use Case Overview
Provide general health guidance and help users determine when to seek medical care.

### Sample Interactions

**Patient**: "I have a persistent cough for 3 weeks with some fever. Should I see a doctor?"

**Medical Bot**: "⚠️ **Based on your symptoms, you should see a healthcare provider soon.**

**Your symptoms suggest:**
- Possible respiratory infection
- Bronchitis or pneumonia
- Post-viral syndrome

**🚨 See a doctor if you have:**
- Fever over 101°F (38.3°C)
- Difficulty breathing or shortness of breath
- Chest pain
- Coughing up blood
- Symptoms worsening after initial improvement

**📞 When to seek immediate care:**
- Severe difficulty breathing
- High fever with chills
- Chest pain with breathing
- Confusion or severe fatigue

**💡 General advice:**
- Stay hydrated
- Rest adequately
- Avoid smoking/vaping
- Use a humidifier

**⚕️ Important:** This is general information only. Please consult with a healthcare professional for proper diagnosis and treatment."

---

**Patient**: "What should I do for a minor cut on my finger?"

**Medical Bot**: "For a minor finger cut, here's the basic first aid:

**🧼 Immediate Steps:**
1. **Clean your hands** with soap and water
2. **Control bleeding** by applying direct pressure with clean cloth
3. **Clean the wound** gently with water (avoid hydrogen peroxide)
4. **Apply antibiotic ointment** if available
5. **Cover with bandage** - change daily or when wet

**🩹 Care Instructions:**
- Keep wound clean and dry
- Change bandage daily
- Watch for signs of infection

**⚠️ Seek medical attention if:**
- Cut is deep (you can see fat, muscle, or bone)
- Bleeding won't stop after 10 minutes of pressure
- Object is embedded in wound
- Signs of infection: increased pain, redness, warmth, pus, fever
- Wound edges won't stay closed
- Numbness or inability to move finger normally

**🔄 Follow-up:**
Minor cuts typically heal in 7-10 days. If you have concerns about healing, consult your healthcare provider."

### Safety Features
```python
# Medical safety checks
def check_emergency_keywords(message):
    emergency_keywords = [
        'chest pain', 'can\'t breathe', 'severe bleeding', 
        'unconscious', 'overdose', 'suicide', 'heart attack'
    ]
    
    if any(keyword in message.lower() for keyword in emergency_keywords):
        return "🚨 EMERGENCY: Call 911 immediately or go to the nearest emergency room. This chatbot cannot help with emergency situations."
    
    return None

# Always include disclaimer
medical_disclaimer = """
⚕️ **Medical Disclaimer:** This information is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.
"""
```

---

## 3. ⚖️ Legal Document Explainer

### Use Case Overview
Help users understand legal documents and concepts in plain language.

### Sample Interactions

**User**: "Can you explain this non-disclosure agreement clause: 'The receiving party agrees to hold and maintain the Confidential Information in strict confidence for a period of five (5) years from the date of disclosure'?"

**Legal Bot**: "This NDA clause means:

**📝 What it says in plain English:**
You (the receiving party) must keep any confidential information completely secret for exactly 5 years from when you first received it.

**🔐 Your obligations:**
- Don't share the information with anyone
- Don't use it for your own benefit
- Protect it like you would your most sensitive personal information
- This applies to all confidential info, not just written documents

**⏰ Time period:**
- Starts counting from when you first receive each piece of information
- Different documents may have different 5-year periods
- After 5 years, restrictions typically end (unless extended)

**💼 Business context:**
This is a standard protection period. Some NDAs have shorter terms (2-3 years) or longer (10+ years), depending on the industry and type of information.

**⚠️ Important notes:**
- Violating this could result in legal action
- Some information may remain confidential even after 5 years if it's trade secrets
- There are usually exceptions for publicly available information

**🔍 Red flags to watch for:**
- Unreasonably long periods (over 10 years)
- Vague definitions of "confidential"
- No exceptions for publicly available info

⚖️ **Legal Disclaimer:** This explanation is for educational purposes only. For legal advice specific to your situation, please consult with a qualified attorney."

---

**User**: "What's the difference between 'liability' and 'damages' in a contract?"

**Legal Bot**: "Great question! These terms are related but distinct:

## 🎯 **LIABILITY**
**Definition:** Legal responsibility for something that goes wrong

**Think of it as:** "Who's to blame and responsible for fixing it?"

**Examples:**
- If you breach a contract, you have liability
- If your product injures someone, you may have liability
- If you don't deliver services as promised, you have liability

## 💰 **DAMAGES**
**Definition:** The actual money or compensation owed as a result of that liability

**Think of it as:** "How much money do you have to pay?"

**Types of damages:**
- **Actual damages:** Real losses (lost profits, repair costs)
- **Punitive damages:** Punishment for bad behavior
- **Liquidated damages:** Pre-agreed amounts in the contract

## 🔗 **How they work together:**
1. Something goes wrong (breach, injury, etc.)
2. Court determines **LIABILITY** (who's responsible)
3. Court calculates **DAMAGES** (how much they owe)

## 📊 **Example scenario:**
- **Situation:** You hire a contractor who damages your roof
- **Liability:** Contractor is liable for the damage
- **Damages:** Contractor owes $5,000 to repair the roof

## ⚖️ **In contracts:**
- **Liability clauses** say who's responsible for what
- **Damages clauses** limit or specify how much can be claimed

**Key takeaway:** Liability = responsibility, Damages = money owed

⚖️ **Legal Disclaimer:** This is general information only. Laws vary by jurisdiction. Consult an attorney for specific legal advice."

---

## 4. 💰 Financial Report Summarizer

### Use Case Overview
Analyze and explain financial reports, budgets, and key metrics in simple terms.

### Sample Interactions

**User**: "Our Q3 revenue was $2.5M, up 15% from Q2 but down 5% from Q3 last year. Operating expenses were $1.8M. Can you analyze this?"

**Financial Bot**: "Here's your Q3 financial analysis:

## 📊 **Revenue Performance**

**Quarterly Growth:** ✅ Strong momentum
- Q3: $2.5M (+15% from Q2)
- Indicates accelerating business growth
- Quarterly improvement is a positive trend

**Year-over-Year:** ⚠️ Slight decline  
- Down 5% vs Q3 last year ($2.63M implied)
- Could indicate market challenges or seasonal factors
- Need to investigate root causes

## 💸 **Profitability Analysis**

**Operating Metrics:**
- Revenue: $2.5M
- Operating Expenses: $1.8M
- **Operating Profit: $700K (28% margin)**

**Margin Analysis:**
- 28% operating margin is generally healthy
- Expense ratio: 72% of revenue
- Industry benchmarks vary, but 20-30% margins are typically good

## 🎯 **Key Insights**

**Positive indicators:**
- Strong quarter-over-quarter growth (15%)
- Healthy profit margins (28%)
- Positive operating cash generation

**Areas of concern:**
- Year-over-year decline (-5%)
- Need expense efficiency analysis
- Revenue growth sustainability

## 📈 **Recommendations**

1. **Investigate YoY decline:**
   - Market conditions vs. competitive issues
   - Seasonal business patterns
   - Customer retention analysis

2. **Expense optimization:**
   - Review $1.8M operating expenses
   - Identify variable vs. fixed costs
   - Look for efficiency opportunities

3. **Growth strategy:**
   - Build on Q2-Q3 momentum
   - Invest in areas driving recent growth
   - Set Q4 targets based on trends

**Bottom line:** Solid operational performance with mixed growth signals requiring deeper analysis."

### Advanced Financial Analysis
```python
# Financial ratio calculations
def calculate_financial_ratios(revenue, expenses, assets, liabilities):
    return {
        'profit_margin': (revenue - expenses) / revenue * 100,
        'operating_ratio': expenses / revenue * 100,
        'debt_to_equity': liabilities / (assets - liabilities),
        'revenue_growth': ((current_revenue - previous_revenue) / previous_revenue) * 100
    }

# Trend analysis
def analyze_trends(quarterly_data):
    trends = {}
    for metric in ['revenue', 'expenses', 'profit']:
        values = [quarter[metric] for quarter in quarterly_data[-4:]]
        trends[metric] = 'increasing' if values[-1] > values[0] else 'decreasing'
    return trends
```

---

## 5. 📄 Resume Optimizer

### Use Case Overview
Help job seekers improve their resumes with industry-specific advice.

**User**: "I'm applying for a software engineering role. Here's my experience: 'Worked on various programming projects using different technologies.' How can I improve this?"

**Career Bot**: "Your experience description needs significant improvement! Here's how to make it compelling:

## ❌ **Current version problems:**
- Too vague ('various projects', 'different technologies')
- No quantifiable results
- No specific technologies mentioned
- Doesn't demonstrate impact

## ✅ **Improved versions:**

**Option 1 - Full-stack focus:**
'Developed 3 full-stack web applications using React, Node.js, and PostgreSQL, serving 500+ daily active users and reducing manual processes by 40%'

**Option 2 - Backend focus:**
'Built scalable REST APIs using Python/Django and AWS, handling 10K+ requests/day with 99.9% uptime and reducing response times by 60%'

**Option 3 - Project variety:**
'Led development of 5 software projects including e-commerce platform (React/Redux), data analytics dashboard (Python/Pandas), and mobile app (React Native), resulting in $50K cost savings'

## 🎯 **Key improvements made:**

1. **Specific numbers:** 3 applications, 500+ users, 40% reduction
2. **Technology stack:** React, Node.js, PostgreSQL, Python, Django, AWS
3. **Business impact:** Cost savings, efficiency gains, user metrics
4. **Action verbs:** Developed, Built, Led (instead of 'Worked on')
5. **Quantifiable results:** Response times, uptime, user counts

## 💡 **Resume optimization tips:**

**Use the STAR method:**
- **S**ituation: What was the context?
- **T**ask: What did you need to accomplish?
- **A**ction: What specific actions did you take?
- **R**esult: What was the measurable outcome?

**Technical roles should include:**
- Specific programming languages and frameworks
- Architecture patterns (microservices, MVC, etc.)
- Deployment/DevOps tools (Docker, Kubernetes, CI/CD)
- Database technologies
- Cloud platforms (AWS, Azure, GCP)
- Performance metrics and improvements

**Power words for tech resumes:**
- Architected, Engineered, Optimized, Scaled
- Automated, Integrated, Deployed, Refactored
- Collaborated, Mentored, Led, Delivered

Would you like me to help optimize other sections of your resume?"

---

## 6. 🌍 Multi-lingual Translator with Context

### Use Case Overview
Combine AWS Bedrock with AWS Translate for context-aware translations.

**User**: "Translate this business email to Spanish: 'Following our discussion yesterday, I wanted to follow up on the quarterly projections. Could you please send me the updated forecasts by EOD Friday?'"

**Translation Bot**: "Here's the professional Spanish translation with context:

## 🇪🇸 **Spanish Translation:**

**Formal business version:**
'Siguiendo nuestra conversación de ayer, quería hacer seguimiento sobre las proyecciones trimestrales. ¿Podrías enviarme las previsiones actualizadas antes del cierre del día viernes?'

## 🎯 **Translation Notes:**

**Cultural adaptations made:**
- 'Following our discussion' → 'Siguiendo nuestra conversación' (more natural in Spanish)
- 'Follow up on' → 'hacer seguimiento sobre' (business context)
- 'EOD' → 'cierre del día' (End of Day explained in Spanish)

**Tone maintained:**
- Professional but friendly
- Polite request format with '¿Podrías...?'
- Maintains urgency without being demanding

## 🌎 **Regional Variations:**

**Mexico/Central America:**
'Después de nuestra plática de ayer, quería dar seguimiento a las proyecciones trimestrales...'

**Argentina/Southern Cone:**
'Luego de nuestra charla de ayer, quería hacer un seguimiento de las proyecciones trimestrales...'

**Spain:**
'Tras nuestra conversación de ayer, quería hacer seguimiento de las previsiones trimestrales...'

## 💼 **Business Spanish tips:**
- Always use 'usted' form in initial business communications
- 'Saludos cordiales' = Best regards
- 'Quedo a la espera' = Looking forward to hearing from you

Would you like me to adapt this for a specific Spanish-speaking region or adjust the formality level?"

### Implementation with AWS Translate
```python
# Enhanced translation with context
async def translate_with_context(text, target_language, context_type='business'):
    # First, get base translation from AWS Translate
    translate_client = boto3.client('translate')
    
    base_translation = translate_client.translate_text(
        Text=text,
        SourceLanguageCode='en',
        TargetLanguageCode=target_language
    )
    
    # Then enhance with Bedrock for cultural context
    enhancement_prompt = f"""
    Improve this {target_language} translation for {context_type} context:
    
    Original English: {text}
    Base translation: {base_translation['TranslatedText']}
    
    Provide:
    1. Culturally appropriate version
    2. Regional variations if relevant
    3. Tone/formality adjustments
    4. Cultural notes
    """
    
    enhanced_response = invoke_bedrock_model(
        'anthropic.claude-3-sonnet-20240229-v1:0',
        enhancement_prompt
    )
    
    return enhanced_response
```

---

## 🚀 Quick Deployment for Each Use Case

Each use case can be quickly configured by updating the domain prompts in the Lambda function:

```python
# Update in lambda/bedrock_handler.py
DOMAIN_PROMPTS = {
    'hr': """You are an HR assistant for a technology company. Help with employee policies, 
    benefits, leave requests, and workplace guidelines. Be professional, empathetic, and always 
    reference the employee handbook. Include specific steps and timelines when possible.""",
    
    'medical': """You are a medical triage assistant. Provide general health information and 
    guidance. ALWAYS emphasize consulting healthcare professionals for serious concerns. 
    Include clear disclaimers. Use emergency warning symbols for urgent situations.""",
    
    'legal': """You are a legal document assistant. Explain legal concepts and documents in 
    plain language. Always include disclaimers about consulting qualified attorneys. 
    Use examples and analogies to clarify complex terms.""",
    
    'finance': """You are a financial analysis assistant. Help with financial reports, 
    budgeting, and basic financial concepts. Use specific numbers and ratios. 
    Include actionable recommendations. Do not provide investment advice.""",
    
    'career': """You are a career development assistant. Help with resumes, job applications, 
    and career advice. Provide specific, actionable feedback with examples. 
    Use industry best practices and current hiring trends.""",
    
    'translation': """You are a translation assistant with cultural expertise. Provide 
    accurate translations with cultural context. Include regional variations and 
    cultural notes. Maintain appropriate tone and formality level."""
}
```

This completes your comprehensive AWS Bedrock GenAI chatbot with multiple specialized use cases!
