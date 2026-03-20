"use client";

import { Suspense, useEffect, useState, useCallback } from "react";
import { useSearchParams } from "next/navigation";
import { useProjectStore, useStoryObjectStore } from "@/lib/stores";
import {
  getProject,
  getStoryObjects,
  createStoryObject,
  updateStoryObject,
  deleteStoryObject,
} from "@/lib/db";
import type { StoryObject, StoryObjectType } from "@/lib/types";
import { ObjectSidebar } from "@/components/write/ObjectSidebar";
import { SceneEditor } from "@/components/write/SceneEditor";
import { ObjectPanel } from "@/components/write/ObjectPanel";
import { AIAssistant } from "@/components/write/AIAssistant";
import { Loader2, Sparkles, PanelRightOpen, PanelRightClose } from "lucide-react";

export default function WritePage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full"><div className="w-8 h-8 border-2 border-slapp-orange border-t-transparent rounded-full animate-spin" /></div>}>
      <WriteInner />
    </Suspense>
  );
}

function WriteInner() {
  const searchParams = useSearchParams();
  const projectId = searchParams.get("project");

  const { currentProject, setCurrentProject } = useProjectStore();
  const { objects, setObjects, selectedObjectId, setSelectedObjectId } =
    useStoryObjectStore();

  const [loading, setLoading] = useState(true);
  const [showAI, setShowAI] = useState(false);
  const [sceneContent, setSceneContent] = useState("");

  // Load project and objects
  useEffect(() => {
    if (projectId) {
      loadProjectData(projectId);
    }
  }, [projectId]);

  async function loadProjectData(id: string) {
    setLoading(true);
    try {
      const [project, objs] = await Promise.all([
        getProject(id),
        getStoryObjects(id),
      ]);
      if (project) setCurrentProject(project);
      setObjects(objs);

      // Auto-select first scene if exists
      const firstScene = objs.find((o) => o.type === "scene");
      if (firstScene) {
        setSelectedObjectId(firstScene.id);
        setSceneContent((firstScene.metadata as Record<string, string>)?.content || "");
      }
    } catch (err) {
      console.error("Failed to load project:", err);
    } finally {
      setLoading(false);
    }
  }

  // When selecting an object, load its content
  useEffect(() => {
    const obj = objects.find((o) => o.id === selectedObjectId);
    if (obj?.type === "scene") {
      setSceneContent((obj.metadata as Record<string, string>)?.content || "");
    }
  }, [selectedObjectId, objects]);

  const selectedObject = objects.find((o) => o.id === selectedObjectId);

  async function handleCreateObject(type: StoryObjectType) {
    if (!projectId) return;

    const defaultNames: Record<string, string> = {
      scene: "New Scene",
      chapter: "New Chapter",
      character: "New Character",
      place: "New Place",
      item: "New Item",
      unused_idea: "Untitled Idea",
    };

    try {
      const obj = await createStoryObject({
        project_id: projectId,
        type,
        name: defaultNames[type] || `New ${type.replace("_", " ")}`,
        sort_order: objects.filter((o) => o.type === type).length,
        tags: [],
        metadata: type === "scene" ? { content: "" } : {},
      });
      setObjects([...objects, obj]);
      setSelectedObjectId(obj.id);
    } catch (err) {
      console.error("Failed to create object:", err);
    }
  }

  async function handleUpdateObject(updates: Partial<StoryObject>) {
    if (!selectedObjectId) return;
    try {
      const updated = await updateStoryObject(selectedObjectId, updates);
      setObjects(
        objects.map((o) => (o.id === selectedObjectId ? updated : o))
      );
    } catch (err) {
      console.error("Failed to update object:", err);
    }
  }

  async function handleDeleteObject(id: string) {
    try {
      await deleteStoryObject(id);
      setObjects(objects.filter((o) => o.id !== id));
      if (selectedObjectId === id) {
        setSelectedObjectId(null);
        setSceneContent("");
      }
    } catch (err) {
      console.error("Failed to delete object:", err);
    }
  }

  // Auto-save scene content with debounce
  const handleSceneContentChange = useCallback(
    (content: string) => {
      setSceneContent(content);
      // Debounced save
      if (selectedObjectId && selectedObject?.type === "scene") {
        const timeout = setTimeout(() => {
          updateStoryObject(selectedObjectId, {
            metadata: { ...(selectedObject.metadata || {}), content },
          }).catch(console.error);
        }, 1000);
        return () => clearTimeout(timeout);
      }
    },
    [selectedObjectId, selectedObject]
  );

  if (!projectId) {
    return (
      <div className="flex items-center justify-center h-full text-text-muted">
        Select a project from the Home page to start writing.
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
      {/* Object Sidebar */}
      <ObjectSidebar
        objects={objects}
        selectedId={selectedObjectId}
        onSelect={setSelectedObjectId}
        onCreate={handleCreateObject}
        onDelete={handleDeleteObject}
      />

      {/* Main Editor Area */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Top bar */}
        <div className="flex items-center justify-between px-4 h-12 border-b border-border-subtle bg-surface-0 flex-shrink-0">
          <div className="flex items-center gap-3">
            <h2 className="text-sm font-medium text-text-primary truncate">
              {currentProject?.title || "Untitled Project"}
            </h2>
            {selectedObject && (
              <span className="text-xs text-text-muted">
                / {selectedObject.name}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setShowAI(!showAI)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs transition ${
                showAI
                  ? "bg-slapp-gold/20 text-slapp-gold"
                  : "bg-surface-2 text-text-secondary hover:text-text-primary"
              }`}
            >
              <Sparkles className="w-3.5 h-3.5" />
              AI
            </button>
          </div>
        </div>

        {/* Editor */}
        {selectedObject?.type === "scene" ? (
          <SceneEditor
            content={sceneContent}
            onUpdate={handleSceneContentChange}
            placeholder={`Start writing "${selectedObject.name}"...`}
          />
        ) : selectedObject ? (
          <div className="flex-1 flex items-center justify-center text-text-muted">
            <p className="text-sm">
              Select a scene to start writing, or edit properties in the right
              panel.
            </p>
          </div>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-text-muted gap-4">
            <p className="text-sm">
              Create a scene to start writing, or add characters and world
              elements.
            </p>
            <button
              onClick={() => handleCreateObject("scene")}
              className="px-4 py-2 bg-slapp-orange text-white rounded-lg text-sm hover:bg-slapp-orange/90 transition"
            >
              Create First Scene
            </button>
          </div>
        )}
      </div>

      {/* Right Panel: Object Properties or AI */}
      {showAI && projectId ? (
        <AIAssistant
          projectId={projectId}
          storyContext={sceneContent}
          canonRules={currentProject?.canon_rules || []}
          onInsert={(text) => {
            setSceneContent(sceneContent + "\n\n" + text);
          }}
          onClose={() => setShowAI(false)}
        />
      ) : selectedObject ? (
        <ObjectPanel
          object={selectedObject}
          onUpdate={handleUpdateObject}
          onClose={() => setSelectedObjectId(null)}
        />
      ) : null}
    </div>
  );
}
