"use client";

import { useState, useCallback } from "react";
import type { StoryTile, MoodOverlay, TileType, StoryboardLane } from "@/lib/types";
import { cn } from "@/lib/utils";
import {
  X,
  Save,
  Image as ImageIcon,
  Plus,
  Trash2,
} from "lucide-react";

interface TileEditorProps {
  tile: StoryTile;
  onUpdate: (updates: Partial<StoryTile>) => void;
  onDelete: () => void;
  onClose: () => void;
}

const MOOD_OPTIONS: MoodOverlay[] = [
  "noir", "dreamlike", "holy", "grotesque", "romantic",
  "decayed", "kinetic", "mythic", "tense", "wonder", "dread",
];

const TILE_TYPES: TileType[] = [
  "beat", "scene", "visual_moment", "reveal", "memory",
  "transition", "character_intro", "mood_cluster", "action_step", "alternate",
];

const LANES: StoryboardLane[] = [
  "main_plot", "character_arc", "romance", "mystery",
  "villain", "flashback", "world_lore", "comic_relief", "symbolic",
];

export function TileEditor({ tile, onUpdate, onDelete, onClose }: TileEditorProps) {
  const [title, setTitle] = useState(tile.title);
  const [summary, setSummary] = useState(tile.beat_summary || "");
  const [tone, setTone] = useState(tile.emotional_tone || "");
  const [tileType, setTileType] = useState(tile.tile_type);
  const [lane, setLane] = useState(tile.lane);
  const [moods, setMoods] = useState<MoodOverlay[]>(tile.mood_overlays || []);
  const [dirty, setDirty] = useState(false);

  function handleSave() {
    onUpdate({
      title,
      beat_summary: summary || null,
      emotional_tone: tone || null,
      tile_type: tileType,
      lane,
      mood_overlays: moods,
    });
    setDirty(false);
  }

  function toggleMood(mood: MoodOverlay) {
    setMoods((prev) =>
      prev.includes(mood)
        ? prev.filter((m) => m !== mood)
        : [...prev, mood]
    );
    setDirty(true);
  }

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="bg-surface-1 border border-border-subtle rounded-2xl w-full max-w-lg max-h-[80vh] overflow-y-auto animate-fade-in">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-border-subtle">
          <h2 className="text-lg font-semibold text-text-primary">Edit Tile</h2>
          <div className="flex items-center gap-2">
            {dirty && (
              <button
                onClick={handleSave}
                className="flex items-center gap-1 px-3 py-1.5 bg-slapp-orange text-white rounded-lg text-xs hover:bg-slapp-orange/90 transition"
              >
                <Save className="w-3 h-3" />
                Save
              </button>
            )}
            <button
              onClick={onClose}
              className="p-1.5 text-text-muted hover:text-text-primary transition"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        <div className="p-5 space-y-5">
          {/* Title */}
          <div>
            <label className="block text-xs text-text-muted mb-1">Title</label>
            <input
              type="text"
              value={title}
              onChange={(e) => { setTitle(e.target.value); setDirty(true); }}
              className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary focus:outline-none focus:border-slapp-orange/50 transition"
            />
          </div>

          {/* Beat Summary */}
          <div>
            <label className="block text-xs text-text-muted mb-1">Beat Summary</label>
            <textarea
              value={summary}
              onChange={(e) => { setSummary(e.target.value); setDirty(true); }}
              rows={3}
              className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition resize-none"
              placeholder="What happens in this beat..."
            />
          </div>

          {/* Type and Lane */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs text-text-muted mb-1">Type</label>
              <select
                value={tileType}
                onChange={(e) => { setTileType(e.target.value as TileType); setDirty(true); }}
                className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary focus:outline-none focus:border-slapp-orange/50 transition appearance-none"
              >
                {TILE_TYPES.map((t) => (
                  <option key={t} value={t}>
                    {t.replace(/_/g, " ")}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-xs text-text-muted mb-1">Lane</label>
              <select
                value={lane}
                onChange={(e) => { setLane(e.target.value as StoryboardLane); setDirty(true); }}
                className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary focus:outline-none focus:border-slapp-orange/50 transition appearance-none"
              >
                {LANES.map((l) => (
                  <option key={l} value={l}>
                    {l.replace(/_/g, " ")}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Emotional Tone */}
          <div>
            <label className="block text-xs text-text-muted mb-1">Emotional Tone</label>
            <input
              type="text"
              value={tone}
              onChange={(e) => { setTone(e.target.value); setDirty(true); }}
              placeholder="e.g., tension, wonder, grief, triumph..."
              className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition"
            />
          </div>

          {/* Mood Overlays */}
          <div>
            <label className="block text-xs text-text-muted mb-2">Mood Overlays</label>
            <div className="flex flex-wrap gap-1.5">
              {MOOD_OPTIONS.map((mood) => (
                <button
                  key={mood}
                  onClick={() => toggleMood(mood)}
                  className={cn(
                    "px-2.5 py-1 rounded-full text-xs transition capitalize",
                    moods.includes(mood)
                      ? "bg-slapp-orange/20 text-slapp-orange border border-slapp-orange/30"
                      : "bg-surface-3 text-text-secondary border border-transparent hover:text-text-primary"
                  )}
                >
                  {mood}
                </button>
              ))}
            </div>
          </div>

          {/* Delete */}
          <div className="pt-3 border-t border-border-subtle">
            <button
              onClick={onDelete}
              className="flex items-center gap-2 px-3 py-2 text-sm text-slapp-coral hover:bg-slapp-coral/10 rounded-lg transition"
            >
              <Trash2 className="w-4 h-4" />
              Delete Tile
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
