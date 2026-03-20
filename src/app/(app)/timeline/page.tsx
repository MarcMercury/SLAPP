"use client";

import { Suspense, useEffect, useState, useMemo } from "react";
import { useSearchParams } from "next/navigation";
import { useProjectStore, useStoryObjectStore, useLinksStore } from "@/lib/stores";
import { getProject, getStoryObjects, getStoryLinks } from "@/lib/db";
import { getObjectTypeIcon, cn } from "@/lib/utils";
import type { StoryObject } from "@/lib/types";
import { Loader2, Clock, ArrowRight, ChevronDown, ChevronUp } from "lucide-react";

export default function TimelinePage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full"><Loader2 className="w-8 h-8 text-slapp-orange animate-spin" /></div>}>
      <TimelineInner />
    </Suspense>
  );
}

function TimelineInner() {
  const searchParams = useSearchParams();
  const projectId = searchParams.get("project");
  const { setCurrentProject } = useProjectStore();
  const { objects, setObjects } = useStoryObjectStore();
  const { links, setLinks } = useLinksStore();

  const [loading, setLoading] = useState(true);
  const [expandedId, setExpandedId] = useState<string | null>(null);

  useEffect(() => {
    if (projectId) loadData(projectId);
  }, [projectId]);

  async function loadData(id: string) {
    setLoading(true);
    const [project, objs, lnks] = await Promise.all([
      getProject(id),
      getStoryObjects(id),
      getStoryLinks(id),
    ]);
    if (project) setCurrentProject(project);
    setObjects(objs);
    setLinks(lnks);
    setLoading(false);
  }

  // Build timeline from scenes and events
  const timelineItems = useMemo(() => {
    const scenes = objects.filter((o) => o.type === "scene" || o.type === "timeline_event");
    // Sort by order_index or created_at
    return scenes.sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0));
  }, [objects]);

  const connectedObjects = useMemo(() => {
    const map: Record<string, StoryObject[]> = {};
    timelineItems.forEach((item) => {
      const relatedIds = links
        .filter((l) => l.source_id === item.id || l.target_id === item.id)
        .map((l) => (l.source_id === item.id ? l.target_id : l.source_id));
      map[item.id] = objects.filter((o) => relatedIds.includes(o.id));
    });
    return map;
  }, [timelineItems, links, objects]);

  if (!projectId) {
    return (
      <div className="flex items-center justify-center h-full text-text-muted">
        Select a project from Home to view the timeline.
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
    <div className="p-6 max-w-3xl mx-auto">
      <h1 className="text-xl font-bold text-text-primary mb-6 flex items-center gap-2">
        <Clock className="w-5 h-5 text-slapp-orange" />
        Timeline
      </h1>

      {timelineItems.length === 0 ? (
        <div className="text-center py-16 text-text-muted text-sm">
          No scenes or events yet. Create scenes in the Writing Suite to build your timeline.
        </div>
      ) : (
        <div className="relative">
          {/* Vertical line */}
          <div className="absolute left-6 top-0 bottom-0 w-0.5 bg-border-subtle" />

          <div className="space-y-4">
            {timelineItems.map((item, index) => {
              const related = connectedObjects[item.id] || [];
              const isExpanded = expandedId === item.id;

              return (
                <div key={item.id} className="relative pl-14">
                  {/* Dot */}
                  <div
                    className={cn(
                      "absolute left-[18px] top-4 w-3 h-3 rounded-full border-2 border-surface-0",
                      item.type === "timeline_event" ? "bg-slapp-coral" : "bg-slapp-orange"
                    )}
                  />

                  {/* Card */}
                  <div
                    className="bg-surface-1 border border-border-subtle rounded-xl p-4 hover:border-border-default transition cursor-pointer"
                    onClick={() => setExpandedId(isExpanded ? null : item.id)}
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-xs text-text-muted">#{index + 1}</span>
                          <span className="text-sm">{getObjectTypeIcon(item.type)}</span>
                          <h3 className="text-sm font-medium text-text-primary">{item.name}</h3>
                        </div>
                        {item.description && (
                          <p className="text-xs text-text-secondary line-clamp-2">{item.description}</p>
                        )}
                      </div>
                      {related.length > 0 && (
                        isExpanded ? (
                          <ChevronUp className="w-4 h-4 text-text-muted flex-shrink-0" />
                        ) : (
                          <ChevronDown className="w-4 h-4 text-text-muted flex-shrink-0" />
                        )
                      )}
                    </div>

                    {isExpanded && related.length > 0 && (
                      <div className="mt-3 pt-3 border-t border-border-subtle space-y-1.5">
                        <p className="text-[10px] text-text-muted uppercase tracking-wider mb-1">Connected</p>
                        {related.map((r) => (
                          <div key={r.id} className="flex items-center gap-2 text-xs text-text-secondary">
                            <ArrowRight className="w-3 h-3 text-text-muted" />
                            <span>{getObjectTypeIcon(r.type)}</span>
                            <span>{r.name}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
