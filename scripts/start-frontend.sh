#!/bin/bash

echo "🚀 Starting AWS Bedrock Chatbot Frontend..."

# Kill any existing processes on port 3000
echo "🧹 Cleaning up port 3000..."
lsof -ti :3000 | xargs kill -9 2>/dev/null || echo "Port 3000 is already free"

# Kill any existing npm/react processes
pkill -f "react-scripts start" 2>/dev/null || true
pkill -f "npm start" 2>/dev/null || true

# Wait a moment for processes to close
sleep 2

# Start the React app
echo "🎨 Starting React development server on port 3000..."
cd frontend && npm start

echo "✅ Frontend should be available at: http://localhost:3000"
