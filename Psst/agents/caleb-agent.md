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
- **CHECK OFF each task immediately after completing it**
- If blocked, document in TODO
- Keep PRD open as reference

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
3. Re-run tests
4. Don't proceed until all pass

### Step 6: Verify With User (Before PR)

**BEFORE creating PR:**

1. **Build and run:**
   ```bash
   xcodebuild -scheme Psst -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

2. **Test end-to-end:**
   - Does it work as described?
   - Any bugs or unexpected behaviors?
   - Smooth and responsive?

3. **Confirm with user:**
   ```
   "Feature complete. All tests pass. All acceptance gates pass. 
   No bugs found. Ready to create PR?"
   ```

4. **Wait for user approval** before proceeding

**If user finds issues:**
- Document in TODO
- Fix issues
- Re-run tests
- Verify again

### Step 7: Create Pull Request

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
- ✅ All TODO items checked off
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
# - Check off each task as completed
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

