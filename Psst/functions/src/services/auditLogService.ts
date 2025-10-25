/**
 * Audit Log Service
 *
 * Tracks all AI function calls for debugging, monitoring, and compliance.
 * Creates records in /aiActions collection with full execution details.
 */

import * as admin from 'firebase-admin';

/**
 * Status of an AI action
 */
export type ActionStatus = 'pending' | 'confirmed' | 'executed' | 'failed' | 'cancelled';

/**
 * Audit log entry for an AI action
 */
export interface AuditLogEntry {
  trainerId: string;
  functionName: string;
  parameters: Record<string, any>;
  status: ActionStatus;
  result?: string;
  createdAt: admin.firestore.FieldValue;
  executedAt?: admin.firestore.Timestamp;
  conversationId?: string;
}

/**
 * Log a function call to the audit trail
 *
 * Creates or updates an entry in /aiActions collection
 *
 * @param trainerId - ID of the trainer initiating the action
 * @param functionName - Name of the function being called
 * @param parameters - Parameters passed to the function
 * @param status - Current status of the action
 * @param result - Result message (success or error)
 * @param conversationId - Optional conversation context ID
 * @returns Document ID of the audit log entry
 */
export async function logFunctionCall(
  trainerId: string,
  functionName: string,
  parameters: Record<string, any>,
  status: ActionStatus,
  result?: string,
  conversationId?: string
): Promise<string> {
  try {
    const db = admin.firestore();
    const aiActionsRef = db.collection('aiActions');

    const logData: AuditLogEntry = {
      trainerId,
      functionName,
      parameters,
      status,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      conversationId
    };

    if (result) {
      logData.result = result;
    }

    if (status === 'executed' || status === 'failed') {
      logData.executedAt = admin.firestore.Timestamp.now();
    }

    const logDoc = await aiActionsRef.add(logData);

    console.log(`[auditLog] Function call logged: ${functionName} (${status}) - ${logDoc.id}`);

    return logDoc.id;
  } catch (error: any) {
    console.error('[logFunctionCall] Failed to log audit entry:', error);
    // Don't throw - audit logging failure shouldn't break the main function
    return '';
  }
}

/**
 * Update an existing audit log entry
 *
 * @param actionId - ID of the audit log document
 * @param status - Updated status
 * @param result - Result message
 */
export async function updateAuditLog(
  actionId: string,
  status: ActionStatus,
  result?: string
): Promise<void> {
  try {
    if (!actionId) {
      console.warn('[updateAuditLog] No actionId provided, skipping update');
      return;
    }

    const db = admin.firestore();
    const updateData: Partial<AuditLogEntry> = {
      status
    };

    if (result) {
      updateData.result = result;
    }

    if (status === 'executed' || status === 'failed') {
      updateData.executedAt = admin.firestore.Timestamp.now();
    }

    await db.collection('aiActions').doc(actionId).update(updateData);

    console.log(`[auditLog] Updated: ${actionId} - ${status}`);
  } catch (error: any) {
    console.error('[updateAuditLog] Failed to update audit log:', error);
    // Don't throw - audit logging failure shouldn't break the main function
  }
}

/**
 * Get audit log history for a trainer
 *
 * @param trainerId - ID of the trainer
 * @param limit - Maximum number of records to return
 * @returns Array of audit log entries
 */
export async function getAuditHistory(
  trainerId: string,
  limit: number = 50
): Promise<any[]> {
  try {
    const db = admin.firestore();
    const snapshot = await db
      .collection('aiActions')
      .where('trainerId', '==', trainerId)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error: any) {
    console.error('[getAuditHistory] Error:', error);
    return [];
  }
}
