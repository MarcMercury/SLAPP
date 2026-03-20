import { createClient } from "@/lib/supabase/client";
import type {
  Project,
  StoryObject,
  StoryTile,
  StoryLink,
  ContinuityFlag,
} from "@/lib/types";

const supabase = createClient();

// ── Projects ────────────────────────────────────────────────

export async function getProjects(): Promise<Project[]> {
  const { data, error } = await supabase
    .from("projects")
    .select("*")
    .order("updated_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function getProject(id: string): Promise<Project | null> {
  const { data, error } = await supabase
    .from("projects")
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw error;
  return data;
}

export async function createProject(
  project: Partial<Project>
): Promise<Project> {
  const { data: userData } = await supabase.auth.getUser();
  const { data, error } = await supabase
    .from("projects")
    .insert({ ...project, user_id: userData.user!.id })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateProject(
  id: string,
  updates: Partial<Project>
): Promise<Project> {
  const { data, error } = await supabase
    .from("projects")
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteProject(id: string): Promise<void> {
  const { error } = await supabase.from("projects").delete().eq("id", id);
  if (error) throw error;
}

// ── Story Objects ───────────────────────────────────────────

export async function getStoryObjects(
  projectId: string
): Promise<StoryObject[]> {
  const { data, error } = await supabase
    .from("story_objects")
    .select("*")
    .eq("project_id", projectId)
    .order("sort_order", { ascending: true });
  if (error) throw error;
  return data ?? [];
}

export async function getStoryObjectsByType(
  projectId: string,
  type: string
): Promise<StoryObject[]> {
  const { data, error } = await supabase
    .from("story_objects")
    .select("*")
    .eq("project_id", projectId)
    .eq("type", type)
    .order("sort_order", { ascending: true });
  if (error) throw error;
  return data ?? [];
}

export async function getStoryObject(
  id: string
): Promise<StoryObject | null> {
  const { data, error } = await supabase
    .from("story_objects")
    .select("*")
    .eq("id", id)
    .single();
  if (error) throw error;
  return data;
}

export async function createStoryObject(
  object: Partial<StoryObject>
): Promise<StoryObject> {
  const { data, error } = await supabase
    .from("story_objects")
    .insert(object)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateStoryObject(
  id: string,
  updates: Partial<StoryObject>
): Promise<StoryObject> {
  const { data, error } = await supabase
    .from("story_objects")
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteStoryObject(id: string): Promise<void> {
  const { error } = await supabase
    .from("story_objects")
    .delete()
    .eq("id", id);
  if (error) throw error;
}

// ── Story Links ─────────────────────────────────────────────

export async function getStoryLinks(
  projectId: string
): Promise<StoryLink[]> {
  const { data, error } = await supabase
    .from("story_links")
    .select("*")
    .eq("project_id", projectId);
  if (error) throw error;
  return data ?? [];
}

export async function createStoryLink(
  link: Partial<StoryLink>
): Promise<StoryLink> {
  const { data, error } = await supabase
    .from("story_links")
    .insert(link)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteStoryLink(id: string): Promise<void> {
  const { error } = await supabase.from("story_links").delete().eq("id", id);
  if (error) throw error;
}

// ── Story Tiles (Storyboard) ────────────────────────────────

export async function getStoryTiles(
  projectId: string
): Promise<StoryTile[]> {
  const { data, error } = await supabase
    .from("story_tiles")
    .select("*")
    .eq("project_id", projectId)
    .order("sequence_position", { ascending: true });
  if (error) throw error;
  return data ?? [];
}

export async function createStoryTile(
  tile: Partial<StoryTile>
): Promise<StoryTile> {
  const { data, error } = await supabase
    .from("story_tiles")
    .insert(tile)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function updateStoryTile(
  id: string,
  updates: Partial<StoryTile>
): Promise<StoryTile> {
  const { data, error } = await supabase
    .from("story_tiles")
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteStoryTile(id: string): Promise<void> {
  const { error } = await supabase
    .from("story_tiles")
    .delete()
    .eq("id", id);
  if (error) throw error;
}

export async function reorderTiles(
  tiles: { id: string; sequence_position: number }[]
): Promise<void> {
  // Update each tile's position
  for (const tile of tiles) {
    const { error } = await supabase
      .from("story_tiles")
      .update({ sequence_position: tile.sequence_position })
      .eq("id", tile.id);
    if (error) throw error;
  }
}

// ── Continuity Flags ────────────────────────────────────────

export async function getContinuityFlags(
  projectId: string
): Promise<ContinuityFlag[]> {
  const { data, error } = await supabase
    .from("continuity_flags")
    .select("*")
    .eq("project_id", projectId)
    .order("created_at", { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function resolveContinuityFlag(id: string): Promise<void> {
  const { error } = await supabase
    .from("continuity_flags")
    .update({ resolved: true })
    .eq("id", id);
  if (error) throw error;
}

// ── Realtime subscriptions ──────────────────────────────────

export function subscribeToProject(
  projectId: string,
  callbacks: {
    onObjectChange?: (payload: unknown) => void;
    onTileChange?: (payload: unknown) => void;
    onFlagChange?: (payload: unknown) => void;
  }
) {
  const channel = supabase
    .channel(`project-${projectId}`)
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "story_objects",
        filter: `project_id=eq.${projectId}`,
      },
      (payload) => callbacks.onObjectChange?.(payload)
    )
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "story_tiles",
        filter: `project_id=eq.${projectId}`,
      },
      (payload) => callbacks.onTileChange?.(payload)
    )
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "continuity_flags",
        filter: `project_id=eq.${projectId}`,
      },
      (payload) => callbacks.onFlagChange?.(payload)
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}
