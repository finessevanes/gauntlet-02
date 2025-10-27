# Architecture Documentation Guide

**Created:** October 25, 2025
**Purpose:** Help choose the right architecture doc for your context needs

---

## Available Documentation

### 1. `architecture-concise.md` (350 lines) ⭐ **RECOMMENDED FOR AGENTS**

**Best for:**
- Agent context (Pam, Caleb, Brenda workflows)
- Quick reference during development
- Understanding system at a glance
- New developers onboarding

**Contains:**
- System overview (stack, status)
- Firestore schema (all collections)
- Cloud Functions list (8 functions)
- iOS app structure (services, models, viewmodels)
- Data flow examples
- Completed PRs summary
- Integration points

**Context cost:** ~1,400 tokens (efficient!)

---

### 2. `architecture.md` (984 lines) **MODERATE DETAIL**

**Best for:**
- Detailed technical reference
- Understanding data flows
- Integration strategy
- Testing and deployment info
- Performance targets

**Contains:**
- Everything in concise version PLUS:
- Detailed project structure
- Complete data flow diagrams
- Technical stack details
- Implementation status (all PRs)
- Design patterns
- Security considerations
- Testing strategy
- Deployment procedures

**Context cost:** ~3,900 tokens

---

### 3. `architecture-full-backup.md` (1,381 lines) **COMPREHENSIVE**

**Best for:**
- Deep brownfield analysis
- Historical context
- Migration planning
- Complete implementation details

**Contains:**
- Everything in moderate version PLUS:
- Detailed brownfield analysis (PR #006.5, #009)
- File-by-file modification lists
- Migration strategies
- Testing checklists
- Security rule examples
- Integration point details

**Context cost:** ~5,500 tokens (use sparingly!)

---

### 4. `brownfield-analysis-pr-009.md` **SPECIALIZED**

**Best for:**
- Understanding trainer-client relationship system
- Migration scripts
- Access control changes
- Risk assessment for PR #009

**Contains:**
- PR #009 specific brownfield analysis
- Affected services and files
- Migration strategy
- Rollback plan
- Testing requirements

---

## When to Use Which Doc

### Scenario: "I'm an agent building a new feature"
✅ Use `architecture-concise.md`
- Fast context loading
- All essential info (schema, services, structure)
- Integration points clearly marked

### Scenario: "I need to understand how AI features work"
✅ Use `architecture.md`
- Detailed data flows
- AI system architecture
- Complete PR implementation status

### Scenario: "I'm modifying the relationship system"
✅ Use `brownfield-analysis-pr-009.md`
- Focused on PR #009
- Migration details
- Risk mitigation

### Scenario: "I need every detail about the codebase"
⚠️ Use `architecture-full-backup.md`
- Only when absolutely necessary
- High context cost
- Contains duplicate information

---

## Context Management Strategy

**For agent workflows (/pam, /caleb, /brenda):**

```
Read: architecture-concise.md      (1,400 tokens)
Read: specific PRD if needed       (~1,000 tokens)
Read: specific TODO if needed      (~800 tokens)
---------------------------------------------
Total: ~3,200 tokens (efficient!)
```

**vs. Old approach:**

```
Read: architecture.md (full)       (5,500 tokens)
Read: duplicate brownfield info    (+2,000 tokens)
Read: PRD                          (+1,000 tokens)
---------------------------------------------
Total: ~8,500 tokens (wasteful!)
```

**Savings: 62% token reduction!**

---

## Quick Reference Table

| Document | Lines | Tokens | Use Case |
|----------|-------|--------|----------|
| `architecture-concise.md` | 350 | ~1,400 | ⭐ Agent workflows, quick ref |
| `architecture.md` | 984 | ~3,900 | Detailed dev reference |
| `architecture-full-backup.md` | 1,381 | ~5,500 | Comprehensive backup |
| `brownfield-analysis-pr-009.md` | ~500 | ~2,000 | PR #009 specific |

---

## Best Practices

**For Pam (Planning Agent):**
1. Read `architecture-concise.md` for system context
2. Read specific PRD from `prds/` folder
3. Generate TODO from templates

**For Caleb (Coder Agent):**
1. Read `architecture-concise.md` for integration points
2. Read PRD + TODO from `prds/` and `todos/`
3. Reference specific services/models as needed

**For Arnold (Architect):**
1. Update `architecture-concise.md` for quick ref changes
2. Update `architecture.md` for detailed changes
3. Create separate brownfield docs for major enhancements

**For Brenda (Brief Creator):**
1. Read `architecture-concise.md` for feature context
2. Check `ai-briefs.md` for existing features
3. Create briefs without needing full architecture

---

## Document Maintenance

**When to update:**
- New PR completed → Update all 3 docs
- New service added → Update concise + moderate
- New Cloud Function → Update concise + moderate
- Migration script → Update brownfield doc
- Performance target change → Update moderate only

**Update checklist:**
```
□ architecture-concise.md (always)
□ architecture.md (if detailed changes)
□ Create new brownfield doc (if major enhancement)
□ Update this guide (if new doc added)
```

---

**Arnold says:** "Come with me if you want to build... with efficient context management."
