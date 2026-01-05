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

> ⚠️ **SECURITY:** All credentials are stored in `.env` (gitignored). Never commit secrets.

| Key | Purpose | Location |
|-----|---------|----------|
| `SUPABASE_URL` | API endpoint | `.env` |
| `SUPABASE_ANON_KEY` | Public client key | `.env` |
| `SUPABASE_SERVICE_ROLE_KEY` | Admin operations (server-side only) | `.env` |
| `SUPABASE_ACCESS_TOKEN` | CLI authentication | `.env` |
| `SUPABASE_DB_*` | Direct database connection | `.env` |
| `GOOGLE_PROJECT_ID` | GCP Project | `.env` |
| `GOOGLE_PROJECT_NUMBER` | GCP Project Number | `.env` |

**Supabase Project Reference:** `spdqigbohimluzghlwjb`  
**Supabase Region:** `us-west-2` (AWS)  
**Google Cloud Project:** `slap-483318`

### Environment Setup

```bash
# Copy example and fill in values
cp .env.example .env

# Required for Supabase CLI
export SUPABASE_ACCESS_TOKEN=$(grep SUPABASE_ACCESS_TOKEN .env | cut -d '=' -f2)
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

**Last Updated:** January 4, 2026
