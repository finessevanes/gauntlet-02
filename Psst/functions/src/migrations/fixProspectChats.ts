/**
 * Migration Script: Fix Prospect IDs in Chat Members
 *
 * This script finds all chats that have prospect IDs in their members array
 * and replaces them with the real client user IDs.
 *
 * Run this once to fix existing data after PR-009 implementation.
 *
 * Usage:
 * 1. Deploy: firebase deploy --only functions:fixProspectChats
 * 2. Call via HTTP or Firebase Console
 */

import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

interface ProspectData {
  prospectId: string;
  convertedToClientId?: string;
  displayName: string;
}

interface ChatData {
  members: string[];
  [key: string]: any;
}

/**
 * Fixes all chats that contain prospect IDs by replacing them with real client IDs
 * This is a one-time migration to fix data after prospect upgrades
 */
export const fixProspectChats = functions.https.onRequest(async (req, res) => {
  const db = admin.firestore();

  try {
    console.log("🔍 Starting prospect chat fix migration...");

    // Step 1: Find all converted prospects (prospects with convertedToClientId set)
    const contactsSnapshot = await db.collection("contacts").get();

    let totalProspectsFound = 0;
    let totalChatsUpdated = 0;
    const prospectMappings: Map<string, string> = new Map(); // prospectId -> clientId

    // Collect all prospect -> client mappings
    for (const contactDoc of contactsSnapshot.docs) {
      const prospectsSnapshot = await contactDoc.ref
        .collection("prospects")
        .where("convertedToClientId", "!=", null)
        .get();

      for (const prospectDoc of prospectsSnapshot.docs) {
        const prospectData = prospectDoc.data() as ProspectData;

        if (prospectData.convertedToClientId) {
          prospectMappings.set(prospectDoc.id, prospectData.convertedToClientId);
          totalProspectsFound++;

          console.log(
            `📋 Found converted prospect: ${prospectData.displayName} ` +
            `(${prospectDoc.id} -> ${prospectData.convertedToClientId})`
          );
        }
      }
    }

    console.log(`\n✅ Found ${totalProspectsFound} converted prospects`);

    if (totalProspectsFound === 0) {
      return res.status(200).json({
        success: true,
        message: "No converted prospects found. Nothing to fix.",
        totalProspectsFound: 0,
        totalChatsUpdated: 0,
      });
    }

    // Step 2: Find and update chats with prospect IDs
    const chatsSnapshot = await db.collection("chats").get();

    for (const chatDoc of chatsSnapshot.docs) {
      const chatData = chatDoc.data() as ChatData;
      const members = chatData.members || [];

      let needsUpdate = false;
      const updatedMembers = members.map((memberId) => {
        // Check if this member ID is a prospect ID that was converted
        if (prospectMappings.has(memberId)) {
          const clientId = prospectMappings.get(memberId)!;
          console.log(
            `🔄 Chat ${chatDoc.id}: Replacing prospect ${memberId} with client ${clientId}`
          );
          needsUpdate = true;
          return clientId;
        }
        return memberId;
      });

      // Update the chat if needed
      if (needsUpdate) {
        await chatDoc.ref.update({
          members: updatedMembers,
        });
        totalChatsUpdated++;

        console.log(
          `✅ Updated chat ${chatDoc.id}: [${members.join(", ")}] -> [${updatedMembers.join(", ")}]`
        );
      }
    }

    console.log(`\n🎉 Migration complete!`);
    console.log(`   - Converted prospects found: ${totalProspectsFound}`);
    console.log(`   - Chats updated: ${totalChatsUpdated}`);

    return res.status(200).json({
      success: true,
      message: "Migration completed successfully",
      totalProspectsFound,
      totalChatsUpdated,
    });

  } catch (error) {
    console.error("❌ Migration failed:", error);

    return res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
});
