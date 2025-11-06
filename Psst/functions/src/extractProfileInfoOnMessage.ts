/**
 * Profile Extraction Cloud Function
 * Automatically extracts client profile information from messages
 * PR #007: Contextual Intelligence (Auto Client Profiles)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { extractProfileInfo, ProfileItem, findDuplicateItem } from './services/profileExtractionService';
import { openaiApiKey } from './config/secrets';

/**
 * Triggered when a new message is created in Firestore
 * Extracts profile information and updates client profile
 */
export const extractProfileInfoOnMessage = functions
  .runWith({
    secrets: [openaiApiKey],
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    try {
      console.log('[ProfileExtraction] New message created:', context.params.messageId);

      const messageData = snapshot.data();
      const messageId = context.params.messageId;
      const chatId = context.params.chatId;
      const senderId = messageData.senderID;
      const messageText = messageData.text;

      // Validate required fields
      if (!chatId || !senderId || !messageText) {
        console.log('[ProfileExtraction] Missing required message fields, skipping');
        return null;
      }

      // Get chat members to determine client and trainer
      const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        console.error('[ProfileExtraction] Chat not found:', chatId);
        return null;
      }

      const chatData = chatDoc.data();
      const members = chatData?.members || [];

      if (members.length !== 2) {
        // Only extract from 1-on-1 chats for now (skip group chats)
        console.log('[ProfileExtraction] Skipping group chat or invalid member count');
        return null;
      }

      // Get sender's user profile to check their role (PR #6.5)
      const senderDoc = await admin.firestore().collection('users').doc(senderId).get();

      if (!senderDoc.exists) {
        console.log('[ProfileExtraction] Sender user document not found');
        return null;
      }

      const senderData = senderDoc.data();
      const senderRole = senderData?.role;

      // Only extract from CLIENT messages (skip trainer messages)
      if (senderRole !== 'client') {
        console.log('[ProfileExtraction] Skipping non-client message (sender role:', senderRole, ')');
        return null;
      }

      // Client is the sender, trainer is the other member
      const clientId = senderId;
      const trainerId = members.find((id: string) => id !== senderId);

      if (!trainerId) {
        console.log('[ProfileExtraction] Could not determine trainer ID');
        return null;
      }

      console.log(`[ProfileExtraction] Extracting profile info for client: ${clientId}`);

      // Extract profile information using OpenAI
      const extractedItems = await extractProfileInfo(
        messageText,
        messageId,
        chatId,
        openaiApiKey.value()
      );

      if (!extractedItems || extractedItems.length === 0) {
        console.log('[ProfileExtraction] No profile information extracted');
        return null;
      }

      console.log(`[ProfileExtraction] Extracted ${extractedItems.length} items`);

      // Fetch or create client profile
      const profileRef = admin.firestore().collection('clientProfiles').doc(clientId);
      const profileDoc = await profileRef.get();

      let profile: any;

      if (!profileDoc.exists) {
        // Create new profile
        profile = {
          clientId: clientId,
          trainerId: trainerId,
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
          injuries: [],
          goals: [],
          equipment: [],
          preferences: [],
          travel: [],
          stressFactors: [],
          totalItems: 0,
          lastReviewedAt: null
        };
        console.log('[ProfileExtraction] Creating new profile for client');
      } else {
        profile = profileDoc.data();
        console.log('[ProfileExtraction] Updating existing profile');
      }

      // Add new items to profile with duplicate detection
      let addedCount = 0;
      let updatedCount = 0;

      for (const newItem of extractedItems) {
        const category = newItem.category;
        const existingItems: ProfileItem[] = profile[category] || [];

        // Check for duplicates
        const duplicateItem = findDuplicateItem(newItem, existingItems);

        if (duplicateItem) {
          // Update timestamp of existing item (most recent mention)
          console.log(`[ProfileExtraction] Duplicate found, updating timestamp: ${newItem.text}`);

          const updatedItems = existingItems.map(item =>
            item.id === duplicateItem.id
              ? { ...item, timestamp: admin.firestore.Timestamp.now() }
              : item
          );

          profile[category] = updatedItems;
          updatedCount++;
        } else {
          // Add new item
          console.log(`[ProfileExtraction] Adding new item: ${newItem.text} [${category}]`);
          profile[category] = [...existingItems, newItem];
          addedCount++;
        }
      }

      // Update metadata
      profile.updatedAt = admin.firestore.Timestamp.now();
      profile.totalItems =
        (profile.injuries?.length || 0) +
        (profile.goals?.length || 0) +
        (profile.equipment?.length || 0) +
        (profile.preferences?.length || 0) +
        (profile.travel?.length || 0) +
        (profile.stressFactors?.length || 0);

      // Save profile to Firestore
      await profileRef.set(profile, { merge: true });

      console.log(`[ProfileExtraction] ✅ Profile updated: ${addedCount} added, ${updatedCount} updated`);
      console.log(`[ProfileExtraction] Total items in profile: ${profile.totalItems}`);

      return null;

    } catch (error: any) {
      console.error('[ProfileExtraction] Error in extractProfileInfoOnMessage:', error);
      console.error('[ProfileExtraction] Error details:', error.message);
      // Don't throw - extraction failure shouldn't break message send
      return null;
    }
  });
