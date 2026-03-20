-- ============================================================
-- SLAPP (Story Layering And Production Platform) — Complete Database Schema
-- "Everything knows what everything else is."
-- ============================================================

-- ── Drop old tables (ground-up rebuild) ─────────────────────
DROP TABLE IF EXISTS slaps CASCADE;
DROP TABLE IF EXISTS board_members CASCADE;
DROP TABLE IF EXISTS boards CASCADE;

-- ── Profiles (Extend existing) ──────────────────────────────
-- profiles table already exists from initial migration; alter it
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS complexity_mode TEXT DEFAULT 'creator';

-- ── Projects ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  logline TEXT,
  genre TEXT,
  tone TEXT,
  target_format TEXT NOT NULL DEFAULT 'novel',
  canon_rules JSONB DEFAULT '[]'::jsonb,
  major_themes JSONB DEFAULT '[]'::jsonb,
  ending_state TEXT,
  style_config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ── Story Objects (The core of StoryOS) ─────────────────────
CREATE TABLE IF NOT EXISTS story_objects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  ai_summary TEXT,
  tags JSONB DEFAULT '[]'::jsonb,
  status TEXT DEFAULT 'draft',
  canon_state TEXT DEFAULT 'draft',
  visual_refs JSONB DEFAULT '[]'::jsonb,
  notes TEXT,
  first_appearance UUID, -- FK to scene story_object
  sort_order INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT valid_type CHECK (type IN (
    'character', 'place', 'scene', 'sequence', 'chapter', 'storyline',
    'item', 'faction', 'theme', 'relationship', 'secret', 'mystery',
    'clue', 'reveal', 'visual_moment', 'dialogue_fragment', 'lore_entry',
    'timeline_event', 'rule', 'unused_idea', 'alternate_version'
  )),
  CONSTRAINT valid_status CHECK (status IN ('draft', 'rough', 'good', 'polished', 'locked')),
  CONSTRAINT valid_canon CHECK (canon_state IN ('canonical', 'draft', 'alternate'))
);

-- ── Story Links (Object graph connections) ──────────────────
CREATE TABLE IF NOT EXISTS story_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  source_id UUID NOT NULL REFERENCES story_objects(id) ON DELETE CASCADE,
  target_id UUID NOT NULL REFERENCES story_objects(id) ON DELETE CASCADE,
  link_type TEXT NOT NULL,
  description TEXT,
  strength INTEGER DEFAULT 5,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT valid_link_type CHECK (link_type IN (
    'appears_in', 'located_at', 'knows', 'owns', 'caused_by', 'leads_to',
    'conflicts_with', 'depends_on', 'references', 'contains', 'part_of',
    'alternate_of', 'inspires', 'setup_for', 'payoff_of', 'related_to'
  )),
  CONSTRAINT valid_strength CHECK (strength >= 1 AND strength <= 10),
  CONSTRAINT no_self_link CHECK (source_id != target_id)
);

-- ── Story Tiles (Storyboard) ────────────────────────────────
CREATE TABLE IF NOT EXISTS story_tiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  scene_id UUID REFERENCES story_objects(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  beat_summary TEXT,
  image_url TEXT,
  characters_present JSONB DEFAULT '[]'::jsonb,
  location_id UUID REFERENCES story_objects(id) ON DELETE SET NULL,
  emotional_tone TEXT,
  mood_overlays JSONB DEFAULT '[]'::jsonb,
  tags JSONB DEFAULT '[]'::jsonb,
  lane TEXT DEFAULT 'main_plot',
  sequence_position INTEGER DEFAULT 0,
  version_status TEXT DEFAULT 'draft',
  tile_type TEXT DEFAULT 'beat',
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT valid_tile_type CHECK (tile_type IN (
    'beat', 'scene', 'visual_moment', 'reveal', 'memory', 'transition',
    'character_intro', 'mood_cluster', 'action_step', 'alternate'
  ))
);

-- ── Narrative Nodes (Big Picture Board positions) ───────────
CREATE TABLE IF NOT EXISTS narrative_nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  story_object_id UUID NOT NULL REFERENCES story_objects(id) ON DELETE CASCADE,
  node_type TEXT DEFAULT 'default',
  position_x DOUBLE PRECISION DEFAULT 0,
  position_y DOUBLE PRECISION DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Narrative Edges (Big Picture Board connections) ──────────
CREATE TABLE IF NOT EXISTS narrative_edges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  source_node_id UUID NOT NULL REFERENCES narrative_nodes(id) ON DELETE CASCADE,
  target_node_id UUID NOT NULL REFERENCES narrative_nodes(id) ON DELETE CASCADE,
  edge_type TEXT DEFAULT 'default',
  label TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── Continuity Flags (Story Intelligence) ───────────────────
CREATE TABLE IF NOT EXISTS continuity_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  flag_type TEXT NOT NULL,
  severity TEXT DEFAULT 'info',
  message TEXT NOT NULL,
  source_object_id UUID REFERENCES story_objects(id) ON DELETE CASCADE,
  target_object_id UUID REFERENCES story_objects(id) ON DELETE CASCADE,
  scene_id UUID REFERENCES story_objects(id) ON DELETE CASCADE,
  resolved BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  
  CONSTRAINT valid_flag_type CHECK (flag_type IN (
    'contradiction', 'missing_introduction', 'knowledge_error',
    'timeline_conflict', 'dropped_thread', 'repeated_beat',
    'pacing_issue', 'weak_causality', 'tone_drift',
    'missing_payoff', 'early_reveal', 'character_inconsistency'
  )),
  CONSTRAINT valid_severity CHECK (severity IN ('info', 'warning', 'error'))
);

-- ── Canon Locks ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS canon_locks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  rule TEXT NOT NULL,
  description TEXT,
  locked_by UUID REFERENCES story_objects(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ── AI Conversations (History) ──────────────────────────────
CREATE TABLE IF NOT EXISTS ai_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  specialist TEXT NOT NULL,
  context_object_ids JSONB DEFAULT '[]'::jsonb,
  messages JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ── Indexes ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_projects_user ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_story_objects_project ON story_objects(project_id);
CREATE INDEX IF NOT EXISTS idx_story_objects_type ON story_objects(project_id, type);
CREATE INDEX IF NOT EXISTS idx_story_links_project ON story_links(project_id);
CREATE INDEX IF NOT EXISTS idx_story_links_source ON story_links(source_id);
CREATE INDEX IF NOT EXISTS idx_story_links_target ON story_links(target_id);
CREATE INDEX IF NOT EXISTS idx_story_tiles_project ON story_tiles(project_id);
CREATE INDEX IF NOT EXISTS idx_story_tiles_lane ON story_tiles(project_id, lane);
CREATE INDEX IF NOT EXISTS idx_narrative_nodes_project ON narrative_nodes(project_id);
CREATE INDEX IF NOT EXISTS idx_continuity_flags_project ON continuity_flags(project_id);
CREATE INDEX IF NOT EXISTS idx_continuity_flags_unresolved ON continuity_flags(project_id, resolved) WHERE resolved = false;
CREATE INDEX IF NOT EXISTS idx_canon_locks_project ON canon_locks(project_id);

-- ── Row Level Security ──────────────────────────────────────

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_tiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE narrative_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE narrative_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE continuity_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE canon_locks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- Helper: get user's project IDs
CREATE OR REPLACE FUNCTION get_user_project_ids()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM projects WHERE user_id = auth.uid();
$$;

-- Projects policies
CREATE POLICY "Users can view their own projects"
  ON projects FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create projects"
  ON projects FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own projects"
  ON projects FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own projects"
  ON projects FOR DELETE
  USING (user_id = auth.uid());

-- Story Objects policies (via project ownership)
CREATE POLICY "Users can view story objects in their projects"
  ON story_objects FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can create story objects in their projects"
  ON story_objects FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can update story objects in their projects"
  ON story_objects FOR UPDATE
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can delete story objects in their projects"
  ON story_objects FOR DELETE
  USING (project_id IN (SELECT get_user_project_ids()));

-- Story Links policies
CREATE POLICY "Users can view links in their projects"
  ON story_links FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can manage links in their projects"
  ON story_links FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can delete links in their projects"
  ON story_links FOR DELETE
  USING (project_id IN (SELECT get_user_project_ids()));

-- Story Tiles policies
CREATE POLICY "Users can view tiles in their projects"
  ON story_tiles FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can manage tiles in their projects"
  ON story_tiles FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can update tiles in their projects"
  ON story_tiles FOR UPDATE
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can delete tiles in their projects"
  ON story_tiles FOR DELETE
  USING (project_id IN (SELECT get_user_project_ids()));

-- Narrative Nodes policies
CREATE POLICY "Users can view nodes in their projects"
  ON narrative_nodes FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can manage nodes in their projects"
  ON narrative_nodes FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can update nodes in their projects"
  ON narrative_nodes FOR UPDATE
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can delete nodes in their projects"
  ON narrative_nodes FOR DELETE
  USING (project_id IN (SELECT get_user_project_ids()));

-- Narrative Edges policies
CREATE POLICY "Users can view edges in their projects"
  ON narrative_edges FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can manage edges in their projects"
  ON narrative_edges FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can delete edges in their projects"
  ON narrative_edges FOR DELETE
  USING (project_id IN (SELECT get_user_project_ids()));

-- Continuity Flags policies
CREATE POLICY "Users can view flags in their projects"
  ON continuity_flags FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can manage flags in their projects"
  ON continuity_flags FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can update flags in their projects"
  ON continuity_flags FOR UPDATE
  USING (project_id IN (SELECT get_user_project_ids()));

-- Canon Locks policies
CREATE POLICY "Users can view canon locks in their projects"
  ON canon_locks FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can manage canon locks in their projects"
  ON canon_locks FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can delete canon locks in their projects"
  ON canon_locks FOR DELETE
  USING (project_id IN (SELECT get_user_project_ids()));

-- AI Conversations policies
CREATE POLICY "Users can view AI conversations in their projects"
  ON ai_conversations FOR SELECT
  USING (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can create AI conversations in their projects"
  ON ai_conversations FOR INSERT
  WITH CHECK (project_id IN (SELECT get_user_project_ids()));

CREATE POLICY "Users can update AI conversations in their projects"
  ON ai_conversations FOR UPDATE
  USING (project_id IN (SELECT get_user_project_ids()));

-- ── Enable Realtime ─────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE story_objects;
ALTER PUBLICATION supabase_realtime ADD TABLE story_tiles;
ALTER PUBLICATION supabase_realtime ADD TABLE continuity_flags;
ALTER PUBLICATION supabase_realtime ADD TABLE story_links;

-- ── Trigger: auto-update updated_at ─────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_story_objects_updated_at
  BEFORE UPDATE ON story_objects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_story_tiles_updated_at
  BEFORE UPDATE ON story_tiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_ai_conversations_updated_at
  BEFORE UPDATE ON ai_conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
