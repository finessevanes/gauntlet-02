/**
 * AI Configuration
 * Contains settings for OpenAI and Pinecone integrations
 */

export const aiConfig = {
  openai: {
    // Embedding model settings
    embeddingModel: 'text-embedding-3-small',
    dimensions: 1536,
    
    // Chat model settings
    chatModel: 'gpt-4',
    maxTokens: 500, // Max tokens for AI response
    temperature: 0.7, // Response creativity (0-2)
    
    timeout: 30000 // 30 seconds
  },
  pinecone: {
    indexName: 'coachai',
    environment: 'gcp-us-central1-4a9f', // Serverless mode
    metric: 'cosine',
    dimensions: 1536,
    timeout: 10000 // 10 seconds
  },
  retry: {
    maxAttempts: 3,
    initialDelay: 1000, // 1 second
    maxDelay: 8000 // 8 seconds
  },
  chat: {
    conversationContextLimit: 10, // Number of recent messages to include for context
    messageMaxLength: 4000 // Max characters in a user message
  }
};

