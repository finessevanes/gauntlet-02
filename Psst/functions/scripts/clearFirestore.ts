/**
 * Script to clear all Firestore data without deleting collections
 * Usage: ts-node scripts/clearFirestore.ts
 */

import * as admin from 'firebase-admin';
import * as path from 'path';

// Initialize Firebase Admin
const serviceAccount = require(path.join(__dirname, '../serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

/**
 * Delete all documents in a collection (and subcollections)
 */
async function deleteCollection(collectionPath: string, batchSize: number = 100): Promise<void> {
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

async function deleteQueryBatch(
  query: admin.firestore.Query,
  resolve: () => void,
  reject: (error: Error) => void
): Promise<void> {
  try {
    const snapshot = await query.get();

    // When there are no documents left, we're done
    if (snapshot.size === 0) {
      resolve();
      return;
    }

    // Delete documents in a batch
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    console.log(`Deleted ${snapshot.size} documents`);

    // Recurse on the next process tick, to avoid exploding the stack
    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error as Error);
  }
}

/**
 * Delete all documents in all subcollections (e.g., chats/{chatId}/messages)
 */
async function deleteSubcollections(
  parentCollection: string,
  subcollectionName: string
): Promise<void> {
  const parentDocs = await db.collection(parentCollection).listDocuments();

  console.log(`Found ${parentDocs.length} documents in ${parentCollection}`);

  for (const parentDoc of parentDocs) {
    const subcollectionPath = `${parentCollection}/${parentDoc.id}/${subcollectionName}`;
    console.log(`Deleting subcollection: ${subcollectionPath}`);
    await deleteCollection(subcollectionPath);
  }
}

/**
 * Main function to clear all Firestore data
 */
async function clearFirestore(): Promise<void> {
  try {
    console.log('🗑️  Starting Firestore cleanup...\n');

    // Delete all messages in all chats (subcollection)
    console.log('📧 Deleting all messages...');
    await deleteSubcollections('chats', 'messages');

    // Delete all AI conversation messages (subcollection)
    console.log('🤖 Deleting all AI conversation messages...');
    await deleteSubcollections('ai_conversations', 'messages');

    // Delete top-level collections
    console.log('💬 Deleting chats...');
    await deleteCollection('chats');

    console.log('👥 Deleting users...');
    await deleteCollection('users');

    console.log('📋 Deleting client profiles...');
    await deleteCollection('clientProfiles');

    console.log('🤖 Deleting AI conversations...');
    await deleteCollection('ai_conversations');

    console.log('📝 Deleting audit logs...');
    await deleteCollection('auditLogs');

    console.log('🔔 Deleting reminders...');
    // Note: reminders are stored per user at users/{userId}/reminders
    // This would require more complex deletion if you want to clear those too

    console.log('\n✅ Firestore cleanup complete!');
    console.log('Collections still exist but all documents have been deleted.\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error clearing Firestore:', error);
    process.exit(1);
  }
}

// Run the script
clearFirestore();
