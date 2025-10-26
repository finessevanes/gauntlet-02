# How AI Works in Psst - Explained Simply

**For:** Anyone who wants to understand Psst's AI features without technical jargon
**Last Updated:** October 25, 2025

---

## The Big Picture

Psst has **two different AI systems** that help personal trainers manage their clients:

1. **The AI Assistant** - A chatbot you talk to (like ChatGPT)
2. **Smart Message Actions** - Quick AI helpers you access by long-pressing messages

Think of it like this:
- **AI Assistant** = Your virtual admin assistant
- **Smart Message Actions** = Quick tools in your toolbox

---

## System 1: The AI Assistant (Chat Interface)

### What It Is
A dedicated chat screen where you talk to an AI assistant about your business. It's like having a personal assistant who knows all your clients.

### How You Use It
Just talk to it naturally:
- "Send Jake a check-in message"
- "Schedule a call with Sarah for tomorrow at 2pm"
- "What did Mike say about his shoulder pain?"
- "Remind me to follow up with Emily next week"

### What Makes It Smart: Function Calling

When you make a request, the AI:
1. **Understands** what you want
2. **Decides** which action to take
3. **Asks for confirmation** before doing anything
4. **Executes** the action (sends message, books call, etc.)

**Example:**

```
You: "Send Jake a motivational message about his progress"

AI: [Thinks: This needs the sendMessage function]
AI: "I'll send this to Jake:
     'Hey Jake! Amazing progress this week - keep crushing it!'"

[Popup appears asking you to confirm]

You: [Tap Confirm]

AI: [Actually sends the message to Jake]
Result: "✓ Message sent to Jake"
```

### The 4 Things AI Assistant Can Do

| Action | What It Does | Example |
|--------|--------------|---------|
| **sendMessage** | Sends a message to a client | "Send Mike a reminder about his session tomorrow" |
| **scheduleCall** | Books a calendar event | "Schedule a call with Sarah on Friday at 3pm" |
| **setReminder** | Creates a follow-up reminder | "Remind me to check in with Jake next Monday" |
| **searchMessages** | Finds past conversations | "What did Emily say about her diet last month?" |

### Key Feature: It Understands Context

The AI remembers your conversation:

```
You: "What are Jake's fitness goals?"
AI: "Jake wants to lose 20 pounds and build upper body strength"

You: "Send him a workout plan for that"
AI: [Knows "him" = Jake, "that" = weight loss + upper body]
AI: Generates personalized message with workout plan
```

---

## System 2: Smart Message Actions (Long-Press Menu)

### What It Is
Quick AI helpers you access by long-pressing any message in a conversation. No chatting required - just pick an action from a menu.

### How You Use It

**Step 1:** Long-press any message
**Step 2:** Pick an action from the menu
**Step 3:** AI does its thing instantly

### The 3 Quick Actions

#### 1. Summarize Conversation
**What it does:** Reads the entire conversation and gives you a quick summary

**When to use it:**
- You have 50+ messages with a client and need a quick recap
- New client sends a long story about their fitness history
- You forgot what you discussed with someone last week

**Example:**
```
[Long-press any message in Jake's chat]
[Tap "Summarize Conversation"]

AI shows:
━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY:
Jake wants to lose 20 lbs for his wedding in 3 months.
He has a knee injury from running but can do low-impact
cardio. Prefers morning workouts.

KEY POINTS:
• Goal: Lose 20 lbs by wedding (3 months)
• Injury: Left knee pain from running
• Preference: Morning sessions, low-impact cardio
• Equipment: Has dumbbells and resistance bands
━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 2. Surface Context
**What it does:** Finds related messages from the past

**When to use it:**
- Client mentions an old injury/issue
- You need to recall what they said about something
- Want to see patterns in their training history

**Example:**
```
Jake's new message: "My knee is bothering me again"

[Long-press this message]
[Tap "Surface Context"]

AI shows past related messages:
━━━━━━━━━━━━━━━━━━━━━━━━
RELATED CONVERSATIONS:

📅 2 weeks ago:
Jake: "Started running again, knee feels good!"

📅 1 month ago:
Jake: "Knee pain after the 5K run yesterday"

📅 2 months ago:
You: "Let's avoid running until your knee heals"
━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 3. Set Reminder
**What it does:** Creates a follow-up reminder based on the message

**When to use it:**
- Client mentions they'll update you next week
- You need to follow up about something specific
- Client asks a question you can't answer right now

**Example:**
```
Sarah's message: "I'll try the new diet plan and let you
know how it goes next week"

[Long-press this message]
[Tap "Set Reminder"]

AI suggests:
━━━━━━━━━━━━━━━━━━━━━━━━
REMINDER SUGGESTION:
"Follow up with Sarah about new diet plan results"

Due: Next Monday, 10:00 AM

[Edit] [Save]
━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## The Key Differences (Side by Side)

| Feature | AI Assistant | Smart Message Actions |
|---------|--------------|----------------------|
| **How you access** | Open AI chat screen, type request | Long-press any message |
| **Who decides what to do** | AI figures it out | You pick from menu |
| **Requires confirmation** | Yes (popup before action) | No (instant) |
| **Can take action** | Yes (sends messages, books calls) | Only creates suggestions |
| **Best for** | Complex tasks, multiple steps | Quick info about one message |

---

## Real-World Scenarios

### Scenario 1: New Lead Inquiry (AI Assistant)

**Situation:** You're asleep and a new lead messages you asking about rates.

```
Lead: "Hey, what are your personal training rates?"

[AI Assistant can respond automatically if you enable YOLO mode]

AI: [Reads your stored rates from preferences]
AI: [Crafts response in your tone]
AI: Sends: "Hi! My 1-on-1 sessions are $150/hour, or I
     offer a 4-session package for $550. What are your
     fitness goals?"

[You wake up to see AI already started the conversation]
```

### Scenario 2: Quick Context Check (Smart Actions)

**Situation:** Client mentions their shoulder, you need to remember what they said before.

```
Mike: "My shoulder feels weird after yesterday's workout"

[Long-press Mike's message]
[Tap "Surface Context"]

AI shows:
━━━━━━━━━━━━━━━━━━━━━━━━
📅 3 weeks ago:
Mike: "Had a rotator cuff injury last year"

📅 1 week ago:
You: "Let me know if you feel any shoulder pain"
━━━━━━━━━━━━━━━━━━━━━━━━

[Now you remember Mike has a history of shoulder issues]
```

### Scenario 3: Batch Follow-Ups (AI Assistant)

**Situation:** You want to check in with clients who've gone quiet.

```
You: "Which clients haven't messaged me in 2 weeks?"

AI: [Searches all conversations]
AI: "Found 5 clients who haven't messaged in 14+ days:
     - Jake (17 days)
     - Sarah (15 days)
     - Mike (21 days)
     - Emily (14 days)
     - David (19 days)"

You: "Send Jake a check-in message"

AI: "I'll send this to Jake:
     'Hey Jake! Just checking in - how's the training
     going? Haven't heard from you in a bit. Let me
     know if you need any adjustments to your program!'"

[Tap Confirm]
Result: Message sent ✓
```

---

## Behind The Scenes (Optional Technical Details)

### What Makes This Possible

1. **OpenAI GPT-4** - The brain that understands and generates text
2. **Function Calling** - How AI decides which action to take
3. **Vector Search (Pinecone)** - How AI finds related past messages using semantic similarity
4. **Firebase** - Stores all your conversations and client data
5. **Swift/iOS** - The app you use on your phone

### How Vector Database & Semantic RAG Work

**The Problem:** How does AI find relevant past messages when there are thousands of conversations?

Traditional keyword search would miss things like:
- You ask: "What did Jake say about his knee?"
- Jake actually said: "My left leg joint has been bothering me"
- Keyword search for "knee" would miss this!

**The Solution: Semantic RAG with Pinecone Vector Database**

#### Step 1: Every Message Becomes a Vector (1536 Numbers)

When any message is sent:
```
Jake's message: "My left leg joint has been bothering me"
    ↓
OpenAI text-embedding-3-small converts to vector
    ↓
[0.234, -0.891, 0.456, ..., 0.123] (1536 numbers)
    ↓
Stored in Pinecone vector database
```

**Why vectors?** Numbers capture the *meaning* of text, not just the words. "Knee pain" and "leg joint bothering me" have similar vector representations because they mean similar things.

#### Step 2: Semantic Search Finds Meaning, Not Just Words

When you ask a question:
```
Your query: "What did Jake say about his knee?"
    ↓
Convert query to vector: [0.245, -0.877, 0.441, ...]
    ↓
Pinecone searches for similar vectors using cosine similarity
    ↓
Finds Jake's message even though it says "leg joint" not "knee"!
    ↓
Returns relevant past messages ranked by similarity
```

#### Step 3: RAG (Retrieval Augmented Generation)

Now the AI has context to answer intelligently:
```
Your question: "What did Jake say about his knee?"
    ↓
Pinecone retrieves: "My left leg joint has been bothering me"
    ↓
AI reads retrieved context + understands the question
    ↓
AI responds: "Jake mentioned his left leg joint has been
bothering him. He didn't use the word 'knee' but was
referring to joint pain in that area."
```

#### The Architecture

**Pinecone Vector Database:**
- Index name: `coachai`
- Dimensions: 1536 (matches OpenAI embeddings)
- Similarity metric: Cosine similarity
- Infrastructure: Serverless (auto-scales)

**How Messages Flow:**
```
1. Message Sent (Firestore)
        ↓
2. Cloud Function Triggered
        ↓
3. OpenAI Creates Embedding (1536 numbers)
        ↓
4. Embedding Stored in Pinecone with metadata:
   - messageId
   - conversationId
   - timestamp
   - sender (trainer/client)
        ↓
5. Available for semantic search instantly
```

**When You Search:**
```
1. Your Query → Converted to vector
        ↓
2. Pinecone finds top 10 most similar vectors
        ↓
3. Returns matching messages with similarity scores
        ↓
4. AI reads messages + generates answer
        ↓
5. You get contextual response
```

#### Why This Matters

**Without Vector DB (keyword search):**
- "knee pain" only finds exact matches
- Misses: "leg hurts", "joint bothering me", "running injury"
- Limited to literal word matching

**With Vector DB (semantic search):**
- Understands *meaning* not just words
- Finds: knee, leg, joint, limb, running injury, discomfort
- Works across synonyms, related concepts, context
- Much smarter search!

#### Real Example

**Scenario:** Client mentions "shoulder discomfort"

**Keyword search would find:**
- Messages containing "shoulder" ✓
- Messages containing "discomfort" ✓

**Vector search also finds:**
- "rotator cuff pain" (related concept)
- "my arm hurts when lifting" (similar meaning)
- "upper body injury" (broader context)
- Previous discussions about shoulder exercises

This is why "Surface Context" feels so smart - it understands relationships between concepts!

### The Data Flow

**For AI Assistant (sendMessage example):**
```
Your request
    ↓
iOS app sends to Firebase
    ↓
Cloud Function calls OpenAI
    ↓
OpenAI decides: "Use sendMessage function"
    ↓
Confirmation popup shows
    ↓
You confirm
    ↓
Message saved to Firestore
    ↓
Client sees message in their app
```

**For Smart Actions (summarize example):**
```
You long-press message
    ↓
iOS app reads conversation from memory
    ↓
Sends messages to OpenAI directly
    ↓
OpenAI generates summary
    ↓
Summary displays instantly
```

---

## Privacy & Safety

### What AI Can Do
- ✅ Read your conversations (only yours)
- ✅ Send messages **after you confirm**
- ✅ Create calendar events and reminders
- ✅ Search past messages

### What AI Cannot Do
- ❌ Send messages without confirmation
- ❌ Access other trainers' data
- ❌ Delete conversations
- ❌ Share your data with third parties
- ❌ Do anything outside the 4 core functions

### Confirmation System
Every action that affects your clients requires confirmation:
- Sending messages → Popup with preview
- Scheduling calls → Shows date/time/client
- Setting reminders → Shows reminder text

Only "read-only" actions happen instantly:
- Searching messages
- Summarizing conversations
- Surfacing context

---

## FAQ

**Q: Does AI read all my messages?**
A: Only when you ask it to search or summarize. Otherwise, it only accesses what's needed for your specific request.

**Q: What if AI sends the wrong message?**
A: It can't. Every message shows a confirmation popup before sending. You always review and approve.

**Q: Can I turn off AI features?**
A: Yes. AI Assistant is opt-in. Smart Message Actions can be disabled in settings.

**Q: What if I have no internet?**
A: AI features require internet. The app shows an error if you're offline.

**Q: Does this cost extra?**
A: AI features are included in your subscription. No extra charges.

**Q: Is my data used to train OpenAI's models?**
A: No. We use OpenAI's API with data protection agreements that prevent training on user data.

---

## Quick Reference Card

| I Want To... | Use This | How |
|--------------|----------|-----|
| Send a message to a client | AI Assistant | "Send [name] a [message]" |
| See past mentions of a topic | AI Assistant | "What did [name] say about [topic]?" |
| Schedule a call | AI Assistant | "Schedule call with [name] on [date/time]" |
| Get reminded about something | AI Assistant | "Remind me to [task] on [date]" |
| Summarize a long conversation | Smart Actions | Long-press → Summarize |
| Find related old messages | Smart Actions | Long-press → Surface Context |
| Create reminder from message | Smart Actions | Long-press → Set Reminder |

---

## Tips for Getting the Most Out of AI

1. **Be specific with names:** "Send Jake" not "Send my client"
2. **Include dates/times:** "Tomorrow at 2pm" not "sometime this week"
3. **Review before confirming:** Always read AI-generated messages before sending
4. **Use Smart Actions for speed:** Long-press is faster than typing for quick tasks
5. **Set up your preferences:** AI responds better when it knows your rates, tone, schedule

---

## What's Coming Next

**Planned AI Features:**
- Voice interface (talk instead of type)
- Proactive suggestions (AI tells you who to follow up with)
- Auto-responses for common questions (YOLO mode)
- Client profile intelligence (AI builds automatic client profiles)

---

**Questions?** Check the full technical docs at `docs/architecture.md` or ask in the support channel.
