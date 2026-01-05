# AGENT.md: SLAPP (The Big Board)

## 1. Project Vision

**Product:** SLAPP (Domain: slapp.fun)  
**Concept:** A "WhatsApp for Ideation." High-speed, collaborative whiteboard for small groups.  
**Core Loop:** Users create groups ("Boards"), invite friends via phone number, and "slap" sticky notes onto an infinite canvas.  
**The Hook:** Merging. Dragging notes together triggers AI synthesis (Edge Functions) to combine ideas.

---

## 2. 🔌 Integrations (CRITICAL - READ FIRST)

**STATUS: LOCKED.** The following services are configured and connected.

| Service | Status | Details |
|---------|--------|---------|
| Supabase | ✅ | Database, Auth, Realtime, Edge Functions |
| Google Cloud | ✅ | Project: `slap-483318` (Number: `59472721706`) |
| Authentication | ✅ | Phone Auth via Supabase OTP |
| Hosting | ✅ | GitHub Codespaces (Dev), Web/Mobile (Target) |

> ⚠️ **WARNING:** DO NOT suggest re-connecting these services. They are working. DO NOT change the tech stack without explicit instruction.

---

## 3. 🚨 Development Standards

**Role:** You are acting as the Senior Flutter Architect and Systems Engineer.

**Protocol:**
1. **UNDERSTAND:** Read related files, check schema, trace data flow.
2. **PLAN:** Consider edge cases (offline mode, race conditions in Realtime).
3. **VERIFY:** Check Riverpod providers, GoRouter paths, and Supabase RLS policies.
4. **TEST:** Mentally trace the code path from UI interaction → Riverpod Controller → Supabase → UI Update.

### 3.1 Critical Flutter + Riverpod Patterns

❌ **THE WRONG WAY (NEVER DO THIS):**

```dart
// WRONG: Using setState for global data
setState(() {
  _notes = newNotes;
});

// WRONG: Passing Ref to functions where it doesn't belong
void helperFunction(WidgetRef ref) { ... }
```

✅ **THE RIGHT WAY (ALWAYS DO THIS):**

```dart
// CORRECT: Use Riverpod Generator for Logic
@riverpod
class BoardController extends _$BoardController {
  Future<void> addSlap(String content) async {
    // Logic here
  }
}

// CORRECT: Watch state in the Widget
final boardState = ref.watch(boardControllerProvider);
```

### 3.2 Database Access Patterns

- **Supabase Client:** Access via the global `supabase` getter in `main.dart`, never instantiate `SupabaseClient` manually inside widgets.
- **Realtime Subscriptions:** Always unsubscribe/dispose of streams in the `onDispose` or `ref.onDispose` block.
- **RLS Compliance:** Always ensure queries include the `board_id` to comply with Row Level Security.

---

## 4. 🛠 Tech Stack & Architecture

| Layer | Tool | Configuration |
|-------|------|---------------|
| Framework | Flutter | SDK ^3.5.4 |
| State | Riverpod | Annotation/Generator Syntax (`@riverpod`) |
| Navigation | GoRouter | v15.1.2, Declarative routing |
| Backend | Supabase | Postgres + Auth + Realtime + Edge Functions |
| Styling | FlexColorScheme | v8.0.2, Vibrant high-contrast theme |
| Environment | flutter_dotenv | v6.0.0 |

**Architecture Rules:**

1. **Auth:** Supabase Phone Auth (OTP). No email/password.
2. **Data Flow:** UI triggers Controller → Controller calls Repository → Repository updates Supabase → Supabase Realtime updates UI (Stream).
3. **Security:** RLS on every table. Policies reference `board_members`.
4. **AI Logic:** Merging logic lives in Supabase Edge Functions (TypeScript/Deno), NOT in the Flutter client.

---

## 5. 🗄 Database Schema

**Migration File:** `supabase/migrations/20260104_initial_schema.sql`

### Core Tables

| Table | Description |
|-------|-------------|
| `profiles` | User profiles linked to `auth.users` |
| `boards` | The collaborative groups/whiteboards |
| `board_members` | Join table for board membership & roles |
| `slaps` | The sticky notes on boards |

### Table Schemas

**profiles**
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK, References `auth.users` |
| `phone_number` | TEXT | Unique |
| `username` | TEXT | Optional display name |
| `avatar_url` | TEXT | Optional avatar |
| `updated_at` | TIMESTAMPTZ | Auto-updated |

**boards**
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK, Auto-generated |
| `name` | TEXT | Required |
| `created_by` | UUID | FK to `profiles.id` |
| `created_at` | TIMESTAMPTZ | Auto-set |

**board_members**
| Column | Type | Notes |
|--------|------|-------|
| `board_id` | UUID | FK to `boards.id`, CASCADE delete |
| `user_id` | UUID | FK to `profiles.id`, CASCADE delete |
| `role` | TEXT | `'admin'` or `'member'` |

**slaps** (The Sticky Notes)
| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID | PK, Auto-generated |
| `board_id` | UUID | FK to `boards.id`, CASCADE delete |
| `user_id` | UUID | FK to `profiles.id` |
| `content` | TEXT | Note content |
| `position_x` | DOUBLE PRECISION | X coordinate |
| `position_y` | DOUBLE PRECISION | Y coordinate |
| `color` | TEXT | Hex color (default: `FFFFE0`) |
| `is_processing` | BOOLEAN | Locks note during AI merge |
| `created_at` | TIMESTAMPTZ | Auto-set |

### Database Triggers

- **`on_board_created`:** Auto-adds board creator as admin to `board_members`
- **`on_auth_user_created`:** Auto-creates profile when user signs up

### Realtime

- `slaps` table is published to `supabase_realtime` for live updates

---

## 6. 🚀 Operational Requirements

### Database Migrations

**Rule:** ALWAYS push migrations to Supabase immediately after creating them.

```bash
# 1. Login to CLI (uses SUPABASE_ACCESS_TOKEN from .env)
npx supabase login

# 2. Link to project (one-time)
npx supabase link --project-ref spdqigbohimluzghlwjb

# 3. Apply migrations to Supabase:
npx supabase db push
```

### Pre-Flight Checklist (Before Every Change)

- [ ] Did I run `dart run build_runner build` to update Riverpod providers?
- [ ] Did I check the database schema for correct column names?
- [ ] Is the widget strictly listening to the specific Provider it needs?
- [ ] Did I handle the "Loading" and "Error" states of the `AsyncValue`?
- [ ] Did I check if the User is a member of the Board before allowing edits?

### Folder Structure (Feature-First)

```
lib/
├── main.dart                # Entry point (Supabase init)
├── core/
│   ├── env/                 # Environment variables (Env class)
│   ├── router/              # GoRouter config (router.dart)
│   └── theme/               # App theme (app_theme.dart)
├── features/
│   ├── auth/                # Phone Auth Logic
│   │   └── presentation/
│   │       └── screens/     # AuthScreen
│   ├── dashboard/           # Home Screen (List of Boards)
│   │   └── presentation/
│   │       └── screens/     # DashboardScreen
│   └── board/               # The Infinite Canvas
│       └── presentation/
│           ├── screens/     # BoardScreen
│           └── widgets/     # StickyNote, etc.
```

### Routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/` | `DashboardScreen` | Home - list of user's boards |
| `/auth` | `AuthScreen` | Phone OTP authentication |
| `/board/:id` | `BoardScreen` | Individual board canvas |

---

## 7. 🔑 Credentials Reference

> **STORED IN REPO:** All credentials are saved in `.env` and `CREDENTIALS.md` (tracked in git).

### All Credentials (Copy-Paste Ready)

```bash
# Supabase
SUPABASE_URL=https://spdqigbohimluzghlwjb.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZHFpZ2JvaGltbHV6Z2hsd2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1NDk5MjksImV4cCI6MjA4MzEyNTkyOX0.btfAPD8-mONxz9iyojuSJh1cEQe8qs0OBIYdtDaB-uY
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZHFpZ2JvaGltbHV6Z2hsd2piIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzU0OTkyOSwiZXhwIjoyMDgzMTI1OTI5fQ.jS-MMdxDh4oqa4eGpz_5EaXz_TyAtWMeA07cnqSCt1c
SUPABASE_ACCESS_TOKEN=sbp_5d419ed19ad03371a9b3521bf71a3a892d19e853
SUPABASE_DB_PASSWORD=Gold_1234!!*

# Google Cloud
GOOGLE_PROJECT_ID=slap-483318
GOOGLE_PROJECT_NUMBER=59472721706

# Twilio
TWILIO_ACCOUNT_SID=AC97d828342cd84882af121bc1edbd98c4
TWILIO_AUTH_TOKEN=7bd0e101d28578a6e0ba96cad6a86454
TWILIO_RECOVERY_CODE=RBZGB4AG7S65NEFVPMMH4E95

# OpenAI
OPENAI_API_KEY=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
```

| Key | Value |
|-----|-------|
| **Supabase Project Ref** | `spdqigbohimluzghlwjb` |
| **Supabase Region** | `us-west-2` (AWS) |
| **DB Host** | `db.spdqigbohimluzghlwjb.supabase.co` |
| **DB User** | `postgres` |
| **DB Port** | `5432` |
| **Google Cloud Project** | `slap-483318` |

### Environment Setup

```bash
# .env is tracked in git - no need to copy
# For CLI authentication:
export SUPABASE_ACCESS_TOKEN=sbp_5d419ed19ad03371a9b3521bf71a3a892d19e853
npx supabase link --project-ref spdqigbohimluzghlwjb
```

---

## 8. 🔒 Row Level Security (RLS) Summary

All tables have RLS enabled. Key policies:

| Table | Policy | Rule |
|-------|--------|------|
| `profiles` | View/Update own | `auth.uid() = id` |
| `boards` | View as member | User must be in `board_members` |
| `boards` | Create | `auth.uid() = created_by` |
| `boards` | Update/Delete | User must be admin in `board_members` |
| `board_members` | View | User must be member of same board |
| `board_members` | Manage | User must be admin |
| `slaps` | View/Create | User must be board member |
| `slaps` | Update/Delete | `auth.uid() = user_id` (own slaps only) |

---

## 9. 🔄 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter Client                          │
├─────────────────────────────────────────────────────────────────┤
│  UI Widget                                                      │
│     │                                                           │
│     ▼ ref.watch()                                               │
│  Riverpod Provider/Controller                                   │
│     │                                                           │
│     ▼ supabase.from('table')                                    │
│  Supabase Client (via global getter)                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Supabase Backend                           │
├─────────────────────────────────────────────────────────────────┤
│  PostgREST API ◄──► PostgreSQL (with RLS)                       │
│       │                                                         │
│       ▼                                                         │
│  Realtime Server ───► WebSocket to Client                       │
│       │                                                         │
│       ▼                                                         │
│  Edge Functions (AI Merge Logic)                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. 🔴 MANDATORY REQUIREMENTS (PERMANENT)

> **⚠️ CRITICAL: These requirements apply to ALL future development work. No exceptions.**

### 10.1 Real Data Only - NO MOCK DATA

- **NEVER** use mock/fake data, hardcoded test data, or placeholder values in production code
- **NEVER** bypass authentication for testing purposes
- **ALWAYS** connect to the real Supabase database (`spdqigbohimluzghlwjb`)
- **ALWAYS** use real-time subscriptions for live data updates
- **ALWAYS** persist data to the database - nothing stored only in local state

### 10.2 Full Functionality Required

- **ALL buttons must work** - no placeholder click handlers
- **ALL forms must save** - data must persist to database immediately
- **ALL screens must load real data** - fetch from Supabase, not hardcoded
- **ALL CRUD operations must be complete** - Create, Read, Update, Delete
- **ALL error states must be handled** - show user-friendly messages

### 10.3 Data Persistence Checklist

For EVERY feature, verify:
- [ ] Data saves to Supabase on user action
- [ ] Data loads from Supabase on screen open
- [ ] Real-time updates reflect across all clients
- [ ] Data persists after app restart
- [ ] Offline state is handled gracefully

### 10.4 Testing Protocol

Before marking any feature complete:
1. **Test auth flow** - Login with real phone number
2. **Test create** - Create new item, verify in database
3. **Test read** - Refresh screen, verify data loads
4. **Test update** - Modify item, verify change persists
5. **Test delete** - Remove item, verify removal
6. **Test real-time** - Open in two browsers, verify sync

### 10.5 Code Review Requirements

Every PR/commit must verify:
- No `TODO` or `FIXME` comments left in production code
- No commented-out code
- No mock data or test stubs
- All providers properly connected to repositories
- All repositories properly calling Supabase
- All error handling in place

---

**Last Updated:** January 5, 2026
