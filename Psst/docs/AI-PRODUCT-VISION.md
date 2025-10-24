# AI Features: Product Vision

**Status:** Active Reference  
**Last Updated:** October 23, 2025

---

## Executive Summary

**Psst AI** is a communication intelligence platform for personal trainers managing 15-30+ clients across messaging platforms.

**The Vision:** A voice-first AI assistant that acts as the trainer's "second brain" - remembering every client detail, responding in the trainer's voice, and proactively suggesting actions. Trainers reclaim 2+ hours daily while providing better, more personalized coaching.

**This Build (Phase 1-5):** Focus on coach communication AI. Client-side features (workout plans, progress tracking) deferred to Phase 6+.

---

## Scope

### ✅ In Scope (Phase 1-5)
- Text-based AI chat assistant (floating "robot" interface)
- Communication AI (semantic search, summarize, contextual actions)
- YOLO mode (automated responses with boundaries)
- Proactive suggestions (follow-ups, client check-ins)
- Voice interface (Phase 4-5, layered on text foundation)
- Function calling (schedule, remind, send messages)
- All features coach-facing only

### ❌ Out of Scope (Deferred to Phase 6+)
- Workout plan management/modifications
- Client-side workout plan tab
- Client-facing AI features
- Exercise library or plan templates
- Progress tracking dashboards
- AI nutrition coaching
- Revenue/business analytics

---

## The 3 Core Problems We're Solving

### Problem 1: Information Overload & Lost Context 🧠
**The Pain:** Trainers manage 30+ clients with hundreds of messages daily. Important details get buried - injury warnings, goals, preferences. Result: Generic advice, clients feel unheard.

**How AI Solves It:**
- **RAG Pipeline:** Semantic search across all conversations ("What did John say about his knee?" → instant answer)
- **Memory/State:** AI builds "second brain" for each client
- **Context Surfacing:** AI reminds trainer of relevant history before sessions

---

### Problem 2: No Boundaries & Repetitive Work ⏰
**The Pain:** Trainers feel "always on" - midnight texts, identical questions 20x/week. Can't scale without automation. Result: Burnout, lost leads, resentment.

**How AI Solves It:**
- **User Preferences:** Stores trainer's rates, programs, voice/style
- **Function Calling:** AI sends messages, books calls autonomously
- **YOLO Mode:** Auto-responds in trainer's voice (scheduled or on-demand)
- **Lead Qualification:** Handles "What are your rates?" instantly

---

### Problem 3: Client Retention & Proactive Follow-Up 📉
**The Pain:** Clients go quiet, trainers forget to check in. Result: 30-50% churn (preventable), silent cancellations, guilt.

**How AI Solves It:**
- **Memory/State:** Tracks engagement patterns per client
- **Function Calling:** Creates reminders, drafts follow-ups, sends proactively
- **RAG Pipeline:** Personalizes follow-ups based on past conversations
- **Churn Prediction:** AI flags at-risk clients early

---

## How the 5 AI Requirements Work Together

Every interaction uses multiple requirements working together:

**Example:** "Send John a check-in message"
1. **Memory/State:** Loads John's context (last message 14 days ago, mentioned travel)
2. **RAG:** Searches past conversations for personalization
3. **User Preferences:** Uses trainer's voice/style
4. **Function Calling:** Actually sends the message via Firebase
5. **Error Handling:** If send fails, queues for retry

---

## User Personas (Core Use Cases)

### Marcus - The Remote Worker Trainer
**Problems:** #2 (Boundaries), #3 (Retention)  
**Background:** 30+ clients, 4 time zones, always on the go  
**Pain:** "Always on" anxiety, loses leads from delayed responses, hard to track who's been quiet

**What AI Does:**
- YOLO mode handles overnight inquiries → Marcus wakes to qualified leads
- Proactive suggestions flag clients who've been quiet
- No guilt disconnecting - AI manages routine questions

**Marcus Says:**
> "It lets me turn off and feel good my business is still working. I'm closing MORE leads because AI responds instantly."

---

### Alex - The Adaptive Trainer
**Problems:** #1 (Information Overload), #3 (Retention)  
**Background:** 20 clients with constant life changes (injuries, travel, equipment)  
**Pain:** Mental gymnastics tracking everyone's contexts, lost details, generic responses

**What AI Does:**
- AI captures context automatically (travel, injuries, stress)
- Surfaces relevant history when Alex opens conversations
- No more mental spreadsheet of 20 clients' lives

**Alex Says:**
> "The AI is like having a second brain that never forgets."

---

## The End-State Experience

### Vision: A Day in the Life (After AI)

**Morning (6:00 AM):**  
YOLO mode handled 6/8 overnight inquiries. Two need personal attention - flagged.

**On-the-Go (10:00 AM):**  
Walking between sessions, coach asks AI: "What's my day look like?" AI reads appointments, flags: "John hasn't checked in for 2 weeks." Coach says "Send it" while making coffee.

**Client Message (2:00 PM):**  
Client mentions knee pain. Coach long-presses message → AI surfaces context: "Sarah mentioned knee issues 2 weeks ago during squats." Responds with informed empathy and modified workout plan.

**New Lead (4:00 PM):**  
DM: "What are your rates?" AI responds instantly, books intro call. Coach sees qualified lead - zero effort.

**Evening (8:00 PM):**  
Asks AI: "What did Marcus say about his diet last month?" Gets exact conversation. Uses for tomorrow's call.

**End of Day:**  
Total admin time: 15 minutes. Messages handled, leads qualified, clients feel heard. Evening free - no guilt.

---

## Core AI Features (What We're Building)

### 1. AI Chat Assistant
**What:** Dedicated "AI Assistant" chat (like messaging another person)  
**User Story:** "Ask 'What did John say about his knee?' and get instant answers from chat history"

### 2. Contextual AI Actions
**What:** Long-press messages → instant AI actions (summarize conversation, set reminder, surface context)  
**User Story:** "Long-press message about client's injury, AI surfaces past mentions of same issue and suggests follow-up actions"

### 3. Proactive Assistant
**What:** AI notices patterns, suggests actions automatically  
**User Story:** "AI notices John hasn't messaged in 2 weeks, suggests follow-up message"

### 4. Multi-Step Agent (Lead Qualification)
**What:** AI handles DM conversations, qualifies leads, books calls  
**User Story:** "AI answers rate inquiries and books intro calls while I sleep"

### 5. Voice Interface (Phase 4-5)
**What:** Speak to AI instead of typing (voice input → AI processes → voice output)  
**User Story:** "Talk to AI while walking between sessions, manage business hands-free"

### 6. AI Tone Customization (Phase 5)
**What:** Set default AI tone + per-client overrides  
**Presets:** Professional, Friendly, Motivational  
**User Story:** "Default 'Friendly' tone, but John gets 'Professional' (corporate client)"

---

## UI/UX Approach

### Hybrid Model (Both Dedicated Chat + Contextual Actions)

**Coach View:**
- **Floating AI button** (🤖) - always accessible
- Tap → Voice interface (primary), keyboard fallback (secondary)
- Within conversations: Quick actions (📊 Summary, 🔍 Search, ⚙️ YOLO Toggle)

**YOLO Mode:**
- Settings toggle: ON/OFF globally
- Schedule-based: "YOLO mode 6am-7am, 8pm-11pm"
- Per-conversation toggle
- Visual indicator when active

**Role Differentiation:**
- Settings: "I'm a Coach" / "I'm a Client"
- Changes navigation/features based on role

---

## Key Experience Principles

- ✅ **Invisible Intelligence:** AI works in background, trainer doesn't think about it
- ✅ **Trainer in Control:** AI suggests, trainer decides
- ✅ **Personal Touch Preserved:** AI sounds like the trainer, not a robot
- ✅ **Full Automation Option:** Can fully automate, but always allow human override
- ✅ **AI Learns from Human:** AI improves from trainer's edits and feedback

---

## Happy Path Demos (Integration Tests)

### Demo 1: Marcus - YOLO Mode Lead Qualification
**Tests:** User Preferences, Function Calling, Memory/State, Error Handling

1. New lead: "What are your rates?"
2. AI responds with rates from User Preferences
3. Lead: "What's your availability?"
4. AI checks calendar, suggests times (Function Calling)
5. Lead: "2pm tomorrow works"
6. AI books call, sends invite
7. Coach reviews later, confirms or edits

---

### Demo 2: Alex - Second Brain Context Recall
**Tests:** RAG Pipeline, Memory/State, Function Calling, User Preferences

1. Client: "Traveling to Dallas next week, hotel gym only"
2. Coach asks AI: "What did this client say about travel before?"
3. RAG searches → finds past conversations
4. AI: "Mike mentioned Dallas 3 weeks ago, liked DB workouts"
5. AI drafts suggested workout message
6. Coach reviews, edits if needed, sends
7. Client: "Perfect! You remembered 🙌"

---

## Assignment Requirements Coverage

| Requirement | Where Implemented | Demo Coverage |
|-------------|-------------------|---------------|
| **RAG Pipeline** | Phase 3 (Vector Search) | Demo 2: Semantic search |
| **User Preferences** | Phase 5 (Trainer settings) | Demo 1: AI knows rates/style |
| **Function Calling** | Phase 4 (Actions) | Demo 1: Books call |
| **Memory/State** | Phase 2-5 (Profiles) | Demo 2: Surfaces context |
| **Error Handling** | All Phases | All features have fallbacks |

---

## Open Questions

1. **Voice of the AI:**
   - Default tone set by coach (Professional/Friendly/Motivational)
   - Per-client overrides available
   - AI learns from coach's writing style over time

2. **Control vs Automation:**
   - YOLO ON: AI sends automatically
   - YOLO OFF: AI shows suggestions, waits for confirmation
   - Coach can give feedback (👍/👎) on responses

3. **Trust & Safety:**
   - Coach sets boundaries on what AI can/can't say
   - Disclaimer when signing up about AI limitations
   - Always include: "If it hurts, stop immediately and let me know"
   - Feedback loop: Coach rates responses to improve AI

---

## For Agents: Key Takeaways

**When Building PRDs:**
- Focus on ONE problem at a time
- Reference this doc for user personas and pain points
- Implementation details go in PRD, not here

**When Building Features:**
- Always consider how 5 requirements work together
- Coach control is paramount - AI suggests, coach decides
- Test against happy path demos

**When Designing UI:**
- Invisible intelligence - don't make users think about AI
- Voice-first, keyboard fallback
- Always show what AI is doing (transparency)

---

**Status:** ✅ Complete - Ready for agent reference  
**Next:** Use this vision to create detailed PRDs for each feature
