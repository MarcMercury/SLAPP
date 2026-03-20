"use client";

import { useState } from "react";
import { cn, getObjectTypeIcon, getObjectTypeLabel, getStatusColor } from "@/lib/utils";
import type { StoryObject, StoryObjectType } from "@/lib/types";
import {
  Search,
  Plus,
  ChevronDown,
  ChevronRight,
  MoreHorizontal,
  Trash2,
  Edit3,
} from "lucide-react";

interface ObjectSidebarProps {
  objects: StoryObject[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onCreate: (type: StoryObjectType) => void;
  onDelete: (id: string) => void;
}

const OBJECT_CATEGORIES: { label: string; types: StoryObjectType[] }[] = [
  { label: "Writing", types: ["scene", "chapter", "sequence", "dialogue_fragment"] },
  { label: "Characters", types: ["character", "relationship", "faction"] },
  { label: "World", types: ["place", "item", "lore_entry", "rule"] },
  { label: "Story", types: ["storyline", "theme", "timeline_event"] },
  { label: "Mystery", types: ["secret", "mystery", "clue", "reveal"] },
  { label: "Inspiration", types: ["visual_moment", "unused_idea", "alternate_version"] },
];

export function ObjectSidebar({
  objects,
  selectedId,
  onSelect,
  onCreate,
  onDelete,
}: ObjectSidebarProps) {
  const [search, setSearch] = useState("");
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(
    new Set(["Writing", "Characters"])
  );
  const [contextMenuId, setContextMenuId] = useState<string | null>(null);

  const filteredObjects = objects.filter(
    (obj) =>
      obj.name.toLowerCase().includes(search.toLowerCase()) ||
      obj.type.toLowerCase().includes(search.toLowerCase()) ||
      obj.tags?.some((t: string) => t.toLowerCase().includes(search.toLowerCase()))
  );

  function toggleCategory(label: string) {
    setExpandedCategories((prev) => {
      const next = new Set(prev);
      if (next.has(label)) next.delete(label);
      else next.add(label);
      return next;
    });
  }

  function getObjectsForTypes(types: StoryObjectType[]) {
    return filteredObjects.filter((obj) => types.includes(obj.type));
  }

  return (
    <div className="flex flex-col h-full bg-surface-1 border-r border-border-subtle w-64 flex-shrink-0">
      {/* Search */}
      <div className="p-3 border-b border-border-subtle">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-text-muted" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search objects..."
            className="w-full pl-9 pr-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition"
          />
        </div>
      </div>

      {/* Object Tree */}
      <div className="flex-1 overflow-y-auto py-1">
        {OBJECT_CATEGORIES.map((category) => {
          const categoryObjects = getObjectsForTypes(category.types);
          const isExpanded = expandedCategories.has(category.label);

          return (
            <div key={category.label}>
              <button
                onClick={() => toggleCategory(category.label)}
                className="flex items-center justify-between w-full px-3 py-2 text-xs font-semibold uppercase tracking-wider text-text-muted hover:text-text-secondary transition"
              >
                <div className="flex items-center gap-1.5">
                  {isExpanded ? (
                    <ChevronDown className="w-3 h-3" />
                  ) : (
                    <ChevronRight className="w-3 h-3" />
                  )}
                  <span>{category.label}</span>
                  {categoryObjects.length > 0 && (
                    <span className="text-[10px] px-1.5 py-0.5 bg-surface-3 rounded-full">
                      {categoryObjects.length}
                    </span>
                  )}
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    onCreate(category.types[0]);
                  }}
                  className="p-0.5 hover:bg-surface-3 rounded transition"
                  title={`New ${category.label}`}
                >
                  <Plus className="w-3 h-3" />
                </button>
              </button>

              {isExpanded && (
                <div className="space-y-0.5 pb-1">
                  {categoryObjects.length === 0 ? (
                    <p className="px-6 py-2 text-xs text-text-muted italic">
                      No {category.label.toLowerCase()} yet
                    </p>
                  ) : (
                    categoryObjects.map((obj) => (
                      <div
                        key={obj.id}
                        className="relative group"
                        onContextMenu={(e) => {
                          e.preventDefault();
                          setContextMenuId(contextMenuId === obj.id ? null : obj.id);
                        }}
                      >
                        <button
                          onClick={() => {
                            onSelect(obj.id);
                            setContextMenuId(null);
                          }}
                          className={cn(
                            "flex items-center gap-2 w-full px-4 py-1.5 text-sm transition text-left",
                            selectedId === obj.id
                              ? "bg-surface-3 text-text-primary"
                              : "text-text-secondary hover:text-text-primary hover:bg-surface-2"
                          )}
                        >
                          <span className="text-xs flex-shrink-0">
                            {getObjectTypeIcon(obj.type)}
                          </span>
                          <span className="truncate">{obj.name}</span>
                          <div
                            className={cn(
                              "w-1.5 h-1.5 rounded-full ml-auto flex-shrink-0",
                              getStatusColor(obj.status)
                            )}
                          />
                        </button>

                        {/* Context Menu */}
                        {contextMenuId === obj.id && (
                          <div className="absolute right-2 top-full z-50 bg-surface-2 border border-border-default rounded-lg shadow-xl py-1 min-w-[140px] animate-fade-in">
                            <button
                              onClick={() => {
                                onSelect(obj.id);
                                setContextMenuId(null);
                              }}
                              className="flex items-center gap-2 w-full px-3 py-1.5 text-sm text-text-secondary hover:text-text-primary hover:bg-surface-3 transition"
                            >
                              <Edit3 className="w-3.5 h-3.5" />
                              Edit
                            </button>
                            <button
                              onClick={() => {
                                onDelete(obj.id);
                                setContextMenuId(null);
                              }}
                              className="flex items-center gap-2 w-full px-3 py-1.5 text-sm text-slapp-coral hover:bg-surface-3 transition"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                              Delete
                            </button>
                          </div>
                        )}
                      </div>
                    ))
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Quick Add */}
      <div className="p-3 border-t border-border-subtle">
        <button
          onClick={() => onCreate("unused_idea")}
          className="flex items-center justify-center gap-2 w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-secondary hover:text-text-primary hover:border-border-strong transition"
        >
          <Plus className="w-4 h-4" />
          Quick Idea
        </button>
      </div>
    </div>
  );
}
