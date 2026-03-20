"use client";

import { Suspense, useEffect, useState, useCallback } from "react";
import { useSearchParams } from "next/navigation";
import { useProjectStore, useStoryboardStore } from "@/lib/stores";
import {
  getProject,
  getStoryTiles,
  createStoryTile,
  updateStoryTile,
  deleteStoryTile,
  reorderTiles,
} from "@/lib/db";
import type { StoryTile, StoryboardLane, MergeMode } from "@/lib/types";
import { TileCard } from "@/components/storyboard/TileCard";
import { TileEditor } from "@/components/storyboard/TileEditor";
import { cn } from "@/lib/utils";
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  DragOverlay,
  type DragStartEvent,
  type DragEndEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  sortableKeyboardCoordinates,
  rectSortingStrategy,
} from "@dnd-kit/sortable";
import {
  Plus,
  Loader2,
  Layers,
  Grid3X3,
  Film,
  LayoutGrid,
  Image as ImageIcon,
  Zap,
  Filter,
} from "lucide-react";

const LANE_LABELS: Record<string, { label: string; color: string }> = {
  main_plot: { label: "Main Plot", color: "bg-blue-500" },
  character_arc: { label: "Character Arc", color: "bg-emerald-500" },
  romance: { label: "Romance", color: "bg-rose-500" },
  mystery: { label: "Mystery", color: "bg-purple-500" },
  villain: { label: "Villain", color: "bg-red-600" },
  flashback: { label: "Flashback", color: "bg-amber-500" },
  world_lore: { label: "World Lore", color: "bg-indigo-500" },
  comic_relief: { label: "Comic Relief", color: "bg-yellow-500" },
  symbolic: { label: "Symbolic", color: "bg-cyan-500" },
};

const VIEW_MODES = [
  { id: "beat" as const, label: "Beat", icon: <Grid3X3 className="w-3.5 h-3.5" /> },
  { id: "cinematic" as const, label: "Cinematic", icon: <Film className="w-3.5 h-3.5" /> },
  { id: "moodboard" as const, label: "Moodboard", icon: <ImageIcon className="w-3.5 h-3.5" /> },
  { id: "structure" as const, label: "Structure", icon: <Layers className="w-3.5 h-3.5" /> },
];

export default function StoryboardPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full"><div className="w-8 h-8 border-2 border-slapp-orange border-t-transparent rounded-full animate-spin" /></div>}>
      <StoryboardInner />
    </Suspense>
  );
}

function StoryboardInner() {
  const searchParams = useSearchParams();
  const projectId = searchParams.get("project");
  const { currentProject, setCurrentProject } = useProjectStore();
  const { tiles, setTiles, viewMode, setViewMode, activeLane, setActiveLane } =
    useStoryboardStore();

  const [loading, setLoading] = useState(true);
  const [editingTile, setEditingTile] = useState<StoryTile | null>(null);
  const [activeDragId, setActiveDragId] = useState<string | null>(null);
  const [showMergeModal, setShowMergeModal] = useState(false);
  const [mergeSource, setMergeSource] = useState<StoryTile | null>(null);
  const [mergeTarget, setMergeTarget] = useState<StoryTile | null>(null);
  const [merging, setMerging] = useState(false);
  const [filterLane, setFilterLane] = useState<string | "all">("all");

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 8 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  );

  useEffect(() => {
    if (projectId) loadData(projectId);
  }, [projectId]);

  async function loadData(id: string) {
    setLoading(true);
    try {
      const [project, tileData] = await Promise.all([
        getProject(id),
        getStoryTiles(id),
      ]);
      if (project) setCurrentProject(project);
      setTiles(tileData);
    } catch (err) {
      console.error("Failed to load storyboard:", err);
    } finally {
      setLoading(false);
    }
  }

  async function handleCreateTile() {
    if (!projectId) return;
    try {
      const tile = await createStoryTile({
        project_id: projectId,
        title: "New Beat",
        lane: filterLane === "all" ? "main_plot" : filterLane,
        sequence_position: tiles.length,
        tile_type: "beat",
        tags: [],
        characters_present: [],
        mood_overlays: [],
        metadata: {},
      });
      setTiles([...tiles, tile]);
      setEditingTile(tile);
    } catch (err) {
      console.error("Failed to create tile:", err);
    }
  }

  async function handleUpdateTile(id: string, updates: Partial<StoryTile>) {
    try {
      const updated = await updateStoryTile(id, updates);
      setTiles(tiles.map((t) => (t.id === id ? updated : t)));
      if (editingTile?.id === id) setEditingTile(updated);
    } catch (err) {
      console.error("Failed to update tile:", err);
    }
  }

  async function handleDeleteTile(id: string) {
    try {
      await deleteStoryTile(id);
      setTiles(tiles.filter((t) => t.id !== id));
      setEditingTile(null);
    } catch (err) {
      console.error("Failed to delete tile:", err);
    }
  }

  function handleDragStart(event: DragStartEvent) {
    setActiveDragId(event.active.id as string);
  }

  async function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event;
    setActiveDragId(null);

    if (!over || active.id === over.id) return;

    const oldIndex = tiles.findIndex((t) => t.id === active.id);
    const newIndex = tiles.findIndex((t) => t.id === over.id);

    if (oldIndex === -1 || newIndex === -1) return;

    // Check if this is a SLAPP merge (dropping tile onto another)
    const sourceTile = tiles[oldIndex];
    const targetTile = tiles[newIndex];

    // If tiles are adjacent, reorder. If they're far apart, prompt merge
    if (Math.abs(oldIndex - newIndex) <= 1) {
      // Reorder
      const newTiles = [...tiles];
      const [removed] = newTiles.splice(oldIndex, 1);
      newTiles.splice(newIndex, 0, removed);
      const reordered = newTiles.map((t, i) => ({
        ...t,
        sequence_position: i,
      }));
      setTiles(reordered);
      await reorderTiles(reordered.map((t) => ({ id: t.id, sequence_position: t.sequence_position })));
    } else {
      // SLAPP Merge!
      setMergeSource(sourceTile);
      setMergeTarget(targetTile);
      setShowMergeModal(true);
    }
  }

  async function handleSlappMerge(mode: MergeMode) {
    if (!mergeSource || !mergeTarget || !projectId) return;
    setMerging(true);

    try {
      const res = await fetch("/api/slapp-merge", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          source: mergeSource,
          target: mergeTarget,
          mergeMode: mode,
        }),
      });

      const result = await res.json();

      // Create merged tile
      const mergedTile = await createStoryTile({
        project_id: projectId,
        title: result.merged_title || `${mergeSource.title} + ${mergeTarget.title}`,
        beat_summary: result.merged_summary || null,
        emotional_tone: result.emotional_tone || null,
        lane: mergeSource.lane,
        sequence_position: mergeSource.sequence_position,
        tile_type: "scene",
        tags: [...(mergeSource.tags || []), ...(mergeTarget.tags || [])],
        characters_present: [
          ...new Set([
            ...(mergeSource.characters_present || []),
            ...(mergeTarget.characters_present || []),
          ]),
        ],
        mood_overlays: [
          ...new Set([
            ...(mergeSource.mood_overlays || []),
            ...(mergeTarget.mood_overlays || []),
          ]),
        ],
        metadata: {
          merged_from: [mergeSource.id, mergeTarget.id],
          merge_mode: mode,
          scene_draft: result.scene_draft,
          continuity_implications: result.continuity_implications,
          arc_impact: result.arc_impact,
        },
      });

      setTiles([
        ...tiles.filter((t) => t.id !== mergeSource.id && t.id !== mergeTarget.id),
        mergedTile,
      ]);
    } catch (err) {
      console.error("SLAPP merge failed:", err);
    } finally {
      setMerging(false);
      setShowMergeModal(false);
      setMergeSource(null);
      setMergeTarget(null);
    }
  }

  const filteredTiles =
    filterLane === "all" ? tiles : tiles.filter((t) => t.lane === filterLane);

  const draggedTile = activeDragId
    ? tiles.find((t) => t.id === activeDragId)
    : null;

  const gridClass = {
    beat: "grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4",
    cinematic: "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6",
    comic: "grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-2",
    moodboard: "grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3",
    structure: "grid-cols-1 md:grid-cols-2 gap-4",
  }[viewMode];

  if (!projectId) {
    return (
      <div className="flex items-center justify-center h-full text-text-muted">
        Select a project from Home to view the storyboard.
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-8 h-8 text-slapp-orange animate-spin" />
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="flex items-center justify-between px-4 h-12 border-b border-border-subtle bg-surface-0 flex-shrink-0">
        <div className="flex items-center gap-4">
          <h2 className="text-sm font-medium text-text-primary">
            Storyboard
          </h2>
          
          {/* View Modes */}
          <div className="flex items-center gap-0.5 bg-surface-2 rounded-lg p-0.5">
            {VIEW_MODES.map((mode) => (
              <button
                key={mode.id}
                onClick={() => setViewMode(mode.id)}
                className={cn(
                  "flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs transition",
                  viewMode === mode.id
                    ? "bg-surface-0 text-text-primary shadow-sm"
                    : "text-text-muted hover:text-text-secondary"
                )}
              >
                {mode.icon}
                <span className="hidden md:inline">{mode.label}</span>
              </button>
            ))}
          </div>

          {/* Lane Filter */}
          <div className="flex items-center gap-1.5">
            <Filter className="w-3.5 h-3.5 text-text-muted" />
            <select
              value={filterLane}
              onChange={(e) => setFilterLane(e.target.value)}
              className="px-2 py-1 bg-surface-2 border border-border-default rounded-lg text-xs text-text-primary focus:outline-none transition appearance-none"
            >
              <option value="all">All Lanes</option>
              {Object.entries(LANE_LABELS).map(([key, { label }]) => (
                <option key={key} value={key}>
                  {label}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <span className="text-xs text-text-muted">
            {filteredTiles.length} tiles
          </span>
          <button
            onClick={handleCreateTile}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-slapp-orange text-white rounded-lg text-xs hover:bg-slapp-orange/90 transition"
          >
            <Plus className="w-3.5 h-3.5" />
            New Tile
          </button>
        </div>
      </div>

      {/* Board */}
      <div className="flex-1 overflow-y-auto p-4">
        {filteredTiles.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full gap-4 text-text-muted">
            <LayoutGrid className="w-16 h-16 text-text-muted/30" />
            <p className="text-sm">No tiles yet. Create your first story beat.</p>
            <button
              onClick={handleCreateTile}
              className="flex items-center gap-2 px-4 py-2 bg-slapp-orange text-white rounded-lg text-sm hover:bg-slapp-orange/90 transition"
            >
              <Plus className="w-4 h-4" />
              Add First Tile
            </button>
          </div>
        ) : (
          <DndContext
            sensors={sensors}
            collisionDetection={closestCenter}
            onDragStart={handleDragStart}
            onDragEnd={handleDragEnd}
          >
            <SortableContext
              items={filteredTiles.map((t) => t.id)}
              strategy={rectSortingStrategy}
            >
              <div className={cn("grid", gridClass)}>
                {filteredTiles.map((tile) => (
                  <TileCard
                    key={tile.id}
                    tile={tile}
                    isSelected={editingTile?.id === tile.id}
                    onClick={() => {}}
                    onDoubleClick={() => setEditingTile(tile)}
                  />
                ))}
              </div>
            </SortableContext>

            <DragOverlay>
              {draggedTile && (
                <div className="w-64">
                  <TileCard
                    tile={draggedTile}
                    isSelected={false}
                    onClick={() => {}}
                    onDoubleClick={() => {}}
                    isDragOverlay
                  />
                </div>
              )}
            </DragOverlay>
          </DndContext>
        )}
      </div>

      {/* Tile Editor Modal */}
      {editingTile && (
        <TileEditor
          tile={editingTile}
          onUpdate={(updates) => handleUpdateTile(editingTile.id, updates)}
          onDelete={() => handleDeleteTile(editingTile.id)}
          onClose={() => setEditingTile(null)}
        />
      )}

      {/* SLAPP Merge Modal */}
      {showMergeModal && mergeSource && mergeTarget && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 p-4">
          <div className="bg-surface-1 border border-border-subtle rounded-2xl w-full max-w-md animate-fade-in">
            <div className="p-5">
              <div className="flex items-center gap-2 mb-4">
                <Zap className="w-5 h-5 text-slapp-orange" />
                <h2 className="text-lg font-bold text-text-primary">
                  SLAPP Merge
                </h2>
              </div>

              <div className="flex items-center gap-3 mb-5">
                <div className="flex-1 p-3 bg-surface-2 rounded-lg">
                  <p className="text-xs text-text-muted mb-1">Source</p>
                  <p className="text-sm text-text-primary font-medium truncate">
                    {mergeSource.title}
                  </p>
                </div>
                <Zap className="w-4 h-4 text-slapp-orange flex-shrink-0" />
                <div className="flex-1 p-3 bg-surface-2 rounded-lg">
                  <p className="text-xs text-text-muted mb-1">Target</p>
                  <p className="text-sm text-text-primary font-medium truncate">
                    {mergeTarget.title}
                  </p>
                </div>
              </div>

              <p className="text-xs text-text-muted mb-3">
                How should these elements merge?
              </p>

              <div className="space-y-1.5">
                {[
                  { mode: "combine_narrative" as MergeMode, label: "Combine Narratively", desc: "Merge plot significance and purpose" },
                  { mode: "combine_visual" as MergeMode, label: "Combine Visually", desc: "Merge imagery and atmosphere" },
                  { mode: "hybrid_scene" as MergeMode, label: "Hybrid Scene", desc: "Create something greater than both" },
                  { mode: "merge_emotions" as MergeMode, label: "Merge Emotions", desc: "Blend emotional beats" },
                  { mode: "alternate_version" as MergeMode, label: "Alternate Version", desc: "Create unexpected blend" },
                  { mode: "branching_options" as MergeMode, label: "Branching Options", desc: "Generate multiple paths" },
                ].map(({ mode, label, desc }) => (
                  <button
                    key={mode}
                    onClick={() => handleSlappMerge(mode)}
                    disabled={merging}
                    className="flex items-start gap-3 w-full p-3 bg-surface-2 rounded-lg text-left hover:bg-surface-3 transition disabled:opacity-50"
                  >
                    <Zap className="w-4 h-4 text-slapp-orange mt-0.5 flex-shrink-0" />
                    <div>
                      <p className="text-sm text-text-primary font-medium">
                        {label}
                      </p>
                      <p className="text-xs text-text-muted">{desc}</p>
                    </div>
                  </button>
                ))}
              </div>

              {merging && (
                <div className="flex items-center justify-center gap-2 mt-4 py-3 text-sm text-slapp-gold">
                  <Loader2 className="w-4 h-4 animate-spin" />
                  SLAPPing together...
                </div>
              )}

              <button
                onClick={() => {
                  setShowMergeModal(false);
                  setMergeSource(null);
                  setMergeTarget(null);
                }}
                className="w-full mt-4 py-2 text-sm text-text-muted hover:text-text-primary transition"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
