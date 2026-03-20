"use client";

import { Suspense, useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import { useProjectStore, useStoryObjectStore } from "@/lib/stores";
import { getProject, getStoryObjects, createStoryObject, deleteStoryObject } from "@/lib/db";
import { getObjectTypeIcon, cn } from "@/lib/utils";
import type { StoryObject, StoryObjectType } from "@/lib/types";
import { Loader2, Plus, Search, Palette, Trash2 } from "lucide-react";

const ASSET_TYPES: StoryObjectType[] = [
  "visual_moment",
  "lore_entry",
  "unused_idea",
  "alternate_version",
  "dialogue_fragment",
];

export default function AssetsPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full"><Loader2 className="w-8 h-8 text-slapp-orange animate-spin" /></div>}>
      <AssetsInner />
    </Suspense>
  );
}

function AssetsInner() {
  const searchParams = useSearchParams();
  const projectId = searchParams.get("project");
  const { setCurrentProject } = useProjectStore();
  const { objects, setObjects } = useStoryObjectStore();

  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

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

  const assets = objects
    .filter((o) => ASSET_TYPES.includes(o.type))
    .filter((o) => !search || o.name.toLowerCase().includes(search.toLowerCase()));

  async function handleCreate(type: StoryObjectType) {
    if (!projectId) return;
    const obj = await createStoryObject({
      project_id: projectId,
      type,
      name: `New ${type.replace(/_/g, " ")}`,
      status: "draft",
      canon_state: "draft",
      tags: [],
    });
    setObjects([...objects, obj]);
  }

  async function handleDelete(id: string) {
    await deleteStoryObject(id);
    setObjects(objects.filter((o) => o.id !== id));
  }

  if (!projectId) {
    return (
      <div className="flex items-center justify-center h-full text-text-muted">
        Select a project from Home to manage assets.
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
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-xl font-bold text-text-primary flex items-center gap-2">
          <Palette className="w-5 h-5 text-slapp-orange" />
          Assets
        </h1>

        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-text-muted" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search assets..."
              className="bg-surface-2 border border-border-subtle rounded-lg pl-8 pr-3 py-1.5 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 w-48"
            />
          </div>

          <div className="flex items-center gap-1">
            {ASSET_TYPES.map((type) => (
              <button
                key={type}
                onClick={() => handleCreate(type)}
                className="flex items-center gap-1.5 px-2.5 py-1.5 bg-surface-2 hover:bg-surface-3 text-text-secondary rounded-lg text-xs transition"
                title={`Add ${type.replace(/_/g, " ")}`}
              >
                <Plus className="w-3 h-3" />
                {getObjectTypeIcon(type)}
              </button>
            ))}
          </div>
        </div>
      </div>

      {assets.length === 0 ? (
        <div className="text-center py-16 text-text-muted text-sm">
          No assets yet. Add images, symbols, color palettes, or visual references.
        </div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
          {assets.map((asset) => (
            <div
              key={asset.id}
              className="group bg-surface-1 border border-border-subtle rounded-xl overflow-hidden hover:border-border-default transition"
            >
              {/* Placeholder visual */}
              <div className="aspect-square bg-surface-2 flex items-center justify-center text-4xl">
                {getObjectTypeIcon(asset.type)}
              </div>

              <div className="p-3">
                <h3 className="text-sm font-medium text-text-primary truncate">{asset.name}</h3>
                <p className="text-[10px] text-text-muted capitalize mt-0.5">
                  {asset.type.replace(/_/g, " ")}
                </p>
              </div>

              <div className="px-3 pb-3 opacity-0 group-hover:opacity-100 transition">
                <button
                  onClick={() => handleDelete(asset.id)}
                  className="text-text-muted hover:text-red-400 transition"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
