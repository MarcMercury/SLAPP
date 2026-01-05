-- =============================================
-- FIX RLS POLICY RECURSION
-- Run this in Supabase SQL Editor
-- =============================================

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Members can view boards" ON public.boards;
DROP POLICY IF EXISTS "Board admins can update boards" ON public.boards;
DROP POLICY IF EXISTS "Board admins can delete boards" ON public.boards;
DROP POLICY IF EXISTS "Members can view board members" ON public.board_members;
DROP POLICY IF EXISTS "Board admins can manage members" ON public.board_members;
DROP POLICY IF EXISTS "Members can view slaps" ON public.slaps;
DROP POLICY IF EXISTS "Members can create slaps" ON public.slaps;

-- BOARDS: Fixed policies using EXISTS (no recursion)
CREATE POLICY "Members can view boards" ON public.boards
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.board_members 
      WHERE board_members.board_id = boards.id 
      AND board_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Board admins can update boards" ON public.boards
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.board_members 
      WHERE board_members.board_id = boards.id 
      AND board_members.user_id = auth.uid() 
      AND board_members.role = 'admin'
    )
  );

CREATE POLICY "Board admins can delete boards" ON public.boards
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.board_members 
      WHERE board_members.board_id = boards.id 
      AND board_members.user_id = auth.uid() 
      AND board_members.role = 'admin'
    )
  );

-- BOARD_MEMBERS: Fixed policies
CREATE POLICY "Members can view board members" ON public.board_members
  FOR SELECT USING (
    auth.uid() = user_id OR 
    EXISTS (
      SELECT 1 FROM public.board_members bm 
      WHERE bm.board_id = board_members.board_id 
      AND bm.user_id = auth.uid()
    )
  );

CREATE POLICY "Board creators can add first member" ON public.board_members
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.boards 
      WHERE boards.id = board_id 
      AND boards.created_by = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM public.board_members bm 
      WHERE bm.board_id = board_members.board_id 
      AND bm.user_id = auth.uid() 
      AND bm.role = 'admin'
    )
  );

CREATE POLICY "Board admins can update members" ON public.board_members
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.board_members bm 
      WHERE bm.board_id = board_members.board_id 
      AND bm.user_id = auth.uid() 
      AND bm.role = 'admin'
    )
  );

CREATE POLICY "Board admins can delete members" ON public.board_members
  FOR DELETE USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM public.board_members bm 
      WHERE bm.board_id = board_members.board_id 
      AND bm.user_id = auth.uid() 
      AND bm.role = 'admin'
    )
  );

-- SLAPS: Fixed policies
CREATE POLICY "Members can view slaps" ON public.slaps
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.board_members 
      WHERE board_members.board_id = slaps.board_id 
      AND board_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Members can create slaps" ON public.slaps
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.board_members 
      WHERE board_members.board_id = slaps.board_id 
      AND board_members.user_id = auth.uid()
    )
  );
