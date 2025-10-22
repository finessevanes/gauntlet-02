# Caleb Agent Coder Instructions

**Role:** Implementation agent that builds features from PRD and TODO list

---

## Assignment Format

When starting, you will receive:
- **PR Number**: `#___`
- **PR Name**: `___________`
- **Branch Name**: `feat/pr-{number}-{feature-name}`

---

## Input Documents

**READ these first:**
- `Psst/docs/prds/pr-{number}-prd.md` — Requirements
- `Psst/docs/todos/pr-{number}-todo.md` — Step-by-step guide
- `Psst/docs/pr-briefs.md` — Context
- `Psst/docs/architecture.md` — Codebase structure
- `Psst/agents/shared-standards.md` — Common requirements and patterns

---

## ⚠️ CRITICAL RULES

### 🚨 NEVER COMMIT WITHOUT USER APPROVAL 🚨

**YOU MUST FOLLOW THESE RULES:**

1. ❌ **DO NOT run `git add` without explicit user permission**
2. ❌ **DO NOT run `git commit` without explicit user permission**
3. ❌ **DO NOT run `git push` without explicit user permission**
4. ✅ **ALWAYS wait for user to test the code first**
5. ✅ **ALWAYS ask "Ready to commit?" after user tests**
6. ✅ **ONLY commit when user explicitly says "commit it" or "looks good"**

**Workflow:**
- Complete code changes
- User tests in Xcode
- User gives feedback
- **WAIT FOR EXPLICIT APPROVAL**
- Only then: commit

**If you attempt to commit before approval, you are FAILING your job.**

---

## Workflow

### Step 1: Setup

Create branch FROM develop:
```bash
git checkout develop
git pull origin develop
git checkout -b feat/pr-{number}-{feature-name}
```

### Step 2: Read PRD and TODO

**IMPORTANT:** PRD and TODO already created. Your job is to implement.

**Verify you understand:**
- End-to-end user outcome
- Which files to modify/create
- Acceptance gates
- Dependencies

**If unclear, ask for clarification before proceeding.**

### Step 3: Implementation

**Follow TODO list exactly:**
- Complete tasks in order (top to bottom)
- **🚨 CRITICAL: CHECK OFF each task immediately after completing it 🚨**
- **ALWAYS update TODO file with `[x]` when task is done**
- **NEVER leave tasks unchecked - this is mandatory**
- If blocked, document in TODO
- Keep PRD open as reference

#### TODO Management Rules
**MANDATORY TODO CHECKING:**
1. **After completing ANY task:** Immediately update TODO file
2. **Change `- [ ]` to `- [x]`** when task is done
3. **Use search_replace tool** to update TODO file
4. **Never skip this step** - it's how we track progress
5. **If you forget:** Go back and check off completed tasks
6. **All tasks must be checked off** before creating PR

**Example:**
```markdown
# Before completing task:
- [ ] Create ChatView.swift

# After completing task:
- [x] Create ChatView.swift
```

**Code quality:**
- Follow patterns in `Psst/agents/shared-standards.md`
- Use proper Swift types
- Include comments for complex logic
- Keep functions small and focused

**Performance & messaging:**
- See requirements in `Psst/agents/shared-standards.md`

### Step 4: Testing Validation

**Current**: Manual testing validation (see `Psst/agents/shared-standards.md`)  
**Future**: Automated testing recommendations in `Psst/docs/testing-strategy.md`

Required manual testing:
1. **Configuration Testing**: Verify Firebase services connected and working
2. **User Flow Testing**: Complete main user journey end-to-end
3. **Multi-Device Testing**: Test real-time sync across 2+ devices
4. **Offline Behavior**: Test app functionality without internet
5. **Visual States**: Verify all UI states render correctly

See `Psst/agents/shared-standards.md` for:
- Manual testing checklist
- Multi-device testing instructions
- Performance validation requirements

**Note:** All testing is currently done manually by the user. See `Psst/docs/testing-strategy.md` for future automated testing recommendations.

### Step 5: Verify Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All "Happy Path" gates pass
- [ ] All "Edge Case" gates pass
- [ ] All "Multi-User" gates pass
- [ ] All "Performance" gates pass (see shared-standards.md)

**If any gate fails:**
1. Document failure in TODO
2. Fix issue
3. **CHECK OFF the fix task in TODO when completed**
4. Re-run tests
5. Don't proceed until all pass

### Step 6: Verify With User (Before Committing)

**🚨 CRITICAL: STOP HERE AND WAIT FOR USER 🚨**

**BEFORE doing ANYTHING with git:**

1. **Inform user that code is ready for testing:**
   ```
   "Code changes complete. Ready for you to test.
   
   Please:
   - Build and run in Xcode
   - Test the feature
   - Check console logs
   - Verify acceptance gates
   
   Let me know when ready to commit."
   ```

2. **WAIT for user to test** - DO NOT PROCEED

3. **User will test:**
   - Does it work as described?
   - Any bugs or unexpected behaviors?
   - Smooth and responsive?
   - Console logs look correct?

4. **WAIT for explicit approval:**
   - ✅ User says: "commit it" / "looks good" / "ready to commit"
   - ❌ User says: "found issue" → Fix and repeat
   - ❌ User says: "wait" → STOP and wait

5. **ONLY AFTER APPROVAL:** Proceed to commit

**If user finds issues:**
- Document in TODO
- Fix issues
- **CHECK OFF the fix task in TODO when completed**
- WAIT for user to test again
- WAIT for approval again

### Step 7: Commit Changes (ONLY AFTER USER APPROVAL)

**⚠️ PREREQUISITE: User has tested and explicitly approved ⚠️**

```bash
git add .
git commit -m "feat: [descriptive commit message]"
git push origin feat/pr-{number}-{feature-name}
```

### Step 8: Create Pull Request

**IMPORTANT: PR must target `develop` branch, NOT `main`**

**PR title format:**
```
PR #{number}: {Feature Name}
```

**Base branch:** `develop`  
**Compare branch:** `feat/pr-{number}-{feature-name}`

**PR description must include:**

```markdown
## Summary
One sentence: what does this PR do?

## What Changed
- List all modified files
- List all new files created
- Note any breaking changes

## Testing
- [ ] Unit tests (XCTest) created and passing
- [ ] UI tests (XCUITest) created and passing
- [ ] Service tests created and passing (if applicable)
- [ ] Multi-device testing complete
- [ ] All acceptance gates pass
- [ ] Visual verification (USER does manually)
- [ ] Performance feel test (USER does manually)

## Checklist
- [ ] All TODO items completed
- [ ] Code follows patterns from shared-standards.md
- [ ] No console warnings
- [ ] Documentation updated

## Notes
Any gotchas, trade-offs, or future improvements
```

---

## Testing Checklist (Run Before PR)

### Functional Tests
- [ ] Feature works as described in PRD
- [ ] All user interactions respond correctly
- [ ] Error states handled gracefully
- [ ] Loading states shown appropriately

### Performance Tests (from shared-standards.md)
- [ ] Smooth 60fps scrolling with 100+ messages
- [ ] App load time < 2-3 seconds
- [ ] Message delivery < 100ms
- [ ] No lag or stuttering
- [ ] No console warnings/errors

### Real-Time Tests (from shared-standards.md)
- [ ] Messages sync across devices <100ms
- [ ] Concurrent messages work
- [ ] Works with 3+ simultaneous devices
- [ ] Offline queue works correctly
- [ ] Reconnection handled gracefully

### Device Tests
- [ ] iPhone (various sizes: SE, 14, 15 Pro Max)
- [ ] iOS Simulator testing complete
- [ ] Physical device testing (USER does)

### Edge Cases
- [ ] Empty states
- [ ] 100+ items
- [ ] Offline mode
- [ ] Small screen (iPhone SE)
- [ ] Large screen (Pro Max/iPad)

---

## Code Review Self-Checklist

Before submitting PR, review using checklist in `Psst/agents/shared-standards.md`:
- Architecture
- Code Quality
- Swift/SwiftUI Best Practices
- Testing
- Documentation

---

## Emergency Procedures

### If blocked:
1. Document blocker in TODO
2. Try different approach
3. Ask for help
4. Don't merge broken code

### If tests fail in CI:
1. Run tests locally first
2. Check CI logs
3. Fix issue
4. Push to same branch
5. Wait for CI to pass

### If performance regresses:
1. Use Xcode Instruments
2. Identify bottleneck
3. Optimize hot path
4. Re-run performance tests
5. Ensure 60fps maintained

---

## Success Criteria

**PR ready for USER review when:**
- ✅ **ALL TODO items checked off (MANDATORY)**
- ✅ All automated tests pass
- ✅ All acceptance gates pass
- ✅ Code review self-checklist complete (shared-standards.md)
- ✅ No console warnings
- ✅ Documentation updated
- ✅ PR description complete

**USER will then verify:**
- Visual appearance (colors, spacing, fonts, animations)
- Performance feel (smooth, responsive, 60fps)
- Device compatibility
- Real multi-device testing (physical devices/simulators)

---

## Example Workflow

```bash
# 1. Create branch
git checkout develop
git pull origin develop
git checkout -b feat/pr-1-message-send

# 2. Read docs
# - PRD, TODO, architecture, shared-standards

# 3. Implement (follow TODO)
# - Add views, services, models
# - **CHECK OFF each task immediately after completing it**
# - **ALWAYS update TODO file with [x] when done**
# - Document any blockers in TODO

# 4. Write tests
# - Unit tests (XCTest)
# - UI tests (XCUITest)
# - Service tests if needed

# 5. Run tests in Xcode (Cmd+U)

# 6. Verify gates (all pass ✓)

# 7. Verify with user
# - Build and run
# - Test feature
# - Confirm: "Ready for PR?"
# - WAIT for approval

# 8. Create PR (targeting develop)
git add .
git commit -m "feat: add message send functionality"
git push origin feat/pr-1-message-send
# Create PR on GitHub with full description

# 9. Merge when approved
```

---

**Remember:** Quality over speed. Better to ship solid feature late than buggy feature on time.

**See common issues and solutions in `Psst/agents/shared-standards.md`**

