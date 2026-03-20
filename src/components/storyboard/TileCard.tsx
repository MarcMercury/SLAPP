"use client";

import { cn } from "@/lib/utils";
import type { StoryTile, MoodOverlay } from "@/lib/types";
import { useSortable } from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import {
  GripVertical,
  MoreHorizontal,
  Image as ImageIcon,
  Users,
  MapPin,
  Layers,
} from "lucide-react";

interface TileCardProps {
  tile: StoryTile;
  isSelected: boolean;
  onClick: () => void;
  onDoubleClick: () => void;
  isDragOverlay?: boolean;
}

const MOOD_COLORS: Record<MoodOverlay, string> = {
  noir: "border-l-zinc-400",
  dreamlike: "border-l-violet-400",
  holy: "border-l-amber-300",
  grotesque: "border-l-red-700",
  romantic: "border-l-rose-400",
  decayed: "border-l-stone-500",
  kinetic: "border-l-orange-500",
  mythic: "border-l-indigo-400",
  tense: "border-l-red-500",
  wonder: "border-l-cyan-400",
  dread: "border-l-gray-600",
};

const TILE_TYPE_COLORS: Record<string, string> = {
  beat: "bg-blue-500/10",
  scene: "bg-emerald-500/10",
  visual_moment: "bg-purple-500/10",
  reveal: "bg-amber-500/10",
  memory: "bg-indigo-500/10",
  transition: "bg-zinc-500/10",
  character_intro: "bg-rose-500/10",
  mood_cluster: "bg-violet-500/10",
  action_step: "bg-orange-500/10",
  alternate: "bg-cyan-500/10",
};

export function TileCard({
  tile,
  isSelected,
  onClick,
  onDoubleClick,
  isDragOverlay,
}: TileCardProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: tile.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  };

  const moodBorder =
    tile.mood_overlays?.length > 0
      ? MOOD_COLORS[tile.mood_overlays[0] as MoodOverlay]
      : "border-l-transparent";

  return (
    <div
      ref={isDragOverlay ? undefined : setNodeRef}
      style={isDragOverlay ? undefined : style}
      onClick={onClick}
      onDoubleClick={onDoubleClick}
      className={cn(
        "group relative bg-surface-2 rounded-xl border-2 border-l-4 overflow-hidden transition-all cursor-pointer",
        moodBorder,
        isSelected
          ? "border-slapp-orange shadow-lg shadow-slapp-orange/10"
          : "border-border-subtle hover:border-border-strong",
        isDragging && "opacity-30",
        isDragOverlay && "shadow-2xl rotate-2 scale-105",
        TILE_TYPE_COLORS[tile.tile_type] || "bg-surface-2"
      )}
    >
      {/* Drag Handle */}
      <div
        {...attributes}
        {...listeners}
        className="absolute top-2 left-1 opacity-0 group-hover:opacity-100 transition cursor-grab active:cursor-grabbing z-10"
      >
        <GripVertical className="w-3.5 h-3.5 text-text-muted" />
      </div>

      {/* Image */}
      {tile.image_url ? (
        <div className="aspect-video bg-surface-3 overflow-hidden">
          <img
            src={tile.image_url}
            alt={tile.title}
            className="w-full h-full object-cover"
          />
        </div>
      ) : (
        <div className="aspect-video bg-surface-3 flex items-center justify-center">
          <ImageIcon className="w-8 h-8 text-text-muted/30" />
        </div>
      )}

      {/* Content */}
      <div className="p-3 space-y-2">
        <div className="flex items-start justify-between gap-2">
          <h3 className="text-sm font-medium text-text-primary line-clamp-2 leading-snug">
            {tile.title}
          </h3>
        </div>

        {tile.beat_summary && (
          <p className="text-xs text-text-secondary line-clamp-2">
            {tile.beat_summary}
          </p>
        )}

        {/* Meta */}
        <div className="flex items-center gap-2 flex-wrap">
          {tile.emotional_tone && (
            <span className="px-1.5 py-0.5 bg-surface-3 text-text-muted rounded text-[10px]">
              {tile.emotional_tone}
            </span>
          )}
          {tile.characters_present?.length > 0 && (
            <span className="flex items-center gap-0.5 text-[10px] text-text-muted">
              <Users className="w-2.5 h-2.5" />
              {tile.characters_present.length}
            </span>
          )}
          {tile.mood_overlays?.length > 0 && (
            <span className="flex items-center gap-0.5 text-[10px] text-text-muted">
              <Layers className="w-2.5 h-2.5" />
              {tile.mood_overlays.join(", ")}
            </span>
          )}
        </div>

        {/* Tags */}
        {tile.tags?.length > 0 && (
          <div className="flex flex-wrap gap-1">
            {tile.tags.slice(0, 3).map((tag: string) => (
              <span
                key={tag}
                className="px-1.5 py-0.5 bg-surface-3 text-text-muted rounded-full text-[10px]"
              >
                {tag}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Tile type badge */}
      <div className="absolute top-2 right-2 px-1.5 py-0.5 bg-black/40 backdrop-blur-sm rounded text-[10px] text-white/80 capitalize">
        {tile.tile_type.replace("_", " ")}
      </div>
    </div>
  );
}
