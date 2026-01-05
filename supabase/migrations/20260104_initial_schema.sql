-- =============================================
-- SLAP DATABASE MIGRATIONS
-- Initial Schema Setup
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
