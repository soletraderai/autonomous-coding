# Session Notes

Cross-session documentation for tracking development progress with Claude Code.

---

## Test Accounts

| Type | Email | Password |
|------|-------|----------|
| PRO | `test-admin@teachy.local` | `TestAdmin123!` |
| FREE | `freetest.teachy@gmail.com` | `FreeTest123!` |

---

## Quick Reference

### Running the App
```bash
# Frontend (port 5173)
cd /Users/marepomana/Web/Teachy/generations/teachy
npm run dev

# Backend (port 3001) - requires Redis
cd /Users/marepomana/Web/Teachy/generations/teachy/api
npm run dev

# Start Redis
brew services start redis
```

### Key Files for Auth/Tier Issues
- `src/stores/authStore.ts` - Auth state management, tier fetching
- `src/components/ui/ProfileTicket.tsx` - Tier badge display
- `src/App.tsx` - AuthInitializer, hydration handling

---

## Sessions

### 2026-01-15: Pro Tier Display Fix (Phase 6)

**Problem:** Pro users showing as FREE despite database having correct tier=PRO. This was the 6th attempt to fix this issue.

**Root Cause:** 5 overlapping race conditions:
1. `isLoading: false` initial state
2. ProfileTicket defaults to 'Free'
3. Zustand persist hydrates stale data before fresh fetch
4. Backend failures silently default to FREE
5. AuthInitializer doesn't wait for hydration

**Fixes Applied:**
| Fix | File | Change |
|-----|------|--------|
| isLoading initial state | `authStore.ts:75` | Changed `false` → `true` |
| ProfileTicket default | `ProfileTicket.tsx:29` | Removed default, added loading state |
| Hydration tracking | `authStore.ts` | Added `hasHydrated` + `onRehydrateStorage` |
| AuthInitializer timing | `App.tsx` | Wait for hydration before init |
| Backend retry | `authStore.ts` | Added retry logic with tier preservation |

**Test Results:**
- [x] Login as test-admin@teachy.local - PASSED
- [x] Tier shows "PRO" immediately - PASSED
- [x] localStorage shows `tier: "PRO"` - PASSED
- [x] Sidebar ProfileTicket displays PRO badge - PASSED
- [x] Learning Insights shows PRO badge - PASSED
- [x] Page refresh preserves PRO tier - PASSED
- [x] FREE user login works correctly - PASSED

**Status:** RESOLVED

---
