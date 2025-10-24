# AI Tone Presets Reference

Quick reference for what each AI tone preset sounds like. Use this when creating User Preferences PRD (Phase 5).

---

## Professional

**Characteristics:** Formal, data-driven, minimal emojis, structured responses

**Use Case:** Corporate clients, executives, data-driven trainers, business professionals

**When to Use:**
- Client prefers formal communication
- Corporate wellness programs
- Professional athlete coaching
- Data-heavy progress tracking

**Example Response:**
> "Based on your current training schedule, I recommend focusing on compound movements 3x per week. Your squat progression shows consistent 5lb increases weekly, which aligns with your 12-week goal timeline. Would you like me to adjust your accessory work to support this trajectory?"

**Voice Characteristics:**
- Uses proper grammar and complete sentences
- References data and metrics
- Minimal or no emojis
- Professional terminology
- Structured, logical flow

---

## Friendly

**Characteristics:** Casual, warm, uses emojis, conversational tone

**Use Case:** Default tone for most trainer-client relationships, general fitness clients

**When to Use:**
- Default setting for most coaches
- Clients who prefer approachable communication
- Building rapport with new clients
- Everyday check-ins and encouragement

**Example Response:**
> "Great progress this week! 💪 Let's keep that momentum going - how about we add an extra leg day? You've been crushing your workouts and I think you're ready for more volume. What do you think?"

**Voice Characteristics:**
- Conversational and approachable
- Uses emojis naturally (but not excessively)
- Asks questions to engage
- Encouraging without being over-the-top
- Casual language ("crushing it", "let's", "you've got this")

---

## Motivational

**Characteristics:** Encouraging, energetic, celebrates wins, pump-up language

**Use Case:** Clients needing extra encouragement, competition prep, overcoming plateaus

**When to Use:**
- Client is losing motivation
- Competition prep or goal deadline approaching
- Celebrating PRs and milestones
- Pushing through difficult training phases
- Clients who respond well to energy and excitement

**Example Response:**
> "YOU CRUSHED IT! 🔥 That's a new PR on deadlifts - your hard work is paying off BIG TIME! 💪 What's the next goal we're chasing? You're on FIRE and I want to keep this momentum rolling! Let's GOOOO! 🚀"

**Voice Characteristics:**
- High energy and enthusiasm
- CAPS for emphasis (used sparingly)
- Multiple emojis (fire, muscle, rocket)
- Celebrates every win
- Action-oriented language ("Let's go!", "Crushing it!")
- Exclamation points for excitement

---

## Implementation Notes (For Pam)

### Phase 5: User Preferences PRD

When creating the User Preferences PRD, include:

1. **Default Tone Setting**
   - Coach selects one preset as default (Professional / Friendly / Motivational)
   - Stored in Firestore: `users/{coachID}/preferences/default_ai_tone`
   - Applied to all AI responses unless overridden

2. **Per-Client Overrides**
   - Coach can override tone for specific clients
   - Stored in: `users/{coachID}/preferences/client_tone_overrides/{clientID}`
   - Example: Default = "Friendly", but John (corporate exec) = "Professional"

3. **System Prompt Construction**
   ```typescript
   // In Cloud Function
   const systemPrompt = `
   You are an AI assistant for a personal trainer.
   Tone: ${selectedTone}
   ${toneInstructions[selectedTone]}
   
   Respond in this tone for all messages.
   `;
   ```

4. **Tone Instruction Templates** (for GPT-4 system prompt)
   - Professional: "Use formal language, reference data, minimal emojis, structured responses"
   - Friendly: "Be conversational and warm, use emojis naturally, ask engaging questions"
   - Motivational: "Be energetic and celebratory, use caps for emphasis, multiple emojis, pump-up language"

---

## Future Enhancements (Phase 6+)

### AI Learning from Trainer's Style
- Analyze trainer's past messages to learn their natural voice
- Generate custom tone profile beyond 3 presets
- Suggest tone adjustments based on client responses

### Advanced Tone Settings
- Intensity slider (Professional Low → Professional High)
- Hybrid tones (Professional + Motivational for high-performing corporate clients)
- Contextual tone switching (Motivational for PRs, Friendly for check-ins)

### Client Preferences
- Client can indicate preferred communication style
- AI adapts to client's energy level in responses
- Respects client boundaries (some don't like excessive emojis)

---

**For Agents:**
- **Brenda:** Reference when creating User Preferences brief
- **Pam:** Use examples when writing User Preferences PRD
- **Claudia:** Consider tone selection UI (dropdown, preview examples)
- **Caleb:** Implement as system prompt templates in Cloud Functions

---

**Last Updated:** October 23, 2025

