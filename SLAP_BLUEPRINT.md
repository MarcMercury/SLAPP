# SLAP: Project Blueprint & Master Context

## 1. Project Context
**App Name:** SLAP (The Big Board)  
**Package:** `fun.slapp`  
**Domain:** Collaborative Ideation ("WhatsApp for Sticky Notes")  
**Platform:** Flutter (Mobile + Web)  
**Backend:** Supabase  
**Hosting:** GitHub Codespaces

## 2. 🔑 ALL CREDENTIALS (MASTER REFERENCE)

> **NOTE:** All credentials are stored in `.env` AND `CREDENTIALS.md` in repo for easy reference.

### Supabase
| Key | Value |
|-----|-------|
| **URL** | `https://spdqigbohimluzghlwjb.supabase.co` |
| **Project Ref** | `spdqigbohimluzghlwjb` |
| **Region** | `us-west-2` (AWS) |
| **Anon Key** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZHFpZ2JvaGltbHV6Z2hsd2piIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1NDk5MjksImV4cCI6MjA4MzEyNTkyOX0.btfAPD8-mONxz9iyojuSJh1cEQe8qs0OBIYdtDaB-uY` |
| **Service Role Key** | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNwZHFpZ2JvaGltbHV6Z2hsd2piIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NzU0OTkyOSwiZXhwIjoyMDgzMTI1OTI5fQ.jS-MMdxDh4oqa4eGpz_5EaXz_TyAtWMeA07cnqSCt1c` |
| **Access Token (CLI)** | `sbp_5d419ed19ad03371a9b3521bf71a3a892d19e853` |
| **DB Password** | `Gold_1234!!*` |
| **DB Host** | `db.spdqigbohimluzghlwjb.supabase.co` |
| **DB User** | `postgres` |
| **DB Port** | `5432` |

### Google Cloud
| Key | Value |
|-----|-------|
| **Project ID** | `slap-483318` |
| **Project Number** | `59472721706` |

### Twilio
| Key | Value |
|-----|-------|
| **Account SID** | `AC97d828342cd84882af121bc1edbd98c4` |
| **Auth Token** | `7bd0e101d28578a6e0ba96cad6a86454` |
| **Recovery Code** | `RBZGB4AG7S65NEFVPMMH4E95` |
| **Phone Number** | `+12517664644` |
| **Messaging Service SID** | `MGb2820566a88a85e3577299463b6d5324` |
| **A2P Brand SID** | `BN9a5ffe926bb699215l2991ea06e8d20b` |
| **A2P Campaign SID** | `CMb7c3273a657c4fdc3af38378dcfd0a78` |
| **A2P Status** | ⏳ Pending Vetting (Jan 7, 2026) |

### OpenAI
| Key | Value |
|-----|-------|
| **API Key** | `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` |

### CLI Setup
```bash
export SUPABASE_ACCESS_TOKEN=sbp_5d419ed19ad03371a9b3521bf71a3a892d19e853
supabase link --project-ref spdqigbohimluzghlwjb
```

## 3. Tech Stack
| Category | Technology |
|----------|------------|
| Framework | Flutter (Latest Stable) |
| Language | Dart |
| State Management | Riverpod (Annotation/Generator) |
| Routing | GoRouter |
| Backend SDK | `supabase_flutter` |
| Environment | `flutter_dotenv` |
| Theming | `flex_color_scheme` |
| Fonts | `google_fonts` |

## 4. Database Schema (PostgreSQL)

**Run these SQL migrations in Supabase SQL Editor:**

```sql
-- =============================================
-- SLAP DATABASE MIGRATIONS
-- Run this in your Supabase SQL Editor
-- =============================================

-- 1. PROFILES (Linked to Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users NOT NULL PRIMARY KEY,
  phone_number TEXT UNIQUE,
  username TEXT,
  avatar_url TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BOARDS (The Groups)
CREATE TABLE IF NOT EXISTS public.boards (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. BOARD_MEMBERS (Security)
CREATE TABLE IF NOT EXISTS public.board_members (
  board_id UUID REFERENCES public.boards(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'admin' or 'member'
  PRIMARY KEY (board_id, user_id)
);

-- 4. SLAPS (Sticky Notes)
CREATE TABLE IF NOT EXISTS public.slaps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  board_id UUID REFERENCES public.boards(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id),
  content TEXT,
  position_x DOUBLE PRECISION DEFAULT 0,
  position_y DOUBLE PRECISION DEFAULT 0,
  color TEXT DEFAULT 'FFFFE0', -- Hex color
  is_processing BOOLEAN DEFAULT FALSE, -- For AI merging
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.boards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slaps ENABLE ROW LEVEL SECURITY;

-- =============================================
-- POLICIES
-- =============================================

-- PROFILES: Users can view and update their own profile
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- BOARDS: Users can only see boards they are members of
CREATE POLICY "Members can view boards" ON public.boards
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.board_members WHERE board_id = id
    )
  );

CREATE POLICY "Authenticated users can create boards" ON public.boards
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Board admins can update boards" ON public.boards
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM public.board_members 
      WHERE board_id = id AND role = 'admin'
    )
  );

CREATE POLICY "Board admins can delete boards" ON public.boards
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.board_members 
      WHERE board_id = id AND role = 'admin'
    )
  );

-- BOARD_MEMBERS: View members of boards you belong to
CREATE POLICY "Members can view board members" ON public.board_members
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.board_members bm WHERE bm.board_id = board_id
    )
  );

CREATE POLICY "Board admins can manage members" ON public.board_members
  FOR ALL USING (
    auth.uid() IN (
      SELECT user_id FROM public.board_members bm 
      WHERE bm.board_id = board_id AND bm.role = 'admin'
    )
  );

-- SLAPS: Members can manage slaps on their boards
CREATE POLICY "Members can view slaps" ON public.slaps
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.board_members WHERE board_id = slaps.board_id
    )
  );

CREATE POLICY "Members can create slaps" ON public.slaps
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.board_members WHERE board_id = slaps.board_id
    )
  );

CREATE POLICY "Users can update own slaps" ON public.slaps
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own slaps" ON public.slaps
  FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- Function to automatically add board creator as admin
CREATE OR REPLACE FUNCTION public.handle_new_board()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.board_members (board_id, user_id, role)
  VALUES (NEW.id, NEW.created_by, 'admin');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to run after board creation
DROP TRIGGER IF EXISTS on_board_created ON public.boards;
CREATE TRIGGER on_board_created
  AFTER INSERT ON public.boards
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_board();

-- Function to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, phone_number)
  VALUES (NEW.id, NEW.phone);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================
-- REALTIME
-- =============================================

-- Enable realtime for slaps table
ALTER PUBLICATION supabase_realtime ADD TABLE public.slaps;
```

## 5. Folder Structure (Feature-First)

```
lib/
├── main.dart                    # Entry point (Initialize Supabase with Anon Key)
├── core/
│   ├── env/
│   │   └── env.dart             # Env variable loader
│   ├── router/
│   │   └── router.dart          # GoRouter config
│   ├── theme/
│   │   └── app_theme.dart       # App theme with FlexColorScheme
│   └── utils/
│       └── constants.dart       # App constants
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── screens/
│   │           └── auth_screen.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       └── screens/
│   │           └── dashboard_screen.dart
│   └── board/
│       └── presentation/
│           ├── screens/
│           │   └── board_screen.dart
│           └── widgets/
│               └── sticky_note.dart
```

## 6. Commands Reference

### Development
```bash
# Run code generation (Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
flutter pub run build_runner watch --delete-conflicting-outputs

# Run the app
flutter run -d chrome  # Web
flutter run            # Mobile emulator
```

### Production
```bash
# Build for web
flutter build web

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

## 7. Next Steps

1. **Run SQL Migrations:** Copy the SQL from Section 4 and run it in your Supabase SQL Editor
2. **Enable Phone Auth:** In Supabase Dashboard → Authentication → Providers → Phone
3. **Run Code Generation:** `flutter pub run build_runner build`
4. **Start Development:** `flutter run`

## 8. Key Features to Implement

- [ ] Phone authentication with OTP
- [ ] Real-time board synchronization
- [ ] Drag & drop sticky notes
- [ ] Board member invitations
- [ ] AI-powered note merging
- [ ] Offline support
