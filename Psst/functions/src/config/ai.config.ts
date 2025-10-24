/**
 * AI Configuration
 * Contains settings for OpenAI and Pinecone integrations
 */

export const aiConfig = {
  openai: {
    model: 'text-embedding-3-small',
    dimensions: 1536,
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
  }
};

