"use client";

import { Suspense, useCallback, useEffect, useState, useMemo } from "react";
import { useSearchParams } from "next/navigation";
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  addEdge,
  type Node,
  type Edge,
  type Connection,
  type NodeTypes,
  Handle,
  Position,
  Panel,
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";
import { useProjectStore, useStoryObjectStore, useLinksStore, useContinuityStore } from "@/lib/stores";
import {
  getProject,
  getStoryObjects,
  getStoryLinks,
  getContinuityFlags,
  createStoryLink,
  deleteStoryLink,
} from "@/lib/db";
import { getObjectTypeIcon, getObjectTypeLabel, cn } from "@/lib/utils";
import type { StoryObject, StoryLink, ContinuityFlag } from "@/lib/types";
import {
  Loader2,
  AlertTriangle,
  CheckCircle,
  Info,
  Eye,
  Filter,
  BarChart3,
  GitBranch,
  Zap,
  Thermometer,
  Activity,
} from "lucide-react";

// ── Custom Node Component ───────────────────────────────────

function StoryNode({ data }: { data: { object: StoryObject; flags: ContinuityFlag[] } }) {
  const { object, flags } = data;
  const unresolvedFlags = flags.filter((f) => !f.resolved);
  const hasWarnings = unresolvedFlags.some((f) => f.severity === "warning");
  const hasErrors = unresolvedFlags.some((f) => f.severity === "error");

  return (
    <div
      className={cn(
        "bg-surface-2 border-2 rounded-xl p-3 min-w-[160px] max-w-[220px] shadow-lg transition-all hover:shadow-xl",
        hasErrors
          ? "border-red-500/60"
          : hasWarnings
          ? "border-amber-500/60"
          : "border-border-default hover:border-border-strong"
      )}
    >
      <Handle type="target" position={Position.Top} className="!bg-slapp-orange !w-2 !h-2" />

      <div className="flex items-center gap-2 mb-1.5">
        <span className="text-sm">{getObjectTypeIcon(object.type)}</span>
        <span className="text-[10px] text-text-muted uppercase tracking-wider">
          {getObjectTypeLabel(object.type)}
        </span>
        {unresolvedFlags.length > 0 && (
          <span className="ml-auto flex items-center gap-0.5">
            {hasErrors ? (
              <AlertTriangle className="w-3 h-3 text-red-400" />
            ) : hasWarnings ? (
              <AlertTriangle className="w-3 h-3 text-amber-400" />
            ) : (
              <Info className="w-3 h-3 text-blue-400" />
            )}
            <span className="text-[10px] text-text-muted">{unresolvedFlags.length}</span>
          </span>
        )}
      </div>

      <h3 className="text-sm font-medium text-text-primary truncate">
        {object.name}
      </h3>

      {object.description && (
        <p className="text-[11px] text-text-secondary mt-1 line-clamp-2">
          {object.description}
        </p>
      )}

      {object.tags?.length > 0 && (
        <div className="flex flex-wrap gap-1 mt-2">
          {object.tags.slice(0, 3).map((tag: string) => (
            <span
              key={tag}
              className="px-1.5 py-0.5 bg-surface-3 text-text-muted rounded text-[9px]"
            >
              {tag}
            </span>
          ))}
        </div>
      )}

      {/* Status dot */}
      <div
        className={cn(
          "absolute top-2 right-2 w-2 h-2 rounded-full",
          object.canon_state === "canonical" ? "bg-purple-500" :
          object.status === "polished" ? "bg-emerald-500" :
          object.status === "good" ? "bg-blue-500" :
          object.status === "rough" ? "bg-amber-500" :
          "bg-zinc-500"
        )}
      />

      <Handle type="source" position={Position.Bottom} className="!bg-slapp-orange !w-2 !h-2" />
    </div>
  );
}

const nodeTypes: NodeTypes = {
  storyNode: StoryNode,
};

// ── View Modes ──────────────────────────────────────────────

type BoardView = "flow" | "arcs" | "causality" | "health";

const VIEWS = [
  { id: "flow" as const, label: "Narrative Flow", icon: <GitBranch className="w-3.5 h-3.5" /> },
  { id: "arcs" as const, label: "Arc View", icon: <Activity className="w-3.5 h-3.5" /> },
  { id: "causality" as const, label: "Causality", icon: <Zap className="w-3.5 h-3.5" /> },
  { id: "health" as const, label: "Story Health", icon: <Thermometer className="w-3.5 h-3.5" /> },
];

// ── Object Type Filters ─────────────────────────────────────

const FILTER_TYPES = [
  "scene", "character", "place", "item", "chapter",
  "storyline", "mystery", "reveal", "theme",
];

export default function BigPicturePage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full"><Loader2 className="w-8 h-8 text-slapp-orange animate-spin" /></div>}>
      <BigPictureInner />
    </Suspense>
  );
}

function BigPictureInner() {
  const searchParams = useSearchParams();
  const projectId = searchParams.get("project");
  const { setCurrentProject } = useProjectStore();
  const { objects, setObjects } = useStoryObjectStore();
  const { links, setLinks } = useLinksStore();
  const { flags, setFlags } = useContinuityStore();

  const [loading, setLoading] = useState(true);
  const [boardView, setBoardView] = useState<BoardView>("flow");
  const [filterTypes, setFilterTypes] = useState<Set<string>>(new Set(FILTER_TYPES));

  const [nodes, setNodes, onNodesChange] = useNodesState<Node>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>([]);

  useEffect(() => {
    if (projectId) loadData(projectId);
  }, [projectId]);

  async function loadData(id: string) {
    setLoading(true);
    try {
      const [project, objs, lnks, flgs] = await Promise.all([
        getProject(id),
        getStoryObjects(id),
        getStoryLinks(id),
        getContinuityFlags(id),
      ]);
      if (project) setCurrentProject(project);
      setObjects(objs);
      setLinks(lnks);
      setFlags(flgs);
    } catch (err) {
      console.error("Failed to load big picture:", err);
    } finally {
      setLoading(false);
    }
  }

  // Convert story objects + links into ReactFlow nodes/edges
  useEffect(() => {
    const filteredObjects = objects.filter((o) => filterTypes.has(o.type));

    // Auto-layout: arrange by type in columns
    const typeGroups: Record<string, StoryObject[]> = {};
    filteredObjects.forEach((obj) => {
      if (!typeGroups[obj.type]) typeGroups[obj.type] = [];
      typeGroups[obj.type].push(obj);
    });

    const flowNodes: Node[] = [];
    let colIndex = 0;

    Object.entries(typeGroups).forEach(([type, objs]) => {
      objs.forEach((obj, rowIndex) => {
        const objFlags = flags.filter(
          (f) =>
            f.source_object_id === obj.id ||
            f.target_object_id === obj.id ||
            f.scene_id === obj.id
        );

        flowNodes.push({
          id: obj.id,
          type: "storyNode",
          position: { x: colIndex * 280 + 50, y: rowIndex * 160 + 50 },
          data: { object: obj, flags: objFlags },
        });
      });
      colIndex++;
    });

    const flowEdges: Edge[] = links
      .filter(
        (link) =>
          filteredObjects.some((o) => o.id === link.source_id) &&
          filteredObjects.some((o) => o.id === link.target_id)
      )
      .map((link) => ({
        id: link.id,
        source: link.source_id,
        target: link.target_id,
        label: link.link_type.replace(/_/g, " "),
        type: "smoothstep",
        animated: link.link_type === "leads_to" || link.link_type === "caused_by",
        style: {
          stroke: link.link_type === "conflicts_with" ? "#EF476F" : "#3D4455",
          strokeWidth: Math.max(1, link.strength / 3),
        },
        labelStyle: { fontSize: 10, fill: "#9BA3B5" },
      }));

    setNodes(flowNodes);
    setEdges(flowEdges);
  }, [objects, links, flags, filterTypes]);

  const onConnect = useCallback(
    async (connection: Connection) => {
      if (!projectId || !connection.source || !connection.target) return;

      try {
        const link = await createStoryLink({
          project_id: projectId,
          source_id: connection.source,
          target_id: connection.target,
          link_type: "related_to",
          strength: 5,
        });
        setLinks([...links, link]);
        setEdges((eds) =>
          addEdge(
            {
              ...connection,
              id: link.id,
              type: "smoothstep",
              label: "related to",
              labelStyle: { fontSize: 10, fill: "#9BA3B5" },
            },
            eds
          )
        );
      } catch (err) {
        console.error("Failed to create link:", err);
      }
    },
    [projectId, links]
  );

  function toggleFilter(type: string) {
    setFilterTypes((prev) => {
      const next = new Set(prev);
      if (next.has(type)) next.delete(type);
      else next.add(type);
      return next;
    });
  }

  // Story health calculations
  const storyHealth = useMemo(() => {
    const unresolvedFlags = flags.filter((f) => !f.resolved);
    const errors = unresolvedFlags.filter((f) => f.severity === "error").length;
    const warnings = unresolvedFlags.filter((f) => f.severity === "warning").length;
    const scenes = objects.filter((o) => o.type === "scene");
    const weakScenes = scenes.filter((s) => s.status === "draft" || s.status === "rough").length;

    return {
      continuityScore: Math.max(0, 100 - errors * 15 - warnings * 5),
      unresolvedFlags: unresolvedFlags.length,
      weakScenes,
      totalObjects: objects.length,
      totalLinks: links.length,
      totalScenes: scenes.length,
    };
  }, [objects, links, flags]);

  if (!projectId) {
    return (
      <div className="flex items-center justify-center h-full text-text-muted">
        Select a project from Home to see the big picture.
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
          <h2 className="text-sm font-medium text-text-primary">Big Picture</h2>
          <div className="flex items-center gap-0.5 bg-surface-2 rounded-lg p-0.5">
            {VIEWS.map((view) => (
              <button
                key={view.id}
                onClick={() => setBoardView(view.id)}
                className={cn(
                  "flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs transition",
                  boardView === view.id
                    ? "bg-surface-0 text-text-primary shadow-sm"
                    : "text-text-muted hover:text-text-secondary"
                )}
              >
                {view.icon}
                <span className="hidden md:inline">{view.label}</span>
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-3 text-xs text-text-muted">
          <span>{objects.length} objects</span>
          <span>{links.length} links</span>
          {flags.filter((f) => !f.resolved).length > 0 && (
            <span className="flex items-center gap-1 text-amber-400">
              <AlertTriangle className="w-3 h-3" />
              {flags.filter((f) => !f.resolved).length} flags
            </span>
          )}
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 relative">
        {boardView === "health" ? (
          /* Story Health Dashboard */
          <div className="p-6 max-w-4xl mx-auto space-y-6">
            <h2 className="text-xl font-bold text-text-primary">Story Health</h2>
            
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <HealthCard
                label="Continuity"
                value={storyHealth.continuityScore}
                suffix="%"
                color={storyHealth.continuityScore > 80 ? "text-slapp-mint" : storyHealth.continuityScore > 50 ? "text-amber-400" : "text-red-400"}
              />
              <HealthCard
                label="Unresolved Flags"
                value={storyHealth.unresolvedFlags}
                color={storyHealth.unresolvedFlags === 0 ? "text-slapp-mint" : "text-amber-400"}
              />
              <HealthCard
                label="Weak Scenes"
                value={storyHealth.weakScenes}
                suffix={` / ${storyHealth.totalScenes}`}
                color={storyHealth.weakScenes === 0 ? "text-slapp-mint" : "text-amber-400"}
              />
              <HealthCard
                label="Story Objects"
                value={storyHealth.totalObjects}
                color="text-slapp-blue"
              />
            </div>

            {/* Flags List */}
            <div>
              <h3 className="text-sm font-semibold text-text-primary mb-3">
                Continuity Flags
              </h3>
              {flags.filter((f) => !f.resolved).length === 0 ? (
                <div className="flex items-center gap-2 p-4 bg-slapp-mint/10 rounded-xl text-slapp-mint text-sm">
                  <CheckCircle className="w-4 h-4" />
                  No unresolved flags. Story continuity looks good!
                </div>
              ) : (
                <div className="space-y-2">
                  {flags
                    .filter((f) => !f.resolved)
                    .map((flag) => (
                      <div
                        key={flag.id}
                        className="flex items-start gap-3 p-3 bg-surface-2 rounded-xl border border-border-subtle"
                      >
                        {flag.severity === "error" ? (
                          <AlertTriangle className="w-4 h-4 text-red-400 mt-0.5 flex-shrink-0" />
                        ) : flag.severity === "warning" ? (
                          <AlertTriangle className="w-4 h-4 text-amber-400 mt-0.5 flex-shrink-0" />
                        ) : (
                          <Info className="w-4 h-4 text-blue-400 mt-0.5 flex-shrink-0" />
                        )}
                        <div>
                          <p className="text-sm text-text-primary">
                            {flag.message}
                          </p>
                          <p className="text-xs text-text-muted mt-0.5 capitalize">
                            {flag.flag_type.replace(/_/g, " ")}
                          </p>
                        </div>
                      </div>
                    ))}
                </div>
              )}
            </div>
          </div>
        ) : (
          /* Flow / Arc / Causality View */
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            nodeTypes={nodeTypes}
            fitView
            proOptions={{ hideAttribution: true }}
            className="bg-surface-0"
          >
            <Background gap={24} size={1} color="#1F2430" />
            <Controls
              className="!bg-surface-2 !border-border-subtle !rounded-lg"
              showInteractive={false}
            />
            <MiniMap
              nodeColor="#2D3340"
              maskColor="rgba(11, 13, 17, 0.7)"
              className="!bg-surface-1 !border-border-subtle !rounded-lg"
            />

            {/* Filter Panel */}
            <Panel position="top-right">
              <div className="bg-surface-1 border border-border-subtle rounded-xl p-3 shadow-xl">
                <div className="flex items-center gap-2 mb-2">
                  <Filter className="w-3.5 h-3.5 text-text-muted" />
                  <span className="text-xs font-medium text-text-secondary">
                    Show
                  </span>
                </div>
                <div className="flex flex-wrap gap-1.5 max-w-[200px]">
                  {FILTER_TYPES.map((type) => (
                    <button
                      key={type}
                      onClick={() => toggleFilter(type)}
                      className={cn(
                        "px-2 py-0.5 rounded text-[10px] transition capitalize",
                        filterTypes.has(type)
                          ? "bg-slapp-orange/20 text-slapp-orange"
                          : "bg-surface-3 text-text-muted hover:text-text-secondary"
                      )}
                    >
                      {getObjectTypeIcon(type)} {type}
                    </button>
                  ))}
                </div>
              </div>
            </Panel>
          </ReactFlow>
        )}
      </div>
    </div>
  );
}

function HealthCard({
  label,
  value,
  suffix,
  color,
}: {
  label: string;
  value: number;
  suffix?: string;
  color: string;
}) {
  return (
    <div className="bg-surface-1 border border-border-subtle rounded-xl p-4">
      <p className="text-xs text-text-muted mb-1">{label}</p>
      <p className={cn("text-2xl font-bold", color)}>
        {value}
        {suffix && <span className="text-sm font-normal text-text-muted">{suffix}</span>}
      </p>
    </div>
  );
}
