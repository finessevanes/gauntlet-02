/**
 * Migration Script: Migrate Existing Chats to Trainer-Client Relationships
 * PR #009: Trainer-Client Relationship System
 *
 * This script migrates existing chat participants into the /contacts collection
 * so that existing chats remain accessible after relationship validation is enabled.
 *
 * Usage:
 *   firebase functions:call migrateExistingChats --data '{"dryRun": true}'
 *   firebase functions:call migrateExistingChats --data '{"dryRun": false}'
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

interface MigrationResult {
  success: boolean;
  trainersProcessed: number;
  clientsAdded: number;
  errors: string[];
  dryRun: boolean;
}

/**
 * Migrates existing chat participants to trainer-client relationships
 */
export const migrateExistingChats = functions.https.onCall(
  async (data, context): Promise<MigrationResult> => {
    const dryRun = data.dryRun === true;

    console.log(`[Migration] Starting migration (dryRun: ${dryRun})`);

    const result: MigrationResult = {
      success: true,
      trainersProcessed: 0,
      clientsAdded: 0,
      errors: [],
      dryRun,
    };

    try {
      // Step 1: Get all users with role = 'trainer'
      const usersSnapshot = await db.collection("users").get();

      const trainers = usersSnapshot.docs.filter((doc) => {
        const data = doc.data();
        return data.role === "trainer";
      });

      console.log(`[Migration] Found ${trainers.length} trainers`);

      // Step 2: Process each trainer
      for (const trainerDoc of trainers) {
        const trainerId = trainerDoc.id;
        const trainerData = trainerDoc.data();

        console.log(
          `[Migration] Processing trainer: ${trainerData.displayName} (${trainerId})`
        );

        try {
          // Get all chats where this trainer is a member
          const chatsSnapshot = await db
            .collection("chats")
            .where("members", "array-contains", trainerId)
            .get();

          console.log(
            `[Migration] Trainer ${trainerId} has ${chatsSnapshot.docs.length} chats`
          );

          // Extract unique participant IDs (exclude the trainer)
          const participantIds = new Set<string>();

          for (const chatDoc of chatsSnapshot.docs) {
            const chatData = chatDoc.data();
            const members = chatData.members as string[];

            // Add non-trainer members
            for (const memberId of members) {
              if (memberId !== trainerId) {
                participantIds.add(memberId);
              }
            }
          }

          console.log(
            `[Migration] Trainer ${trainerId} has ${participantIds.size} unique chat participants`
          );

          // For each participant, check if already in /contacts, if not, add them
          for (const clientId of participantIds) {
            try {
              // Get client user data
              const clientDoc = await db
                .collection("users")
                .doc(clientId)
                .get();

              if (!clientDoc.exists) {
                console.warn(
                  `[Migration] User ${clientId} not found, skipping`
                );
                continue;
              }

              const clientData = clientDoc.data()!;

              // Check if already exists in contacts
              const existingClientDoc = await db
                .collection("contacts")
                .doc(trainerId)
                .collection("clients")
                .doc(clientId)
                .get();

              if (existingClientDoc.exists) {
                console.log(
                  `[Migration] Client ${clientId} already exists for trainer ${trainerId}, skipping`
                );
                continue;
              }

              // Create client relationship
              const clientRelationship = {
                clientId,
                displayName: clientData.displayName || "Unknown User",
                email: clientData.email || "",
                addedAt: admin.firestore.FieldValue.serverTimestamp(),
                lastContactedAt: null,
              };

              if (!dryRun) {
                await db
                  .collection("contacts")
                  .doc(trainerId)
                  .collection("clients")
                  .doc(clientId)
                  .set(clientRelationship);

                console.log(
                  `[Migration] ✅ Added client ${clientData.displayName} (${clientId}) for trainer ${trainerId}`
                );
              } else {
                console.log(
                  `[Migration] [DRY RUN] Would add client ${clientData.displayName} (${clientId}) for trainer ${trainerId}`
                );
              }

              result.clientsAdded++;
            } catch (error) {
              const errorMsg = `Failed to process client ${clientId} for trainer ${trainerId}: ${error}`;
              console.error(`[Migration] ❌ ${errorMsg}`);
              result.errors.push(errorMsg);
            }
          }

          result.trainersProcessed++;
        } catch (error) {
          const errorMsg = `Failed to process trainer ${trainerId}: ${error}`;
          console.error(`[Migration] ❌ ${errorMsg}`);
          result.errors.push(errorMsg);
        }
      }

      console.log(
        `[Migration] Completed: ${result.trainersProcessed} trainers processed, ${result.clientsAdded} clients added`
      );
      console.log(`[Migration] Errors: ${result.errors.length}`);

      return result;
    } catch (error) {
      console.error(`[Migration] Fatal error: ${error}`);
      result.success = false;
      result.errors.push(`Fatal error: ${error}`);
      return result;
    }
  }
);
