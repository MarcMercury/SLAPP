"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useProjectStore, useStoryObjectStore } from "@/lib/stores";
import { getProject, getStoryObjects, createStoryObject, updateStoryObject, deleteStoryObject } from "@/lib/db";
import { getObjectTypeIcon, cn } from "@/lib/utils";
import type { StoryObject, StoryObjectType } from "@/lib/types";
import { Loader2, Plus, Search, MapPin, Users, Gem, Crown, Scroll, X } from "lucide-react";

const WORLD_TYPES: { type: StoryObjectType; icon: React.ReactNode; label: string }[] = [
  { type: "character", icon: <Users className="w-4 h-4" />, label: "Characters" },
  { type: "place", icon: <MapPin className="w-4 h-4" />, label: "Places" },
  { type: "item", icon: <Gem className="w-4 h-4" />, label: "Items" },
  { type: "faction", icon: <Crown className="w-4 h-4" />, label: "Factions" },
  { type: "rule", icon: <Scroll className="w-4 h-4" />, label: "World Rules" },
];

export default function WorldPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full"><Loader2 className="w-8 h-8 text-slapp-orange animate-spin" /></div>}>
      <WorldInner />
    </Suspense>
  );
}

function WorldInner() {
  const searchParams = useSearchParams();
  const projectId = searchParams.get("project");
  const { setCurrentProject } = useProjectStore();
  const { objects, setObjects } = useStoryObjectStore();

  const [loading, setLoading] = useState(true);
  const [activeType, setActiveType] = useState<StoryObjectType>("character");
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<StoryObject | null>(null);
  const [editName, setEditName] = useState("");
  const [editDesc, setEditDesc] = useState("");

  useEffect(() => {
    if (projectId) loadData(projectId);
  }, [projectId]);

  async function loadData(id: string) {
    setLoading(true);
    const [project, objs] = await Promise.all([getProject(id), getStoryObjects(id)]);
    if (project) setCurrentProject(project);
    setObjects(objs);
    setLoading(false);
  }

  const filtered = objects
    .filter((o) => o.type === activeType)
    .filter((o) => !search || o.name.toLowerCase().includes(search.toLowerCase()));

  async function handleCreate() {
    if (!projectId) return;
    const obj = await createStoryObject({
      project_id: projectId,
      type: activeType,
      name: `New ${activeType}`,
      status: "draft",
      canon_state: "draft",
      tags: [],
    });
    setObjects([...objects, obj]);
    setSelected(obj);
    setEditName(obj.name);
    setEditDesc("");
  }

  async function handleSave() {
    if (!selected) return;
    const updated = await updateStoryObject(selected.id, {
      name: editName,
      description: editDesc,
    });
    setObjects(objects.map((o) => (o.id === updated.id ? updated : o)));
    setSelected(updated);
  }

  async function handleDelete(id: string) {
    await deleteStoryObject(id);
    setObjects(objects.filter((o) => o.id !== id));
    if (selected?.id === id) setSelected(null);
  }

  if (!projectId) {
    return (
      <div className="flex items-center justify-center h-full text-text-muted">
        Select a project from Home to explore your world.
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
    <div className="flex h-full">
      {/* Left: Category + List */}
      <div className="w-72 border-r border-border-subtle bg-surface-1 flex flex-col flex-shrink-0">
        <div className="p-3 border-b border-border-subtle">
          <div className="relative">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-text-muted" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search world..."
              className="w-full bg-surface-2 border border-border-subtle rounded-lg pl-8 pr-3 py-1.5 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50"
            />
          </div>
        </div>

        <div className="flex border-b border-border-subtle overflow-x-auto">
          {WORLD_TYPES.map((wt) => (
            <button
              key={wt.type}
              onClick={() => { setActiveType(wt.type); setSelected(null); }}
              className={cn(
                "flex items-center gap-1.5 px-3 py-2 text-xs whitespace-nowrap transition",
                activeType === wt.type
                  ? "text-slapp-orange border-b-2 border-slapp-orange"
                  : "text-text-muted hover:text-text-secondary"
              )}
            >
              {wt.icon}
              {wt.label}
              <span className="text-[10px] text-text-muted">
                ({objects.filter((o) => o.type === wt.type).length})
              </span>
            </button>
          ))}
        </div>

        <div className="flex-1 overflow-y-auto p-2 space-y-1">
          {filtered.map((obj) => (
            <button
              key={obj.id}
              onClick={() => {
                setSelected(obj);
                setEditName(obj.name);
                setEditDesc(obj.description || "");
              }}
              className={cn(
                "w-full text-left px-3 py-2 rounded-lg text-sm transition",
                selected?.id === obj.id
                  ? "bg-slapp-orange/10 text-slapp-orange"
                  : "text-text-secondary hover:bg-surface-2"
              )}
            >
              <span className="mr-2">{getObjectTypeIcon(obj.type)}</span>
              {obj.name}
            </button>
          ))}

          <button
            onClick={handleCreate}
            className="w-full flex items-center gap-2 px-3 py-2 rounded-lg text-sm text-text-muted hover:bg-surface-2 transition"
          >
            <Plus className="w-3.5 h-3.5" />
            Add {activeType}
          </button>
        </div>
      </div>

      {/* Right: Detail */}
      <div className="flex-1 p-6 overflow-y-auto">
        {selected ? (
          <div className="max-w-2xl space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-xs text-text-muted uppercase tracking-wider">
                {getObjectTypeIcon(selected.type)} {selected.type}
              </span>
              <button
                onClick={() => handleDelete(selected.id)}
                className="text-text-muted hover:text-red-400 transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <input
              value={editName}
              onChange={(e) => setEditName(e.target.value)}
              onBlur={handleSave}
              className="w-full bg-transparent text-2xl font-bold text-text-primary focus:outline-none"
            />

            <textarea
              value={editDesc}
              onChange={(e) => setEditDesc(e.target.value)}
              onBlur={handleSave}
              placeholder="Describe this element..."
              rows={8}
              className="w-full bg-surface-2 border border-border-subtle rounded-xl p-4 text-sm text-text-secondary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 resize-none"
            />

            {selected.tags && selected.tags.length > 0 && (
              <div className="flex flex-wrap gap-1.5">
                {selected.tags.map((tag: string) => (
                  <span key={tag} className="px-2 py-0.5 bg-surface-3 text-text-muted rounded text-xs">
                    {tag}
                  </span>
                ))}
              </div>
            )}
          </div>
        ) : (
          <div className="flex items-center justify-center h-full text-text-muted text-sm">
            Select an element or create a new one.
          </div>
        )}
      </div>
    </div>
  );
}
