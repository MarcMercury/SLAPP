// ============================================================
// SLAPP — Story Layering And Production Platform
// Core Type Definitions
// Everything is a Story Object. Everything knows everything.
// ============================================================

// ── Story Object Types ──────────────────────────────────────

export type StoryObjectType =
  | "character"
  | "place"
  | "scene"
  | "sequence"
  | "chapter"
  | "storyline"
  | "item"
  | "faction"
  | "theme"
  | "relationship"
  | "secret"
  | "mystery"
  | "clue"
  | "reveal"
  | "visual_moment"
  | "dialogue_fragment"
  | "lore_entry"
  | "timeline_event"
  | "rule"
  | "unused_idea"
  | "alternate_version";

export type ObjectStatus = "draft" | "rough" | "good" | "polished" | "locked";
export type CanonState = "canonical" | "draft" | "alternate";

// ── Base Story Object ───────────────────────────────────────

export interface StoryObject {
  id: string;
  project_id: string;
  type: StoryObjectType;
  name: string;
  description: string | null;
  ai_summary: string | null;
  tags: string[];
  status: ObjectStatus;
  canon_state: CanonState;
  visual_refs: string[];
  notes: string | null;
  first_appearance: string | null; // scene ID
  sort_order: number;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

// ── Project ─────────────────────────────────────────────────

export interface Project {
  id: string;
  user_id: string;
  title: string;
  logline: string | null;
  genre: string | null;
  tone: string | null;
  target_format: TargetFormat;
  canon_rules: string[];
  major_themes: string[];
  ending_state: string | null;
  style_config: StyleConfig;
  created_at: string;
  updated_at: string;
}

export type TargetFormat =
  | "novel"
  | "screenplay"
  | "comic"
  | "series"
  | "game"
  | "mixed";

export interface StyleConfig {
  prose_style?: string;
  tone?: string;
  pacing?: string;
  voice_inspirations?: string[];
  genre_balance?: string;
  description_level?: string;
  dialogue_density?: string;
  humor_level?: string;
  cinematic_vs_literary?: string;
}

// ── Character ───────────────────────────────────────────────

export interface CharacterData {
  aliases: string[];
  age: string | null;
  voice: string | null;
  archetype: string | null;
  role_in_story: string | null;
  physical_description: string | null;
  emotional_profile: string | null;
  internal_contradiction: string | null;
  external_goal: string | null;
  secret: string | null;
  fear: string | null;
  flaw: string | null;
  relationship_anchors: string[];
  // Behavior engine
  speech_patterns: string | null;
  knowledge_state: string[];
  stress_reactions: string | null;
  never_would: string | null;
  change_triggers: string | null;
  // Living updates
  locations_visited: string[];
  lessons_learned: string[];
  people_met: string[];
  injuries: string[];
  promises_made: string[];
  inventory: string[];
  transformations: string[];
}

// ── Place ───────────────────────────────────────────────────

export interface PlaceData {
  sensory_profile: string | null;
  mood: string | null;
  rules: string | null;
  people_tied: string[];
  events: string[];
  map_connections: string[];
  story_importance: string | null;
  symbols: string[];
  timeline_states: PlaceTimelineState[];
}

export interface PlaceTimelineState {
  label: string;
  description: string;
  scene_id: string | null;
}

// ── Scene ───────────────────────────────────────────────────

export interface SceneData {
  purpose: string | null;
  pov: string | null;
  location_id: string | null;
  time: string | null;
  characters_present: string[];
  emotional_turn: string | null;
  conflict_type: string | null;
  information_revealed: string[];
  questions_raised: string[];
  setups_introduced: string[];
  payoffs_delivered: string[];
  objects_introduced: string[];
  image_tiles: string[];
  dependencies: string[];
  consequences: string[];
  content: string; // Rich text content (TipTap JSON)
  word_count: number;
}

// ── Story Object Links ──────────────────────────────────────

export type LinkType =
  | "appears_in"
  | "located_at"
  | "knows"
  | "owns"
  | "caused_by"
  | "leads_to"
  | "conflicts_with"
  | "depends_on"
  | "references"
  | "contains"
  | "part_of"
  | "alternate_of"
  | "inspires"
  | "setup_for"
  | "payoff_of"
  | "related_to";

export interface StoryLink {
  id: string;
  project_id: string;
  source_id: string;
  target_id: string;
  link_type: LinkType;
  description: string | null;
  strength: number; // 1-10
  created_at: string;
}

// ── Storyboard ──────────────────────────────────────────────

export interface StoryTile {
  id: string;
  project_id: string;
  scene_id: string | null;
  title: string;
  beat_summary: string | null;
  image_url: string | null;
  characters_present: string[];
  location_id: string | null;
  emotional_tone: string | null;
  mood_overlays: MoodOverlay[];
  tags: string[];
  lane: string;
  sequence_position: number;
  version_status: ObjectStatus;
  tile_type: TileType;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export type TileType =
  | "beat"
  | "scene"
  | "visual_moment"
  | "reveal"
  | "memory"
  | "transition"
  | "character_intro"
  | "mood_cluster"
  | "action_step"
  | "alternate";

export type MoodOverlay =
  | "noir"
  | "dreamlike"
  | "holy"
  | "grotesque"
  | "romantic"
  | "decayed"
  | "kinetic"
  | "mythic"
  | "tense"
  | "wonder"
  | "dread";

export type StoryboardLane =
  | "main_plot"
  | "character_arc"
  | "romance"
  | "mystery"
  | "villain"
  | "flashback"
  | "world_lore"
  | "comic_relief"
  | "symbolic";

// ── Big Picture Board ───────────────────────────────────────

export interface NarrativeNode {
  id: string;
  project_id: string;
  story_object_id: string;
  node_type: string;
  position_x: number;
  position_y: number;
  metadata: Record<string, unknown>;
}

export interface NarrativeEdge {
  id: string;
  source_node_id: string;
  target_node_id: string;
  edge_type: string;
  label: string | null;
}

// ── Continuity & Intelligence ───────────────────────────────

export interface ContinuityFlag {
  id: string;
  project_id: string;
  flag_type: ContinuityFlagType;
  severity: "info" | "warning" | "error";
  message: string;
  source_object_id: string | null;
  target_object_id: string | null;
  scene_id: string | null;
  resolved: boolean;
  created_at: string;
}

export type ContinuityFlagType =
  | "contradiction"
  | "missing_introduction"
  | "knowledge_error"
  | "timeline_conflict"
  | "dropped_thread"
  | "repeated_beat"
  | "pacing_issue"
  | "weak_causality"
  | "tone_drift"
  | "missing_payoff"
  | "early_reveal"
  | "character_inconsistency";

// ── AI Specialist Modes ─────────────────────────────────────

export type AISpecialist =
  | "architect"
  | "psychologist"
  | "continuity"
  | "visual_director"
  | "worldbuilder"
  | "dialogue_coach"
  | "genre_guide"
  | "dev_editor";

export interface AIRequest {
  specialist: AISpecialist;
  context: {
    project_id: string;
    scene_id?: string;
    object_ids?: string[];
    selection?: string;
    instruction: string;
  };
}

// ── User Profile ────────────────────────────────────────────

export interface Profile {
  id: string;
  email: string | null;
  username: string | null;
  avatar_url: string | null;
  complexity_mode: ComplexityMode;
  created_at: string;
  updated_at: string;
}

export type ComplexityMode = "simple" | "creator" | "studio";

// ── SLAPP Merge ─────────────────────────────────────────────

export type MergeMode =
  | "combine_visual"
  | "combine_narrative"
  | "alternate_version"
  | "fuse_settings"
  | "merge_emotions"
  | "hybrid_scene"
  | "branching_options";

export interface SlappMergeRequest {
  source_id: string;
  target_id: string;
  merge_mode: MergeMode;
  project_id: string;
}

export interface SlappMergeResult {
  merged_tile: Partial<StoryTile>;
  merged_summary: string;
  scene_draft: string | null;
  continuity_implications: string[];
  arc_impact: string[];
}

// ── Story Health ────────────────────────────────────────────

export interface StoryHealth {
  continuity_score: number;
  pacing_score: number;
  character_coherence: number;
  theme_consistency: number;
  unresolved_threads: number;
  weak_scenes: number;
  exposition_overload: number;
  underused_assets: number;
}
