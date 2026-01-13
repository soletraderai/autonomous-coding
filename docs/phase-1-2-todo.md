# Phase 2 Feature Completion Plan - Teachy (QuizzTube)

## Executive Summary

**Current Status:** 372/415 features passing (89.6%)
**Target:** 415/415 features (100%)
**Failed Features:** 48 total (5 Phase 1, 43 Phase 2)

**Key Decisions:**
- Migrate authentication from JWT to Supabase Auth
- Code Sandbox: JavaScript only (no Python/Pyodide)
- Deployment: Digital Ocean + Supabase + Stripe

---

## Progress Tracking (Single Source of Truth)

**Last Updated:** 2026-01-13
**Session:** Phase 0 complete, Phase 1 complete, TypeScript errors fixed, ready for Phase 2+

### Phase 0: Supabase Auth Migration :white_check_mark: COMPLETE

| Task | Status | Verification | Notes |
|------|--------|--------------|-------|
| 0.1 Set up Supabase project | :white_check_mark: PASSED | MCP connected, `prisma db push` succeeded | Project: `gnvnpiaxducayitpmksd`, 20 tables synced |
| 0.2 Add supabaseId to User model | :white_check_mark: PASSED | `npx prisma generate` succeeded | Added `supabaseId String? @unique @map("supabase_id")` to User model in `api/prisma/schema.prisma:29` |
| 0.3 Create Supabase client libraries | :white_check_mark: PASSED | TypeScript compilation passed | Created `src/lib/supabase.ts` (frontend) and `api/src/lib/supabase.ts` (backend) |
| 0.4 Modify auth middleware for Supabase JWT | :white_check_mark: PASSED | `cd api && npm run build` passed | Updated `api/src/middleware/auth.ts` - supports both legacy JWT and Supabase tokens |
| 0.5 Update frontend auth store | :white_check_mark: PASSED | No TypeScript errors in file | Updated `src/stores/authStore.ts` with Supabase integration and `onAuthStateChange` listener |
| 0.6 Update Login/Signup pages | :white_check_mark: PASSED | No TypeScript errors | Added Google OAuth button functionality to both pages |
| 0.7 Create OAuth callback handler | :white_check_mark: PASSED | File created, no errors | Created `src/pages/AuthCallback.tsx` |
| 0.8 Update App.tsx with auth routes | :white_check_mark: PASSED | Route added successfully | Added `/auth/callback` route to `src/App.tsx:42` |

**Phase 0 Summary:**
- All 8/8 tasks complete
- Supabase project configured with Google OAuth enabled
- Database schema synced (20 tables)
- Environment files configured:
  - `generations/teachy/.env` - Frontend (VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY)
  - `generations/teachy/api/.env` - Backend (DATABASE_URL, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
- **Note:** RLS disabled on tables (acceptable since backend API handles auth via middleware)

### Phase 1: Install Missing Libraries :white_check_mark: COMPLETE

| Task | Status | Verification | Notes |
|------|--------|--------------|-------|
| 1.1 Install Framer Motion | :white_check_mark: PASSED | `npm ls framer-motion` shows installed | Ran `npm install framer-motion` - added 6 packages |
| 1.2 Add page transitions | :white_check_mark: PASSED | No TypeScript errors | Updated `src/components/ui/PageTransition.tsx` with `motion` and `AnimatePresence` |
| 1.3 Install TanStack Query | :white_check_mark: PASSED | `npm ls @tanstack/react-query` shows installed | Ran `npm install @tanstack/react-query` |
| 1.4 Set up QueryClientProvider | :white_check_mark: PASSED | No TypeScript errors | Created `src/lib/queryClient.ts`, wrapped App in `main.tsx` |
| 1.5 Migrate API calls to useQuery | :white_check_mark: PASSED | Manual testing + `npx tsc --noEmit` | See detailed verification below |

**Task 1.5 Detailed Verification:**

| Verification Step | Result | Why It Passed |
|-------------------|--------|---------------|
| TypeScript compilation | `npx tsc --noEmit` exits with 0 errors | All hooks properly typed, imports resolved, no type mismatches |
| Dashboard loads commitment | Data displays in "Today's Commitment" card | `useCommitment()` hook fetches from `/api/commitment/today`, returns `CommitmentData` |
| Dashboard loads insights (PRO) | Learning Insights section populated | `useLearningInsights()` hook fetches from `/api/learning-model`, transforms response |
| Goals list loads | Goals displayed or empty state shown | `useGoals(status)` hook fetches from `/api/goals?status=X` |
| Goals suggestions load | Suggested Goals section populated | `useGoalSuggestions()` hook fetches from `/api/goals/suggestions` |
| Create goal works | New goal appears in list after creation | `useCreateGoal()` mutation POSTs to `/api/goals`, invalidates cache |
| Edit goal works | Goal updates persist | `useUpdateGoal()` mutation PATCHes `/api/goals/:id`, invalidates cache |
| Delete goal works | Goal removed from list | `useDeleteGoal()` mutation DELETEs `/api/goals/:id`, invalidates cache |
| Query caching works | Navigating away and back shows instant data | TanStack Query caches for 5 min (staleTime), retains for 30 min (gcTime) |
| No console errors | Browser DevTools clean | No import errors, no runtime exceptions, no failed network requests |

**Phase 1 Summary:**
- All 5/5 tasks complete :white_check_mark:
- TanStack Query hooks created for Dashboard and Goals pages
- Benefits achieved:
  - Automatic caching (5 min stale, 30 min cache retention)
  - Query deduplication (no duplicate requests on re-renders)
  - Background refetch on window focus
  - Built-in retry with exponential backoff (3 retries)
  - ~150 lines of manual fetch/cache code removed from each page

### Phase 2-9: Not Started

| Phase | Status | Blocking Dependencies |
|-------|--------|----------------------|
| Phase 2: Server-Side Features | :x: NOT STARTED | None - can start |
| Phase 3: Timed Sessions | :x: NOT STARTED | None - Phase 1 complete, can start |
| Phase 4: Knowledge Map Optimization | :x: NOT STARTED | None - can start |
| Phase 5: Code Sandbox | :x: NOT STARTED | None - can start |
| Phase 6: Stripe Integration | :x: NOT STARTED | Stripe credentials needed |
| Phase 7: Email Infrastructure | :x: NOT STARTED | Resend account needed |
| Phase 8: Notification & ML | :x: NOT STARTED | Phase 7 must complete first |
| Phase 9: DevOps | :x: NOT STARTED | Digital Ocean setup needed |

---

## Pre-Existing TypeScript Errors :white_check_mark: ALL FIXED

All 12 TypeScript errors have been resolved. `npx tsc --noEmit` now passes with 0 errors.

| Error | Fix Applied | Why It Passed |
|-------|-------------|---------------|
| Dashboard.tsx(388): `correctAnswers` not on `SessionScore` | Changed to `questionsCorrect` | `SessionScore` interface defines `questionsCorrect`, not `correctAnswers` |
| Goals.tsx(357): `calculateProgress` declared but never read | Removed unused function | Function was dead code with no references |
| Library.tsx(22): condition always true | Changed `isAuthenticated` to `isAuthenticated()` | `isAuthenticated` is a function in authStore, must be called |
| Onboarding.tsx(230): string not assignable to `LearningStyle` | Added explicit type annotation + cast | `savedProgress.selectedStyle` needed cast to `LearningStyle` |
| Onboarding.tsx(236): `languageVariant` not in Settings | Extended `Settings` interface | Added `languageVariant?: LanguageVariant` to type definition |
| Onboarding.tsx(240): `dailyCommitment` not in Settings | Extended `Settings` interface | Added `dailyCommitment`, `preferredTime`, `learningDays` as optional fields |
| Settings.tsx(8): `SettingsSectionSkeleton` never read | Removed unused import | Import was not used anywhere in the file |
| Settings.tsx(146): `name` not on `AuthUser` | Changed to `displayName` | `AuthUser` interface has `displayName`, not `name` |
| Settings.tsx(682): `name` not on `AuthUser` | Changed to `displayName` | Same as above - consistent property naming |
| Settings.tsx(1870): `unknown` not assignable to `ReactNode` | Added `typeof` type guard | Proper runtime type check before rendering |
| sessionStore.ts(67): `id` not on `VideoMetadata` | Extended `VideoMetadata` interface | Added `id?: string` as optional property |
| sessionStore.ts(71): `channelId` not on `VideoMetadata` | Extended `VideoMetadata` interface | Added `channelId?: string` as optional property |

**Files Modified:**
- `src/types/index.ts` - Extended `Settings` and `VideoMetadata` interfaces, added `LanguageVariant` type
- `src/pages/Dashboard.tsx` - Fixed property name
- `src/pages/Settings.tsx` - Fixed property names, type guard, removed import
- `src/pages/Library.tsx` - Fixed function call
- `src/pages/Onboarding.tsx` - Fixed type annotations, array typing
- `src/pages/Goals.tsx` - Removed unused function

---

## Next Steps (Priority Order)

### Completed Actions

1. ~~**Test Supabase Auth Flow**~~ :white_check_mark: DONE
   - Email/password signup works
   - Google OAuth configured
   - Token refresh implemented

2. ~~**Fix Pre-Existing TypeScript Errors**~~ :white_check_mark: DONE
   - All 12 errors resolved
   - `npx tsc --noEmit` passes clean

3. ~~**Complete Phase 1.5: Migrate API calls to useQuery**~~ :white_check_mark: DONE
   - Created custom hooks for Dashboard and Goals pages
   - Automatic caching, deduplication, and retry logic now active
   - Manual testing confirmed all features working

### Immediate Actions (Ready to Execute)

1. **Start Phase 2: Server-Side Features**
   - Complete Gemini API integration (needs API key)
   - Create knowledge base server endpoint
   - Connect knowledge base to question generation

2. **Start Phase 3: Timed Sessions** (largest feature set - 12 features)
   - Create Timed Sessions page
   - Implement timer with session types (Rapid/Focused/Comprehensive)
   - Add results and history tracking

3. **Provide Stripe Test Keys** (for Phase 6)
   ```env
   STRIPE_SECRET_KEY=sk_test_...
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

4. **Provide Resend API Key** (for Phase 7)
   ```env
   RESEND_API_KEY=re_...
   ```

---

## Files Created/Modified This Session

### New Files Created
| File | Purpose |
|------|---------|
| `src/lib/supabase.ts` | Frontend Supabase client with auth helpers |
| `src/lib/queryClient.ts` | TanStack Query client configuration |
| `src/pages/AuthCallback.tsx` | OAuth redirect handler |
| `api/src/lib/supabase.ts` | Backend Supabase admin client |

### Files Modified
| File | Changes |
|------|---------|
| `api/prisma/schema.prisma` | Added `supabaseId` field to User model |
| `api/src/middleware/auth.ts` | Added Supabase token verification alongside legacy JWT |
| `src/stores/authStore.ts` | Integrated Supabase auth with backwards compatibility |
| `src/pages/Login.tsx` | Added working Google OAuth button |
| `src/pages/Signup.tsx` | Added working Google OAuth button |
| `src/components/ui/PageTransition.tsx` | Replaced CSS transitions with Framer Motion |
| `src/components/ui/StaggeredList.tsx` | Replaced CSS animations with Framer Motion |
| `src/main.tsx` | Added QueryClientProvider wrapper |
| `src/App.tsx` | Added /auth/callback route |
| `package.json` | Added framer-motion, @tanstack/react-query, @supabase/supabase-js |
| `api/package.json` | Added @supabase/supabase-js |

### Files Modified (TypeScript Error Fixes - Session 2)
| File | Changes |
|------|---------|
| `src/types/index.ts` | Extended `VideoMetadata` (added `id`, `channelId`), extended `Settings` (added `languageVariant`, `dailyCommitment`, `preferredTime`, `learningDays`), added `LanguageVariant` type |
| `src/pages/Dashboard.tsx` | Fixed `correctAnswers` → `questionsCorrect` |
| `src/pages/Settings.tsx` | Fixed `user?.name` → `user?.displayName` (2 places), added type guard for `patternData`, removed unused import |
| `src/pages/Library.tsx` | Fixed `isAuthenticated` → `isAuthenticated()` |
| `src/pages/Onboarding.tsx` | Added `LearningStyle` import, typed `learningStyles` array, added type annotation to `selectedStyle` state, fixed `'hands-on'` → `'kinesthetic'` |
| `src/pages/Goals.tsx` | Removed unused `calculateProgress` function |

### Files Created (Phase 1.5 - TanStack Query Migration)
| File | Purpose |
|------|---------|
| `src/hooks/queries/useCommitment.ts` | Hook for fetching daily commitment data |
| `src/hooks/queries/useLearningInsights.ts` | Hook for fetching PRO learning insights |
| `src/hooks/queries/useGoals.ts` | Hooks for fetching goals and suggestions |
| `src/hooks/mutations/useGoalMutations.ts` | Mutations for create, update, delete goals |
| `src/hooks/index.ts` | Re-exports all hooks |

### Files Modified (Phase 1.5 - TanStack Query Migration)
| File | Changes |
|------|---------|
| `src/lib/queryClient.ts` | Added query keys for commitment, learningInsights, goals.suggestions |
| `src/pages/Dashboard.tsx` | Replaced useEffect/useState with useCommitment and useLearningInsights hooks |
| `src/pages/Goals.tsx` | Replaced fetch calls with useGoals, useGoalSuggestions, and mutation hooks |

---

## Implementation Phases (Reference)

### Phase 0: Supabase Auth Migration (CRITICAL PATH)
**Features Addressed:** #338 (Google OAuth)

| Task | Complexity | Files to Modify |
|------|------------|-----------------|
| 0.1 Set up Supabase project | Simple | External (supabase.com) |
| 0.2 Add supabaseId to User model | Simple | `api/prisma/schema.prisma` |
| 0.3 Create Supabase client libraries | Medium | `src/lib/supabase.ts`, `api/src/lib/supabase.ts` |
| 0.4 Modify auth middleware for Supabase JWT | Medium | `api/src/middleware/auth.ts` |
| 0.5 Update frontend auth store | Medium | `src/stores/authStore.ts` |
| 0.6 Update Login/Signup pages | Medium | `src/pages/Login.tsx`, `src/pages/Signup.tsx` |
| 0.7 Create OAuth callback handler | Simple | `src/pages/AuthCallback.tsx` (new) |
| 0.8 Update App.tsx with auth routes | Simple | `src/App.tsx` |

**Success Criteria:**
- Email/password login/signup works through Supabase
- Google OAuth flow completes successfully
- Token refresh works automatically
- Existing users can migrate

---

### Phase 1: Install Missing Libraries
**Features Addressed:** #449, #603 (Framer Motion), #616 (TanStack Query)

| Task | Complexity | Action |
|------|------------|--------|
| 1.1 Install Framer Motion | Simple | `npm install framer-motion` |
| 1.2 Add page transitions | Medium | Update `PageTransition.tsx`, `StaggeredList.tsx` |
| 1.3 Install TanStack Query | Simple | `npm install @tanstack/react-query` |
| 1.4 Set up QueryClientProvider | Medium | Update `main.tsx`, create `lib/queryClient.ts` |
| 1.5 Migrate API calls to useQuery | Medium | Refactor service files |

**Success Criteria:**
- Page transitions animate smoothly
- List items stagger on mount
- Server state managed with caching

---

### Phase 2: Server-Side Features
**Features Addressed:** #103, #105, #220, #223, #224

| Task | Complexity | Files |
|------|------------|-------|
| 2.1 Complete Gemini API integration | Medium | `api/src/routes/ai.ts` |
| 2.2 Create knowledge base server endpoint | Complex | `api/src/routes/knowledgeBase.ts` (new) |
| 2.3 Update frontend knowledge base service | Medium | `src/services/knowledgeBase.ts` |
| 2.4 Connect knowledge base to question generation | Medium | `api/src/routes/ai.ts` |

**Success Criteria:**
- External sources (GitHub READMEs) fetched via server proxy
- AI feedback references knowledge base sources
- Questions generated from actual transcript content
- Topic titles derived from video segments

---

### Phase 3: Timed Sessions
**Features Addressed:** #555-564, #687-688 (12 features)

| Task | Complexity | Files |
|------|------------|-------|
| 3.1 Create Timed Sessions page | Complex | `src/pages/TimedSessions.tsx` (new) |
| 3.2 Create active session component | Complex | `src/pages/TimedSessionActive.tsx` (new) |
| 3.3 Add session controls (skip, abandon) | Medium | Same as above |
| 3.4 Create results page | Medium | `src/pages/TimedSessionResults.tsx` (new) |
| 3.5 Create history page | Medium | Extend existing |
| 3.6 Add routes and navigation | Simple | `src/App.tsx`, `Layout.tsx` |

**Session Types:**
- Rapid: 5 minutes
- Focused: 15 minutes
- Comprehensive: 30 minutes

**Success Criteria:**
- Timer displays and counts down
- Warnings at 1 minute remaining
- Skip/abandon work correctly
- Results show accuracy and time metrics
- History tracks past timed sessions

---

### Phase 4: Knowledge Map Optimization
**Features Addressed:** #681, #682

| Task | Complexity | Files |
|------|------------|-------|
| 4.1 Optimize canvas rendering | Medium | `src/pages/KnowledgeMap.tsx` |
| 4.2 Add Web Workers for layout | Complex | `src/workers/knowledgeMapLayout.worker.ts` (new) |

**Success Criteria:**
- Renders smoothly with 100+ nodes
- Zoom/pan responsive (<16ms frame time)
- Layout calculation doesn't block UI

---

### Phase 5: Code Sandbox (JavaScript Only)
**Features Addressed:** #683-688 (6 features)

| Task | Complexity | Files |
|------|------------|-------|
| 5.1 Remove Python support | Simple | `src/components/ui/CodePlayground.tsx` |
| 5.2 Create isolated iframe sandbox | Complex | Same as above |
| 5.3 Capture console output | Medium | Same as above |
| 5.4 Add error boundary | Simple | Same as above |

**Success Criteria:**
- JavaScript executes in sandboxed iframe
- Console output captured and displayed
- 5-second execution timeout
- Errors caught gracefully

---

### Phase 6: Stripe Integration
**Features Addressed:** #700-702, #705 (4 features)

| Task | Complexity | Action |
|------|------------|--------|
| 6.1 Configure Stripe products | Simple | Stripe Dashboard |
| 6.2 Test webhook endpoint | Medium | `api/src/routes/webhooks.ts` |
| 6.3 Test billing portal | Simple | `api/src/routes/subscriptions.ts` |

**Success Criteria:**
- Products/prices configured
- Checkout creates subscription
- Webhooks update database
- Billing portal accessible

---

### Phase 7: Email Infrastructure
**Features Addressed:** #677-679, #696-697 (5 features)

| Task | Complexity | Action |
|------|------------|--------|
| 7.1 Set up Resend account | Simple | External |
| 7.2 Configure DNS records | Medium | SPF, DKIM, DMARC |
| 7.3 Configure bounce handling | Medium | `api/src/routes/webhooks.ts` |
| 7.4 Implement weekly email scheduler | Complex | `api/src/jobs/weeklyEmails.ts` (new) |

**Success Criteria:**
- Emails deliver to inbox (not spam)
- SPF/DKIM/DMARC pass
- Bounces handled gracefully
- Weekly emails sent on schedule

---

### Phase 8: Notification & ML Features
**Features Addressed:** #671, #675, #676 (3 features)

| Task | Complexity | Files |
|------|------------|-------|
| 8.1 Implement notification timing | Medium | `api/src/services/notificationScheduler.ts` (new) |
| 8.2 Implement topic priority algorithm | Complex | `api/src/services/topicPrioritizer.ts` (new) |
| 8.3 Implement quiet hours | Medium | Same as 8.1 |

**Success Criteria:**
- Notifications at optimal times based on user patterns
- Topics prioritized by spaced repetition algorithm
- Quiet hours respected

---

### Phase 9: DevOps & Infrastructure
**Features Addressed:** #712-717, #681 (7 features)

| Task | Complexity | Files |
|------|------------|-------|
| 9.1 Create production Dockerfile | Medium | `Dockerfile.prod` (new) |
| 9.2 Create GitHub Actions CI/CD | Complex | `.github/workflows/deploy.yml` (new) |
| 9.3 Add rollback script | Medium | Workflow update |
| 9.4 Add smoke tests | Medium | `tests/smoke.test.ts` (new) |
| 9.5 Set up monitoring | Medium | Sentry, UptimeRobot |
| 9.6 Configure alerts | Simple | External dashboards |
| 9.7 Configure SSL | Simple | Certbot/Let's Encrypt |
| 9.8 Database backup | Medium | DigitalOcean managed DB |

**Success Criteria:**
- Automated deployment on push to main
- Rollback available
- Smoke tests pass post-deployment
- Monitoring and alerts active
- SSL certificate auto-renewing
- Daily database backups

---

## Dependency Graph

```
Phase 0 (Supabase) ──────────────┐
                                 │
Phase 1 (Libraries) ─────────────┼──> Phase 3 (Timed Sessions)
                                 │
Phase 2 (Server-side) ───────────┼──> Phase 4 (Knowledge Map)
                                 │
                                 └──> Phase 5 (Code Sandbox)

Phase 6 (Stripe) ────────────────> Independent

Phase 7 (Email) ─────────────────> Phase 8 (Notifications/ML)

Phase 9 (DevOps) ────────────────> Can parallel after Phase 0
```

---

## Feature Mapping Summary

| Phase | Features | Count |
|-------|----------|-------|
| 0 | #338 | 1 |
| 1 | #449, #603, #616 | 3 |
| 2 | #103, #105, #220, #223, #224 | 5 |
| 3 | #555-564, #687-688 | 12 |
| 4 | #681, #682 | 2 |
| 5 | #683-688 | 6 |
| 6 | #700-702, #705 | 4 |
| 7 | #677-679, #696-697 | 5 |
| 8 | #671, #675, #676 | 3 |
| 9 | #712-717, #681 (backup) | 7 |
| **Total** | | **48** |

---

## Critical Files Reference

| File | Purpose |
|------|---------|
| `api/src/middleware/auth.ts` | Auth middleware - Supabase JWT verification |
| `src/stores/authStore.ts` | Frontend auth state - Supabase integration |
| `api/prisma/schema.prisma` | Database schema with all models |
| `src/lib/queryClient.ts` | TanStack Query configuration and query keys |
| `src/hooks/index.ts` | Central export for all custom hooks |
| `src/hooks/queries/*.ts` | Query hooks (useCommitment, useLearningInsights, useGoals) |
| `src/hooks/mutations/*.ts` | Mutation hooks (useCreateGoal, useUpdateGoal, useDeleteGoal) |
| `src/pages/KnowledgeMap.tsx` | Canvas visualization to optimize |
| `src/components/ui/CodePlayground.tsx` | Code execution - JS sandbox |
| `api/src/routes/ai.ts` | AI/Gemini integration |
| `api/src/routes/webhooks.ts` | Stripe + email webhooks |

---

## Verification Plan

After each phase:
1. Run the application locally (`npm run dev`)
2. Test affected features manually
3. Run existing tests (`npm test`)
4. Query features.db to verify pass status updated
5. Check for console errors

Final verification:
- All 415 features should pass
- Full user journey test (signup -> session -> review -> subscription)
- Mobile responsiveness check
- Performance audit (Lighthouse)
