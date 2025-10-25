/**
 * executeFunctionCall Cloud Function
 *
 * Handles execution of AI function calls after user confirmation.
 * This function is called by the iOS app after the user confirms an action.
 *
 * Validates parameters, executes the function, and logs to audit trail.
 * Version: 1.0.1 (Force redeploy)
 */

import * as functions from 'firebase-functions';
import { executeFunctionCall as executeFunction } from './services/functionExecutionService';
import { logFunctionCall, updateAuditLog } from './services/auditLogService';
import { openaiApiKey, pineconeApiKey } from './config/secrets';

/**
 * Request structure for function execution
 */
interface ExecuteFunctionRequest {
  functionName: string;
  parameters: Record<string, any>;
  conversationId?: string;
}

/**
 * Response structure for function execution
 */
interface ExecuteFunctionResponse {
  success: boolean;
  actionId?: string;
  result?: string;
  data?: any;
  error?: string;
}

/**
 * Callable Cloud Function for executing AI functions
 *
 * @param data - Function name and parameters
 * @param context - Firebase auth context
 * @returns Execution result
 */
export const executeFunctionCallFunction = functions
  .runWith({
    secrets: [openaiApiKey, pineconeApiKey],
    timeoutSeconds: 120,
    memory: '256MB'
  })
  .https.onCall(
  async (data: ExecuteFunctionRequest, context): Promise<ExecuteFunctionResponse> => {
    // Get secret values
    const openaiKey = openaiApiKey.value();
    const pineconeKey = pineconeApiKey.value();
    try {
      // ========================================
      // 1. AUTHENTICATION
      // ========================================

      if (!context.auth) {
        console.warn('[executeFunctionCall] Unauthenticated request rejected');
        throw new functions.https.HttpsError(
          'unauthenticated',
          'You must be authenticated to execute functions'
        );
      }

      const trainerId = context.auth.uid;
      console.log(`[executeFunctionCall] Request from trainer: ${trainerId}`);

      // ========================================
      // 2. INPUT VALIDATION
      // ========================================

      const { functionName, parameters, conversationId } = data;

      if (!functionName || typeof functionName !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Function name must be provided'
        );
      }

      if (!parameters || typeof parameters !== 'object') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Parameters must be an object'
        );
      }

      const validFunctions = ['scheduleCall', 'setReminder', 'sendMessage', 'searchMessages'];
      if (!validFunctions.includes(functionName)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Unknown function: ${functionName}`
        );
      }

      console.log(`[executeFunctionCall] Executing: ${functionName}`);
      console.log(`[executeFunctionCall] Parameters:`, JSON.stringify(parameters));

      // ========================================
      // 3. CREATE AUDIT LOG (PENDING)
      // ========================================

      const actionId = await logFunctionCall(
        trainerId,
        functionName,
        parameters,
        'pending',
        undefined,
        conversationId
      );

      console.log(`[executeFunctionCall] Audit log created: ${actionId}`);

      // ========================================
      // 4. EXECUTE FUNCTION
      // ========================================

      let executionResult;

      try {
        executionResult = await executeFunction(functionName, trainerId, parameters, openaiKey, pineconeKey);

        console.log(`[executeFunctionCall] Execution result:`, executionResult);

      } catch (error: any) {
        console.error(`[executeFunctionCall] Execution error:`, error);

        // Log failure
        await updateAuditLog(actionId, 'failed', error.message);

        throw new functions.https.HttpsError(
          'internal',
          `Function execution failed: ${error.message}`
        );
      }

      // ========================================
      // 5. UPDATE AUDIT LOG
      // ========================================

      if (executionResult.success) {
        await updateAuditLog(actionId, 'executed', executionResult.message);

        console.log(`[executeFunctionCall] ✅ Function executed successfully`);

        return {
          success: true,
          actionId,
          result: executionResult.message,
          data: executionResult.data
        };
      } else {
        await updateAuditLog(actionId, 'failed', executionResult.error);

        console.log(`[executeFunctionCall] ❌ Function execution failed: ${executionResult.error}`);

        return {
          success: false,
          actionId,
          error: executionResult.error,
          data: executionResult.data  // Include data field (for SELECTION_REQUIRED)
        };
      }

    } catch (error: any) {
      console.error('[executeFunctionCall] Request failed:', error);

      // If error is already a Firebase HttpsError, re-throw it
      if (error.code && error.message) {
        throw error;
      }

      // Otherwise, wrap in a generic internal error
      throw new functions.https.HttpsError(
        'internal',
        `Unexpected error: ${error.message}`
      );
    }
  }
);
