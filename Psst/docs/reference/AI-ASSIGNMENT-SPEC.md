# AI Assignment Specification - Psst Messaging App

**Status:** Active Reference for Assignment Submission  
**Last Updated:** October 24, 2025

---

## Overview

This document maps the 5 required AI capabilities to the features being built in **Psst**, a messaging app for personal trainers. It explains what each requirement is, why it's needed, and which features depend on it.

**Our Approach:** Hybrid AI architecture combining a dedicated AI Assistant chat with contextual AI features embedded in conversations (long-press actions, proactive suggestions).

---

## User Personas

### Marcus - The Remote Worker Trainer
- Manages 30+ clients across 4 time zones
- Always on the go, feels "always on" anxiety
- Loses leads from delayed responses
- Struggles to track which clients have gone quiet

### Alex - The Adaptive Trainer
- Manages 20 clients with constantly changing contexts (injuries, travel, equipment)
- Does mental gymnastics tracking everyone's details
- Gives generic responses when they forget client context
- Wants to provide personalized coaching at scale

---

# THE 5 AI REQUIREMENTS EXPLAINED

## 1️⃣ **CONVERSATION HISTORY RETRIEVAL (RAG Pipeline)**

### What It Is
RAG (Retrieval Augmented Generation) allows the AI to search past conversations and use that context to answer questions or make suggestions.

### Why It's Needed
Without RAG, the AI can't remember what clients have said previously. Trainers would have to manually search through hundreds of messages to find relevant context.

### How It Works in Psst
1. Trainer asks: "What did Sarah say about her diet?"
2. AI searches Firestore for Sarah's past messages containing diet-related keywords
3. AI retrieves relevant messages and uses them to answer
4. Trainer gets: "Sarah said she's trying keto but struggling with meal prep (mentioned 3 days ago)"

### Which Psst Features Use This

| Feature | How RAG Is Used | Persona |
|---------|-----------------|---------|
| **AI Chat Assistant** | Semantic search across all conversations | Marcus, Alex |
| **Contextual Actions** | Surfaces past mentions when long-pressing messages | Alex |
| **Proactive Assistant** | Identifies clients who haven't messaged recently | Marcus |
| **Multi-Step Agent** | Recalls context from earlier in DM conversation | Marcus |

---

## 2️⃣ **USER PREFERENCE STORAGE**

### What It Is
Stores trainer-specific information (rates, programs, communication style, availability) so the AI can respond consistently in the trainer's voice.

### Why It's Needed
Without preferences, the AI would give generic responses. Trainers would have to repeat their rates, availability, and preferences every time they want the AI to respond on their behalf.

### How It Works in Psst
1. Trainer sets up profile: "My 1-on-1 sessions are $150/hour, group sessions $50/person, I prefer friendly/professional tone, unavailable Sundays"
2. Preferences stored in Firestore under trainer's user profile
3. When AI responds (YOLO mode or suggestions), it includes trainer's preferences in the context
4. AI responds in trainer's voice with accurate information

### Which Psst Features Use This

| Feature | How Preferences Are Used | Persona |
|---------|--------------------------|---------|
| **Multi-Step Agent** | Auto-responds to rate inquiries with trainer's actual rates | Marcus |
| **AI Tone Customization** | Responds in trainer's chosen style (professional/friendly/motivational) | Marcus, Alex |
| **YOLO Mode** | Handles common questions using trainer's voice and info | Marcus |
| **Proactive Assistant** | Suggests follow-ups based on trainer's scheduling preferences | Marcus, Alex |

---

## 3️⃣ **FUNCTION CALLING CAPABILITIES**

### What It Is
Allows the AI to execute actions (send messages, create reminders, search conversations) instead of just talking. The AI decides which function to call based on the user's request.

### Why It's Needed
Without function calling, the AI can only provide information—it can't actually do anything. Trainers would still have to manually send messages, create reminders, and book appointments.

### How It Works in Psst
1. Trainer asks: "Send John a check-in message"
2. AI determines it needs to use the `send_message` function
3. AI calls the function with parameters (recipient: John, message: personalized check-in)
4. Firebase Cloud Function executes the action (actually sends the message)
5. AI confirms: "Sent check-in to John: 'Hey John! How's the knee feeling this week?'"

### Which Psst Features Use This

| Feature | Functions Used | Persona |
|---------|----------------|---------|
| **Multi-Step Agent** | `send_message()`, `book_calendar_event()`, `flag_lead()` | Marcus |
| **Proactive Assistant** | `create_reminder()`, `send_follow_up()`, `get_inactive_clients()` | Marcus, Alex |
| **Contextual Actions** | `summarize_conversation()`, `set_reminder()`, `search_messages()` | Alex |
| **YOLO Mode** | `send_auto_response()`, `qualify_lead()` | Marcus |

---

## 4️⃣ **MEMORY/STATE MANAGEMENT**

### What It Is
Tracks conversation context across multiple messages so the AI remembers what was discussed earlier and can continue multi-step tasks.

### Why It's Needed
Without memory, the AI forgets what was said in previous messages. Multi-turn conversations (like qualifying a lead) would require the trainer to repeat information.

### How It Works in Psst
1. New lead asks: "What are your rates?"
2. AI responds with rates and asks: "What are you looking to achieve?"
3. Lead responds: "Lose 20 pounds"
4. AI remembers the conversation context and continues naturally
5. AI books intro call with full context about the lead's goal

Memory is stored in Firestore and includes:
- Current task being worked on
- Information collected so far
- Conversation history
- Client-specific context

### Which Psst Features Use This

| Feature | How Memory Is Used | Persona |
|---------|-------------------|---------|
| **Multi-Step Agent** | Remembers lead conversation across multiple messages | Marcus |
| **AI Chat Assistant** | Maintains conversation context with the trainer | Marcus, Alex |
| **Contextual Intelligence** | Builds long-term "second brain" profile for each client | Alex |
| **Proactive Assistant** | Remembers which suggestions were already made | Marcus, Alex |

---

## 5️⃣ **ERROR HANDLING AND RECOVERY**

### What It Is
Gracefully handles failures when the AI service is unavailable, requests fail, or users ask for impossible actions.

### Why It's Needed
AI services can fail due to API timeouts, rate limits, network issues, or invalid requests. Without error handling, the app would crash or show cryptic errors to trainers.

### How It Works in Psst
When errors occur, the app:
1. Detects the error type (timeout, rate limit, invalid request, etc.)
2. Logs the error for debugging
3. Shows user-friendly message explaining what went wrong
4. Provides fallback options or retry mechanisms

**Common Error Scenarios:**
- **AI service timeout:** "AI is taking too long. Try again in a moment."
- **Rate limit exceeded:** "Too many requests. Please wait 30 seconds."
- **Invalid request:** "I can't do that, but I can help you search conversations instead."
- **Function failure:** "Couldn't create reminder. Please try manually."

### Which Psst Features Use This

**All features require error handling:**
- Multi-Step Agent (lead qualification can fail mid-conversation)
- AI Chat Assistant (OpenAI API can timeout)
- Contextual Actions (function calls can fail)
- Proactive Assistant (Firebase queries can fail)
- YOLO Mode (auto-responses need fallback for failures)

---

# Requirements Summary

| Requirement | What It Does | Which Features Use It |
|-------------|--------------|----------------------|
| **RAG Pipeline** | Searches past conversations for context | AI Chat, Contextual Actions, Proactive Assistant, Multi-Step Agent |
| **User Preferences** | Stores trainer's rates, style, availability | Multi-Step Agent, YOLO Mode, AI Tone Customization |
| **Function Calling** | Executes actions (send, remind, schedule) | All active features (Multi-Step, Proactive, Contextual, YOLO) |
| **Memory/State** | Remembers conversation context across messages | Multi-Step Agent, AI Chat, Contextual Intelligence |
| **Error Handling** | Gracefully handles failures | All features (required safety net) |

---

# Psst AI Features Mapped to Personas

## Marcus's Features (Boundaries & Lead Management)

### Multi-Step Agent (YOLO Mode)
**Requirements:** User Preferences, Function Calling, Memory/State, RAG, Error Handling  
**What It Does:** Handles incoming leads automatically - answers rate inquiries, books intro calls, qualifies prospects in Marcus's voice while he sleeps.  
**Value:** Marcus closes more leads because AI responds instantly. No more lost opportunities from delayed responses.

### Proactive Assistant
**Requirements:** RAG Pipeline, Function Calling, Memory/State, Error Handling  
**What It Does:** Identifies clients who've gone quiet (14+ days no message) and suggests personalized follow-up messages.  
**Value:** Marcus prevents churn by staying proactive. AI flags at-risk clients before they silently cancel.

### AI Tone Customization
**Requirements:** User Preferences, Function Calling  
**What It Does:** Sets default tone (Professional/Friendly/Motivational) with per-client overrides.  
**Value:** Marcus's AI responses sound like him. Corporate clients get professional tone, casual clients get friendly.

---

## Alex's Features (Context & Personalization)

### AI Chat Assistant
**Requirements:** RAG Pipeline, Memory/State, Function Calling, Error Handling  
**What It Does:** Semantic search across all conversations. "What did Sarah say about her knee?" gets instant answers.  
**Value:** Alex's "second brain" - never forgets client details. No more mental gymnastics tracking 20 clients.

### Contextual Actions
**Requirements:** RAG Pipeline, Function Calling, Error Handling  
**What It Does:** Long-press any message → AI surfaces past mentions, summarizes conversation, suggests actions.  
**Value:** Alex provides personalized coaching at scale. Client mentions knee pain → AI shows injury history from 3 weeks ago.

### Contextual Intelligence (Client Profiles)
**Requirements:** RAG Pipeline, Memory/State, User Preferences  
**What It Does:** Builds long-term profile for each client (injuries, goals, equipment, preferences) automatically from conversations.  
**Value:** Alex gives personalized advice without reviewing notes. AI remembers "Mike prefers DB exercises, has shoulder injury, travels to Dallas monthly."

---

## Shared Features (Both Personas)

### Voice Interface
**Requirements:** All 5 requirements (layered on existing features)  
**What It Does:** Talk to AI instead of typing - hands-free operation while walking between sessions.  
**Value:** Both Marcus and Alex manage their business on the go without stopping to type.

---

# Assignment Submission Notes

**Demo 1 (Marcus - Lead Qualification):**  
Tests User Preferences, Function Calling, Memory/State, Error Handling via Multi-Step Agent handling a new lead inquiry.

**Demo 2 (Alex - Context Recall):**  
Tests RAG Pipeline, Memory/State, Function Calling via AI surfacing past client context and suggesting personalized response.

Both demos showcase multiple requirements working together in real-world scenarios trainers face daily.