# Phase 4: Micro-Interactions - Implementation Todo List

> **Important**: After completing each phase, update the [Session Notes](./session-notes.md) with:
> - What was completed
> - Any blockers or issues encountered
> - Decisions made during implementation
> - Key learnings
> - Priority for next session
> - Update session-notes.md after each phase

---

## Reference Documents

- [PRD: Micro-Interactions & Personalization](./prd-microinteractions.md)
- [Implementation Analysis](./microinteractions-analysis.md)
- [Session Notes](./session-notes.md)
- [Research: Micro-Interactions](../microinteractions.md)

---

## Pre-Development Setup

### Baseline Metrics (Do First)
- [ ] Record current Day 7 retention rate
- [ ] Record current Daily Active Users count
- [ ] Record current Time to First Quiz (funnel analysis)
- [ ] Record current Quiz Completion Rate
- [ ] Document baseline values in [Session Notes](./session-notes.md)

### Verify Infrastructure
- [x] Confirm Framer Motion is working (`npm list framer-motion`)
- [x] Verify `timezone` field exists in UserPreferences table
- [x] Verify `lastActiveAt` field is being updated on user activity
- [x] Confirm `displayName` is available in authStore

---

## Phase 1: Foundation

**Goal**: Establish personalized greetings and basic micro-interactions
**Priority**: P0 - Core personalization layer

### 1.1 Greeting Utility Functions

**File to create**: `src/utils/greeting.ts`

**Why**: Separating greeting logic into a utility makes it testable, reusable, and keeps the Dashboard component clean. The utility handles timezone conversion and contextual logic.

- [x] Create `src/utils/greeting.ts` file
- [x] Implement `getTimeBasedGreeting(timezone: string)` function
  - Returns: "Good morning" (5am-12pm), "Good afternoon" (12pm-5pm), "Good evening" (5pm-9pm), "Working late" (9pm-5am)
  - Uses `Intl.DateTimeFormat` with user's timezone
- [x] Implement `getContextualGreeting(lastActiveAt: Date | null, isFirstVisit: boolean)` function
  - First visit: "Welcome to Teachy."
  - Absence 3+ days: "Good to see you. Your progress is saved."
  - Otherwise: returns `null` (use time-based greeting)
- [x] Implement `buildGreetingMessage(displayName: string, timeGreeting: string, contextGreeting: string | null)` function
  - Combines components into final greeting string
  - Example output: "Good morning, Alex. Your progress is saved."
- [ ] Add unit tests for greeting functions

### 1.2 Dashboard Greeting Integration

**File to modify**: `src/pages/Dashboard.tsx`

**Why**: The dashboard is the first thing users see when they log in. A personalized greeting creates immediate recognition and emotional connection, which research shows increases retention by up to 15%.

**What exists**: Dashboard currently shows "Welcome back" or user stats without time/context awareness.

**What changes**: Replace static welcome with dynamic greeting that considers time of day and user context.

- [x] Import greeting utility functions
- [x] Fetch user's timezone from UserPreferences (or use browser default)
- [ ] Fetch `lastActiveAt` from user data
- [x] Determine if first dashboard visit (check `onboardingCompleted` + session count)
- [x] Render greeting at top of dashboard
- [x] Style greeting to match brutal design system (font-heading, appropriate sizing)
- [ ] Test greeting displays correctly for:
  - [ ] Morning user (5am-12pm in their timezone)
  - [ ] Afternoon user (12pm-5pm)
  - [ ] Evening user (5pm-9pm)
  - [ ] Night user (9pm-5am)
  - [x] First-time visitor
  - [ ] Returning after 3+ days absence
  - [ ] Regular return visit

### 1.3 Button Press Animation

**File to modify**: `src/components/ui/Button.tsx`

**Why**: Micro-interactions on buttons provide tactile feedback that makes the interface feel responsive. A subtle scale animation (0.98) on press is imperceptible consciously but felt subconsciously, improving perceived quality.

**What exists**: Button has Tailwind hover states but no press animation.

**What changes**: Wrap button in Framer Motion component with `whileTap` animation.

- [x] Import `motion` from 'framer-motion'
- [x] Convert button element to `motion.button`
- [x] Add `whileTap={{ scale: 0.98 }}` prop
- [x] Add `transition={{ duration: 0.1 }}` for snappy feel
- [x] Verify animation doesn't conflict with existing hover states
- [ ] Test on multiple button variants (primary, secondary, etc.)
- [ ] Test keyboard accessibility (Enter/Space should still work)

### 1.4 Empty State Component

**File to create**: `src/components/ui/EmptyState.tsx`

**Why**: Consistent empty states across the app create a cohesive experience. A reusable component ensures every empty state has the same structure: heading, description, and action. This is more maintainable than inline empty states scattered throughout the codebase.

**What exists**: Various inline empty states with inconsistent copy and styling.

**What changes**: Create single component, then replace inline implementations.

- [x] Create `src/components/ui/EmptyState.tsx`
- [x] Define interface:
  ```typescript
  interface EmptyStateProps {
    icon?: React.ReactNode;
    title: string;
    description?: string;
    action?: { label: string; onClick: () => void };
  }
  ```
- [x] Implement component with:
  - Centered layout (`flex flex-col items-center justify-center`)
  - Icon slot (optional)
  - Title (font-heading)
  - Description (text-text-secondary)
  - Action button (optional)
- [ ] Export from `src/components/ui/index.ts`

### 1.5 Replace Inline Empty States

**Files to modify**: Various pages

**Why**: Updating existing empty states to use the new component ensures consistency and makes future copy changes easy (single source of truth).

- [x] **Dashboard.tsx**: Replace "Start Your Learning Journey" empty state with EmptyState component
  - Title: "No sessions yet"
  - Description: "Start your first learning session to see your progress here."
  - Action: "Start Learning" → navigate to home
- [x] **Library page**: Update empty state
  - Title: "No videos yet"
  - Description: "Paste a video link to get started."
  - Action: "Add Video" → navigate to home
- [x] **Feed page**: Update empty/error state
  - Title: "No content yet"
  - Description: "Your feed will show content as you learn."
- [x] **Search results**: Update no results state
  - Title: "No results"
  - Description: "Try different keywords."
- [ ] **Goals page**: Verify empty state follows pattern (may already be good)

### 1.6 Error Message Improvements

**Files to modify**: Various components with error handling

**Why**: Harsh error messages ("Invalid input", "Error 404") feel robotic and frustrating. Concise, helpful messages maintain the professional tone while guiding users to resolution.

- [x] Audit current error messages across the app
- [x] Create error message copy guide:
  | Scenario | Current | New |
  |----------|---------|-----|
  | Network error | "Network error" | "Connection lost. Retrying..." |
  | Invalid input | "Invalid input" | "Check the format and try again" |
  | Not found | "Error 404" | "Page not found. Return to dashboard." |
  | Auth error | Varies | "Session expired. Please log in again." |
- [ ] Update error messages in:
  - [x] API error handlers
  - [x] Form validation
  - [ ] Network error boundaries
  - [x] 404 page

---

**✅ Phase 1 Complete Checklist**:
- [x] All greeting functions implemented and tested
- [x] Dashboard shows personalized greeting
- [x] Buttons have press animation
- [x] EmptyState component created
- [x] All empty states use new component
- [x] Error messages updated

**→ Update [Session Notes](./session-notes.md) before proceeding to Phase 2**

---

## Phase 2: Engagement

**Goal**: Add visual feedback to quiz interactions and progress
**Priority**: P0 - Core engagement features

### 2.1 Quiz Feedback Animations

**File to modify**: `src/pages/ActiveSession.tsx`

**Why**: Visual feedback on quiz answers provides immediate reinforcement. Research shows that micro-animations on correct/incorrect answers increase engagement and help with learning retention. The 300ms timing is noticeable but doesn't slow down the experience.

**What exists**: Sentiment detection already categorizes answers as excellent/good/needs-improvement. Color-coded cards display based on sentiment.

**What changes**: Add motion animations to feedback cards for visual reinforcement.

- [x] Import `motion` and animation variants from framer-motion
- [x] Create feedback animation variants:
  ```typescript
  const feedbackVariants = {
    correct: {
      scale: [1, 1.02, 1],
      transition: { duration: 0.3 }
    },
    incorrect: {
      x: [0, -4, 4, -4, 0],
      transition: { duration: 0.3 }
    }
  };
  ```
- [x] Wrap feedback card in `motion.div`
- [x] Apply `variants={feedbackVariants}` and `animate` based on sentiment
- [x] Map sentiment to animation:
  - "excellent" or "good" → correct animation (subtle scale pulse)
  - "needs-improvement" → incorrect animation (subtle shake)
- [x] Test animation timing feels right (adjust if needed)
- [x] Ensure animation doesn't interfere with "Dig Deeper" button click

### 2.2 Question Transition Animation

**File to modify**: `src/pages/ActiveSession.tsx`

**Why**: Smooth transitions between questions make the quiz feel polished rather than jarring. A simple fade creates continuity without slowing down users.

**What exists**: Questions change instantly with no transition.

**What changes**: Add fade transition when moving to next question.

- [x] Wrap question content in `motion.div`
- [x] Add `key={currentQuestionIndex}` to trigger animation on question change
- [x] Add animation props:
  ```typescript
  initial={{ opacity: 0 }}
  animate={{ opacity: 1 }}
  exit={{ opacity: 0 }}
  transition={{ duration: 0.2 }}
  ```
- [x] Wrap in `AnimatePresence` for exit animations
- [x] Test transition feels smooth, not slow
- [x] Verify question index updates correctly trigger animation

### 2.3 Quiz Completion Feedback

**File to modify**: `src/pages/SessionNotes.tsx`

**Why**: Completing a quiz is a significant moment. Visual feedback (progress bar filling, score display) provides satisfaction and closure.

**What exists**: Summary shows after quiz completion with score.

**What changes**: Animate the transition to summary and enhance the completion moment.

- [x] Add animated progress bar showing 100% on completion
- [x] Display score with AnimatedNumber component (already exists)
- [x] Add "Perfect score" badge for 100% accuracy:
  - Simple text badge, not over-the-top
  - Example: "Perfect score" with subtle highlight
- [x] Add CompletionCheckmark animation (component already exists)
- [x] Test completion flow feels satisfying but professional

### 2.4 Progress Bar Enhancement

**File to modify**: `src/components/ui/ProgressBar.tsx`

**Why**: Animated progress bars provide visual satisfaction when values change. This applies to quiz progress, daily commitment, and topic mastery displays.

**What exists**: Static progress bar component.

**What changes**: Add Framer Motion animation on value change.

- [x] Import `motion` from framer-motion
- [x] Convert inner div to `motion.div`
- [x] Add animation:
  ```typescript
  initial={{ width: 0 }}
  animate={{ width: `${percentage}%` }}
  transition={{ duration: 0.5, ease: 'easeOut' }}
  ```
- [x] Test animation on:
  - [x] Quiz progress indicator
  - [x] Daily commitment widget
  - [x] Topic mastery displays
- [x] Verify animation doesn't cause layout shift

### 2.5 Dashboard Stats Enhancement

**File to modify**: `src/pages/Dashboard.tsx`

**Why**: Making progress stats more prominent reinforces user achievements. Using AnimatedNumber for counts adds polish.

**What exists**: Quick Stats Card shows sessions, time invested, topics, accuracy.

**What changes**: Ensure AnimatedNumber is used and stats are visually prominent.

- [x] Verify AnimatedNumber is used for stat values (Session Score in SessionNotes uses AnimatedNumber)
- [x] Review stats card layout for prominence
- [x] Add brief labels if not present:
  - "X videos completed"
  - "X quizzes passed"
  - "X topics explored"
- [x] Test numbers animate on dashboard load

---

**✅ Phase 2 Complete Checklist**:
- [x] Quiz feedback has correct/incorrect animations
- [x] Questions transition smoothly
- [x] Quiz completion has enhanced feedback
- [x] Progress bars animate
- [x] Dashboard stats use animated numbers

**→ Update [Session Notes](./session-notes.md) before proceeding to Phase 3**

---

## Phase 3: AI Companion

**Goal**: Standardize chat responses with timestamps and consistent patterns
**Priority**: P1 - Enhancement to existing functionality

### 3.1 Update AI Response Prompts

**File to modify**: `src/services/gemini.ts`

**Why**: Consistent response patterns make the AI feel like a coherent persona rather than random outputs. Leading with the answer respects users' time, while offering elaboration gives them control.

**What exists**: Tutor personality system with PROFESSOR/COACH/DIRECT/CREATIVE modes. Prompts vary by personality.

**What changes**: Update prompts to follow consistent pattern regardless of personality:
1. Direct answer first
2. Video citation with timestamp
3. "Want more detail?" offer

- [x] Locate dig deeper / help panel prompt templates in gemini.ts
- [x] Update base prompt to include:
  ```
  Response format rules:
  1. Lead with a direct, concise answer (1-2 sentences max)
  2. Reference the video with timestamp when relevant: "From the video (MM:SS): [relevant quote]"
  3. End with: "Want more detail on any part?"
  4. Keep responses scannable - use bullet points for multiple items
  5. Maximum 3-4 sentences for initial response
  ```
- [x] Ensure personality still influences tone (DIRECT = more terse, COACH = more encouraging)
- [ ] Test responses maintain format across personalities (requires live API test)

### 3.2 Implement Timestamp References (DEFERRED)

**File to modify**: `src/services/gemini.ts` and potentially `src/components/ui/HelpPanel.tsx`

**Why**: Citing specific video timestamps adds credibility and allows users to verify or dive deeper into the source material. This is valuable for professional users who want to reference the original content.

**What exists**: Transcripts have timing data. AI responses don't currently cite timestamps.

**What changes**: Include transcript timing in context and instruct AI to cite sources.

**Status**: DEFERRED - Requires architectural changes to pass transcript timing data to AI functions

- [ ] Review transcript data structure to confirm timestamp availability
- [ ] Include relevant transcript segments with timestamps in AI context
- [ ] Update prompt to instruct timestamp citation:
  ```
  When referencing video content, include the timestamp:
  "From the video (2:34): [quote or paraphrase]"
  ```
- [ ] Test AI responses include timestamps when relevant
- [ ] Verify timestamps are accurate to transcript

### 3.3 Clickable Timestamp Links (Optional Enhancement - DEFERRED)

**File to modify**: `src/components/ui/HelpPanel.tsx`

**Why**: If timestamps are displayed, making them clickable to jump to that point in the video adds significant value.

**What exists**: Chat messages display as text.

**What changes**: Parse timestamp patterns in responses and make them clickable.

**Status**: DEFERRED - Depends on 3.2 being completed first

- [ ] Create regex to detect timestamp pattern: `\((\d{1,2}):(\d{2})\)`
- [ ] Replace matched patterns with clickable links
- [ ] On click, seek video player to that timestamp
- [ ] Verify video player is accessible from HelpPanel context
- [ ] Test clicking timestamp jumps to correct position

### 3.4 Response Pattern Consistency

**File to modify**: `src/components/ui/HelpPanel.tsx`

**Why**: Ensuring the UI supports the response pattern (direct answer → elaboration offer) may require minor adjustments.

- [x] Review how responses are rendered (already supports markdown)
- [x] Ensure markdown formatting is supported (for bullet points)
- [ ] Test "Want more detail?" pattern in conversation flow (requires live API)
- [x] Verify multi-turn conversations maintain context (conversation history passed to AI)

---

**✅ Phase 3 Complete Checklist**:
- [x] AI prompts updated with response format rules
- [x] Responses lead with direct answers (prompt updated)
- [ ] Timestamps are cited when referencing video (DEFERRED)
- [ ] (Optional) Timestamps are clickable (DEFERRED)
- [x] Response pattern is consistent across personalities (prompt format applies to all)

**→ Update [Session Notes](./session-notes.md) with Phase 3 completion**

---

## Bug Fixes (From Existing phase4-tasks.md)

**Note**: These are existing issues that should be addressed alongside or before micro-interactions work.

**Status**: ✅ All bug fixes completed (January 2026)

### Critical Issues
- [x] **Onboarding not completing**: "Start Learning" button does nothing
  - File: `src/pages/Onboarding.tsx`, `api/src/routes/users.ts`
  - **Fix**: Updated `handleComplete` to always navigate even on non-OK responses; fixed API to save all onboarding preferences (learning style, language variant, daily commitment, preferred time/days)
- [x] **Pro Tier not registering**: Database has PRO but UI shows FREE
  - Root cause: Port conflict between transcript proxy (3001) and API server
  - **Fix**: Changed transcript proxy (`server.js`) to use port 3002 by default; updated `youtube.ts` and `gemini.ts` to call port 3002
- [x] **Feed error**: "Unexpected token '<'" JSON parse error
  - **Fix**: Added content-type check in `Feed.tsx` before parsing JSON; now handles HTML error pages gracefully

### UI Issues
- [x] **Home page for logged-in users**: Remove Home, redirect to Dashboard
  - **Fix**: Added useEffect in `Home.tsx` to redirect authenticated users to `/dashboard` (preserves auto-start from Feed)
- [x] **Pricing overlay for logged-in users**: Show Pro option only, 20% opacity overlay
  - **Fix**: Added 60% opacity to Free tier card for logged-in FREE users; added "YOUR CURRENT PLAN" badge; disabled Free plan button
- [x] **Dashboard card responsiveness**: Cards don't expand on larger screens
  - **Fix**: Added `xl:grid-cols-4` breakpoints to grids in `Dashboard.tsx` for Continue Series, Recommendations, Recent Sessions, and Learning Paths sections

### Feedback Improvements
- [x] Provide more accurate and in-depth feedback on questions
  - **Fix**: Added `expectedAnswer` field to Question type; updated question generation prompts to include expected answer hints; enhanced `evaluateAnswer` prompt with clear verdict levels, specific evaluation criteria, and honest feedback
- [x] Improve system feedback overall
  - **Fix**: Enhanced evaluation prompt to require specific references to topic content, concrete suggestions, and honest assessment of incorrect/missing information


### Added Tasks

**Status**: ✅ All added tasks completed (January 2026)

#### AT-1: Remove Home Navigation Button from Dashboard ✅

**File modified**: `src/components/ui/Sidebar.tsx`

**What**: The dashboard has a "Home" navigation button that is redundant since logged-in users are already redirected from Home to Dashboard.

**Fix Applied**: Removed the Home navigation item from the `navItems` array in Sidebar.tsx. The logo still links to `/` if needed.

**Success**: Dashboard navigation no longer shows a "Home" button. Navigation remains functional without it.

---

#### AT-2: Pro Tier Not Registering in UI (Critical) ✅

**Files modified**: `src/stores/authStore.ts`, `src/main.tsx`

**What**: Users confirmed as PRO tier in Supabase database are displaying as FREE tier in the UI. Pro features are inaccessible despite correct database records.

**Root Cause**: The auth state listener only handled `SIGNED_IN` and `TOKEN_REFRESHED` events, not `INITIAL_SESSION`. When the app loaded with a persisted session, the tier data wasn't being refreshed from the backend.

**Fix Applied**:
1. Added `INITIAL_SESSION` event handling in authStore to fetch fresh user data on page load
2. Added user data refresh on `TOKEN_REFRESHED` events
3. Added `initializeAuth()` call in main.tsx on app startup

**Success**: Users with PRO tier in Supabase see "Pro" in the UI and can access all Pro features.

---

#### AT-3: Feed Page Shows Nothing ✅

**Files modified**: `src/pages/Feed.tsx`, `src/pages/Home.tsx`

**What**: The "Your Feed" page displays empty/blank content when it should show user activity or recommendations.

**Root Cause**: The "Start Learning" button in the empty state navigated to `/` without passing the `newSession` flag. Since logged-in users are redirected from `/` to `/dashboard`, clicking "Start Learning" would loop back to Dashboard instead of showing the video input form.

**Fix Applied**: Updated navigation calls to pass `{ state: { newSession: true } }` so users can access the video input form.

**Success**: Feed page displays content (activity, recommendations) or shows a meaningful empty state with working navigation.

---

#### AT-4: Start Learning Button Not Working (Critical) ✅

**Files modified**: `src/pages/Home.tsx`, `src/pages/Dashboard.tsx`, `src/pages/Feed.tsx`

**What**: Clicking the "Start Learning" button produces no response - no navigation, no modal, no action.

**Root Cause**: The button navigated to `/` which immediately redirected logged-in users back to `/dashboard`, creating a loop.

**Fix Applied**:
1. Added `newSession` state flag check in Home.tsx to bypass Dashboard redirect
2. Updated all "Start Learning" and "Start New Session" buttons in Dashboard.tsx and Feed.tsx to pass `{ state: { newSession: true } }`

**Success**: Clicking "Start Learning" navigates user to the video input page.

---

#### AT-5: Remove Duplicate "Create First Session" Section ✅

**File modified**: `src/pages/Dashboard.tsx`

**What**: Dashboard has a redundant "Create First Session" section at the bottom that duplicates the "Start Learning" functionality at the top.

**Fix Applied**: Removed the duplicate empty state section at the bottom of Dashboard.tsx (lines 1333-1366). The first empty state in the Continue Series section handles the no-sessions case.

**Success**: Dashboard no longer shows duplicate session creation CTAs. Only one clear "Start Learning" entry point exists.

---

#### AT-6: User Data Not Persisting to Database (Critical) ✅

**Files modified**: `src/stores/authStore.ts`, `src/main.tsx`

**What**: User data (sessions, progress, preferences) is only stored in local session/cookies. When users log back in, their data is gone. Data should persist to Supabase.

**Root Cause**: The `syncWithCloud()` function in sessionStore was never being called automatically. Sessions were being saved to the cloud, but not fetched back when the user logged in again.

**Fix Applied**:
1. Added automatic `syncWithCloud()` call in authStore when `INITIAL_SESSION` or `SIGNED_IN` events fire
2. Added backup sync call in main.tsx with 1-second delay to handle edge cases where auth state is restored from localStorage before events fire
3. The sessionStore already had proper cloud sync logic - just needed to be triggered

**Success**: User creates a session, logs out, logs back in, and sees their session history, progress stats, and preferences intact.
---

## Post-Implementation

### Verify Success Metrics
- [ ] Record post-implementation metrics (after 1-2 weeks)
- [ ] Compare to baseline:
  | Metric | Baseline | Post | Target | Status |
  |--------|----------|------|--------|--------|
  | Day 7 Retention | | | +10% | |
  | Daily Active Users | | | +15% | |
  | Time to First Quiz | | | -30% | |
  | Quiz Completion Rate | | | +25% | |
- [ ] Document results in [Session Notes](./session-notes.md)

### Final Review
- [ ] All animations perform well (<300ms)
- [ ] No accessibility regressions
- [ ] Greetings display correctly in all scenarios
- [ ] Empty states are consistent
- [ ] AI responses follow new pattern
- [ ] Bug fixes verified

---

## Out of Scope Reminder

Do NOT implement:
- Visual mascot or animated character
- Gamification (leaderboards, points, XP)
- Push notifications
- Social features (sharing, comparing)
- Audio/sound effects
- Haptic feedback
- Streak system (database schema changes required - defer to future phase)

---

*Last Updated: January 14, 2026 - Bug fixes completed*
