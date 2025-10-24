/**
 * Retry Helper
 * Implements exponential backoff retry logic with jitter
 */

/**
 * Retry a function with exponential backoff
 * @param fn - Async function to retry
 * @param maxAttempts - Maximum number of retry attempts (default: 3)
 * @param initialDelay - Initial delay in milliseconds (default: 1000)
 * @param maxDelay - Maximum delay in milliseconds (default: 8000)
 * @returns Promise resolving to function result
 */
export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxAttempts: number = 3,
  initialDelay: number = 1000,
  maxDelay: number = 8000
): Promise<T> {
  let lastError: Error;
  
  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      
      // Don't retry on the last attempt
      if (attempt === maxAttempts - 1) {
        break;
      }
      
      // Calculate delay with exponential backoff: initialDelay * (2 ^ attempt)
      const baseDelay = Math.min(initialDelay * Math.pow(2, attempt), maxDelay);
      
      // Add jitter (±20%) to prevent thundering herd
      const jitter = baseDelay * 0.2 * (Math.random() * 2 - 1);
      const delay = Math.round(baseDelay + jitter);
      
      console.log(`[RetryHelper] Attempt ${attempt + 1}/${maxAttempts} failed. Retrying in ${delay}ms...`);
      console.log(`[RetryHelper] Error: ${error instanceof Error ? error.message : String(error)}`);
      
      // Wait before retrying
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
  
  // All retries exhausted, throw the last error
  throw lastError!;
}

/**
 * Check if an error is retryable
 * @param error - Error to check
 * @returns True if error should trigger retry
 */
export function isRetryableError(error: any): boolean {
  // Network errors
  if (error.code === 'ETIMEDOUT' || error.code === 'ECONNRESET' || error.code === 'ENOTFOUND') {
    return true;
  }
  
  // Rate limit errors (429)
  if (error.status === 429 || error.statusCode === 429) {
    return true;
  }
  
  // Server errors (500-599)
  if (error.status >= 500 || error.statusCode >= 500) {
    return true;
  }
  
  return false;
}

