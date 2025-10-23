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

### Step 7: Commit Changes Functionally (ONLY AFTER USER APPROVAL)

**⚠️ PREREQUISITE: User has tested and explicitly approved ⚠️**

**🧹 BEFORE COMMITTING: Clean up all debug code**

**MANDATORY cleanup checklist:**
- [ ] Remove all `print()` debug statements
- [ ] Remove all `debugPrint()` statements
- [ ] Remove all commented-out code
- [ ] Remove all `// TODO:` comments (unless tracking actual future work)
- [ ] Remove all `// FIXME:` comments
- [ ] Remove all test/placeholder values
- [ ] Remove all unused imports
- [ ] Verify no console spam during normal usage

**IMPORTANT: Commit by function/feature, not all at once**

When user confirms feature is working and ready for PR, commit in logical functional chunks:

**Commit Strategy:**
- Commit by functional component (not all files in one commit)
- Make it easy for anyone to see how things are implemented
- Don't over-commit (avoid giant commits with 20+ files)
- Each commit should be a logical, complete piece of functionality

**Example commit sequence for PR-005:**
```bash
# Commit 1: Data model
git add Psst/Psst/Models/ReadReceiptDetail.swift
git commit -m "feat(pr-005): add ReadReceiptDetail data model"

# Commit 2: Service layer
git add Psst/Psst/Services/MessageService.swift
git commit -m "feat(pr-005): add fetchReadReceiptDetails to MessageService"

# Commit 3: ViewModel
git add Psst/Psst/ViewModels/ReadReceiptDetailViewModel.swift
git commit -m "feat(pr-005): add ReadReceiptDetailViewModel with real-time listener"

# Commit 4: UI components
git add Psst/Psst/Views/Components/ReadReceiptMemberRow.swift
git add Psst/Psst/Views/Components/ReadReceiptDetailView.swift
git commit -m "feat(pr-005): add read receipt detail UI components"

# Commit 5: Integration
git add Psst/Psst/Views/Components/MessageReadIndicatorView.swift
git commit -m "feat(pr-005): add tap gesture to MessageReadIndicatorView for groups"

# Commit 6: Documentation
git add Psst/docs/todos/pr-005-todo.md
git commit -m "docs(pr-005): update TODO with completed tasks"

# Push all commits
git push origin feat/pr-{number}-{feature-name}
```

**Guidelines:**
- Group related files together (e.g., all UI components in one commit)
- Separate major functional pieces (data model, service, viewmodel, UI)
- Keep commits focused on one logical change
- Write clear commit messages that explain what was added/changed

### Step 8: Create Pull Request with Summary

**IMPORTANT: PR must target `develop` branch, NOT `main`**

**Use GitHub CLI to create PR with summary included:**

```bash
# Create PR with full summary in CLI command
gh pr create \
  --base develop \
  --head feat/pr-{number}-{feature-name} \
  --title "PR #{number}: {Feature Name}" \
  --body "## Summary
{One sentence: what does this PR do?}

## What Changed
- List all modified files
- List all new files created
- Note any breaking changes

## Testing
- [x] Configuration testing complete
- [x] User flow testing complete
- [x] Multi-device testing complete (real-time sync <100ms)
- [x] Offline behavior tested
- [x] All acceptance gates pass
- [x] Visual states verified
- [x] Performance targets met (see shared-standards.md)

## Checklist
- [x] All TODO items completed
- [x] Code follows patterns from shared-standards.md
- [x] No console warnings
- [x] Documentation updated

## Notes
{Any gotchas, trade-offs, or future improvements}"
```

**Example for PR-005:**
```bash
gh pr create \
  --base develop \
  --head feat/pr-005-group-read-receipts-detailed-view \
  --title "PR #005: Group Read Receipts Detailed View" \
  --body "## Summary
Implemented detailed read receipt view for group chats showing which members have read messages by name.

## What Changed
- Added ReadReceiptDetail.swift (new data model)
- Modified MessageService.swift (added fetchReadReceiptDetails method)
- Added ReadReceiptDetailViewModel.swift (manages state and real-time updates)
- Added ReadReceiptDetailView.swift (modal sheet component)
- Added ReadReceiptMemberRow.swift (member list row component)
- Modified MessageReadIndicatorView.swift (added tap gesture for groups)

## Testing
- [x] Configuration testing complete
- [x] User flow testing complete (tap, display, dismiss)
- [x] Multi-device testing complete (real-time sync <100ms)
- [x] Offline behavior tested
- [x] All acceptance gates pass (9/9)
- [x] Visual states verified (loading, error, empty, success)
- [x] Performance targets met (<300ms load, 60fps animations)

## Checklist
- [x] All TODO items completed
- [x] Code follows patterns from shared-standards.md
- [x] No console warnings
- [x] Documentation updated

## Notes
- Feature only activates in group chats (3+ members)
- Uses existing message.readBy array (no schema changes)
- Real-time updates via Firestore listener
- Profile photos with initials fallback"
```

**After creating PR:**
1. **IMPORTANT: Return the PR URL to the user**
2. Example output:
   ```
   ✅ PR created successfully!
   
   PR URL: https://github.com/username/repo/pull/27
   
   Ready for review.
   ```

**PR Creation Checklist:**
- [ ] Used `gh pr create` CLI command
- [ ] Included full summary in `--body` parameter
- [ ] Targeted `develop` branch (not main)
- [ ] Used correct branch name format
- [ ] **Returned PR URL to user**

---

## Code Review Self-Checklist

Before submitting PR, verify:
- [ ] Code follows `Psst/agents/shared-standards.md` (architecture, code quality, Swift/SwiftUI best practices)
- [ ] All testing complete (see Step 4 and TODO document)
- [ ] Documentation updated

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
- ✅ **All debug code removed (MANDATORY)**
- ✅ No console warnings or debug spam
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
# - Confirm: "Ready to commit?"
# - WAIT for approval

# 8. Commit functionally (after user approval)
# Data model
git add Psst/Psst/Models/Message.swift
git commit -m "feat(pr-1): add Message data model"

# Service layer
git add Psst/Psst/Services/MessageService.swift
git commit -m "feat(pr-1): add sendMessage to MessageService"

# UI components
git add Psst/Psst/Views/ChatView.swift Psst/Psst/Views/MessageInputView.swift
git commit -m "feat(pr-1): add chat view and message input UI"

# Documentation
git add Psst/docs/todos/pr-1-todo.md
git commit -m "docs(pr-1): update TODO with completed tasks"

# Push all commits
git push origin feat/pr-1-message-send

# 9. Create PR with summary in CLI command
gh pr create \
  --base develop \
  --head feat/pr-1-message-send \
  --title "PR #001: Message Send Functionality" \
  --body "## Summary
Implemented message send functionality with real-time sync.

## What Changed
- Added Message.swift data model
- Added sendMessage to MessageService
- Added ChatView and MessageInputView

## Testing
- [x] All testing complete

## Checklist
- [x] All TODO items completed"

# Return PR URL to user
# ✅ PR created successfully!
# PR URL: https://github.com/username/repo/pull/1

# 10. Merge when approved
```

---

**Remember:** Quality over speed. Better to ship solid feature late than buggy feature on time.

**See common issues and solutions in `Psst/agents/shared-standards.md`**

