-- =============================================
-- FIX RLS POLICIES - Avoid Recursion Issues
-- =============================================
-- This migration fixes RLS policies to avoid recursive subquery issues
-- while maintaining proper security

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Members can view boards" ON public.boards;
DROP POLICY IF EXISTS "Authenticated users can create boards" ON public.boards;
DROP POLICY IF EXISTS "Board admins can update boards" ON public.boards;
DROP POLICY IF EXISTS "Board admins can delete boards" ON public.boards;
DROP POLICY IF EXISTS "Members can view board members" ON public.board_members;
DROP POLICY IF EXISTS "Board creators can add first member" ON public.board_members;
DROP POLICY IF EXISTS "Board admins can update members" ON public.board_members;
DROP POLICY IF EXISTS "Board admins can delete members" ON public.board_members;
DROP POLICY IF EXISTS "Members can view slaps" ON public.slaps;
DROP POLICY IF EXISTS "Members can create slaps" ON public.slaps;
DROP POLICY IF EXISTS "Users can update own slaps" ON public.slaps;
DROP POLICY IF EXISTS "Users can delete own slaps" ON public.slaps;

-- Re-enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.boards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slaps ENABLE ROW LEVEL SECURITY;

-- =============================================
-- SECURITY DEFINER FUNCTIONS (Avoid RLS recursion)
-- =============================================

-- Function to check if user is a board member (bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_board_member(board_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_id = board_uuid AND user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Function to check if user is a board admin (bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_board_admin(board_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.board_members
    WHERE board_id = board_uuid AND user_id = user_uuid AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Function to check if user created the board (bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_board_creator(board_uuid UUID, user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.boards
    WHERE id = board_uuid AND created_by = user_uuid
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Function to get user's board IDs (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_user_board_ids(user_uuid UUID)
RETURNS SETOF UUID AS $$
BEGIN
  RETURN QUERY SELECT board_id FROM public.board_members WHERE user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- =============================================
-- PROFILES POLICIES
-- =============================================

-- Users can view their own profile
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Users can view profiles of people in their boards (for member lists)
CREATE POLICY "profiles_select_board_members" ON public.profiles
  FOR SELECT USING (
    id IN (
      SELECT bm.user_id FROM public.board_members bm
      WHERE bm.board_id IN (SELECT public.get_user_board_ids(auth.uid()))
    )
  );

-- Users can insert their own profile
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- =============================================
-- BOARDS POLICIES
-- =============================================

-- Users can view boards they are members of (using SECURITY DEFINER function)
CREATE POLICY "boards_select_member" ON public.boards
  FOR SELECT USING (public.is_board_member(id, auth.uid()));

-- Authenticated users can create boards
CREATE POLICY "boards_insert_authenticated" ON public.boards
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND 
    auth.uid() = created_by
  );

-- Board admins can update their boards
CREATE POLICY "boards_update_admin" ON public.boards
  FOR UPDATE USING (public.is_board_admin(id, auth.uid()));

-- Board admins can delete their boards  
CREATE POLICY "boards_delete_admin" ON public.boards
  FOR DELETE USING (public.is_board_admin(id, auth.uid()));

-- =============================================
-- BOARD_MEMBERS POLICIES
-- =============================================

-- Users can see their own memberships
CREATE POLICY "board_members_select_own" ON public.board_members
  FOR SELECT USING (user_id = auth.uid());

-- Users can see other members of boards they belong to
CREATE POLICY "board_members_select_same_board" ON public.board_members
  FOR SELECT USING (public.is_board_member(board_id, auth.uid()));

-- Board admins and creators can add members
CREATE POLICY "board_members_insert" ON public.board_members
  FOR INSERT WITH CHECK (
    -- User adding themselves (for new board creation trigger)
    user_id = auth.uid() OR
    -- Board creator can add anyone
    public.is_board_creator(board_id, auth.uid()) OR
    -- Board admin can add anyone
    public.is_board_admin(board_id, auth.uid())
  );

-- Board admins can update member roles
CREATE POLICY "board_members_update_admin" ON public.board_members
  FOR UPDATE USING (public.is_board_admin(board_id, auth.uid()));

-- Users can remove themselves, or admins can remove others
CREATE POLICY "board_members_delete" ON public.board_members
  FOR DELETE USING (
    user_id = auth.uid() OR
    public.is_board_admin(board_id, auth.uid())
  );

-- =============================================
-- SLAPS POLICIES
-- =============================================

-- Board members can view slaps on their boards
CREATE POLICY "slaps_select_member" ON public.slaps
  FOR SELECT USING (public.is_board_member(board_id, auth.uid()));

-- Board members can create slaps
CREATE POLICY "slaps_insert_member" ON public.slaps
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    public.is_board_member(board_id, auth.uid())
  );

-- Board members can update any slap on their boards (for AI merge, position updates)
CREATE POLICY "slaps_update_member" ON public.slaps
  FOR UPDATE USING (public.is_board_member(board_id, auth.uid()));

-- Board members can delete any slap on their boards (for merge cleanup)
CREATE POLICY "slaps_delete_member" ON public.slaps
  FOR DELETE USING (public.is_board_member(board_id, auth.uid()));

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Index for faster board member lookups
CREATE INDEX IF NOT EXISTS idx_board_members_user_id ON public.board_members(user_id);
CREATE INDEX IF NOT EXISTS idx_board_members_board_id ON public.board_members(board_id);
CREATE INDEX IF NOT EXISTS idx_board_members_role ON public.board_members(role);

-- Index for faster slaps queries
CREATE INDEX IF NOT EXISTS idx_slaps_board_id ON public.slaps(board_id);
CREATE INDEX IF NOT EXISTS idx_slaps_user_id ON public.slaps(user_id);
CREATE INDEX IF NOT EXISTS idx_slaps_created_at ON public.slaps(created_at);

-- Index for faster board queries
CREATE INDEX IF NOT EXISTS idx_boards_created_by ON public.boards(created_by);

-- =============================================
-- REALTIME CONFIGURATION
-- =============================================

-- Make sure realtime is enabled for slaps (for live updates)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'slaps'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.slaps;
  END IF;
END $$;

-- Enable realtime for boards (for live updates when board name changes)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'boards'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.boards;
  END IF;
END $$;

-- Enable realtime for board_members (for member updates)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'board_members'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.board_members;
  END IF;
END $$;

-- =============================================
-- DATA INTEGRITY CONSTRAINTS
-- =============================================

-- Ensure color is a valid hex code (6 characters)
ALTER TABLE public.slaps DROP CONSTRAINT IF EXISTS slaps_color_format;
ALTER TABLE public.slaps ADD CONSTRAINT slaps_color_format 
  CHECK (color ~ '^[A-Fa-f0-9]{6}$');

-- Ensure board names are not empty
ALTER TABLE public.boards DROP CONSTRAINT IF EXISTS boards_name_not_empty;
ALTER TABLE public.boards ADD CONSTRAINT boards_name_not_empty 
  CHECK (length(trim(name)) > 0);

-- Ensure role is valid
ALTER TABLE public.board_members DROP CONSTRAINT IF EXISTS board_members_valid_role;
ALTER TABLE public.board_members ADD CONSTRAINT board_members_valid_role 
  CHECK (role IN ('admin', 'member'));

-- =============================================
-- UPDATED_AT TRIGGER
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at column to slaps if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'slaps' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.slaps ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- Trigger for slaps updated_at
DROP TRIGGER IF EXISTS update_slaps_updated_at ON public.slaps;
CREATE TRIGGER update_slaps_updated_at
  BEFORE UPDATE ON public.slaps
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger for profiles updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Add updated_at to boards if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'boards' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE public.boards ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- Trigger for boards updated_at
DROP TRIGGER IF EXISTS update_boards_updated_at ON public.boards;
CREATE TRIGGER update_boards_updated_at
  BEFORE UPDATE ON public.boards
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
