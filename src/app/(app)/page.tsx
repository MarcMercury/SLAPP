"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useProjectStore } from "@/lib/stores";
import { getProjects, createProject } from "@/lib/db";
import { formatRelativeTime, truncate } from "@/lib/utils";
import type { Project } from "@/lib/types";
import Image from "next/image";
import {
  Plus,
  BookOpen,
  Film,
  Gamepad2,
  ScrollText,
  LayoutGrid,
  Sparkles,
  ArrowRight,
  Loader2,
} from "lucide-react";

const formatIcons: Record<string, React.ReactNode> = {
  novel: <BookOpen className="w-4 h-4" />,
  screenplay: <Film className="w-4 h-4" />,
  comic: <LayoutGrid className="w-4 h-4" />,
  series: <ScrollText className="w-4 h-4" />,
  game: <Gamepad2 className="w-4 h-4" />,
  mixed: <Sparkles className="w-4 h-4" />,
};

export default function HomePage() {
  const router = useRouter();
  const { projects, setProjects, setCurrentProject } = useProjectStore();
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [showNewProject, setShowNewProject] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newLogline, setNewLogline] = useState("");
  const [newFormat, setNewFormat] = useState<string>("novel");

  useEffect(() => {
    loadProjects();
  }, []);

  async function loadProjects() {
    try {
      const data = await getProjects();
      setProjects(data);
    } catch {
      // Projects table may not exist yet
    } finally {
      setLoading(false);
    }
  }

  async function handleCreateProject(e: React.FormEvent) {
    e.preventDefault();
    if (!newTitle.trim()) return;
    setCreating(true);

    try {
      const project = await createProject({
        title: newTitle.trim(),
        logline: newLogline.trim() || null,
        target_format: newFormat as Project["target_format"],
        genre: null,
        tone: null,
        canon_rules: [],
        major_themes: [],
        ending_state: null,
        style_config: {},
      });
      setCurrentProject(project);
      setProjects([project, ...projects]);
      router.push(`/write?project=${project.id}`);
    } catch (err) {
      console.error("Failed to create project:", err);
    } finally {
      setCreating(false);
    }
  }

  function openProject(project: Project) {
    setCurrentProject(project);
    router.push(`/write?project=${project.id}`);
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-8 h-8 text-slapp-orange animate-spin" />
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-6 py-10">
      {/* Header */}
      <div className="flex items-center justify-between mb-10">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Your Stories</h1>
          <p className="text-sm text-text-secondary mt-1">
            Write it. See it. Shape it.
          </p>
        </div>
        <button
          onClick={() => setShowNewProject(true)}
          className="flex items-center gap-2 px-4 py-2.5 bg-slapp-orange text-white font-medium rounded-xl hover:bg-slapp-orange/90 transition"
        >
          <Plus className="w-4 h-4" />
          New Story
        </button>
      </div>

      {/* New Project Form */}
      {showNewProject && (
        <div className="mb-8 bg-surface-1 border border-border-subtle rounded-2xl p-6 animate-fade-in">
          <h2 className="text-lg font-semibold mb-4">Start a new story</h2>
          <form onSubmit={handleCreateProject} className="space-y-4">
            <div>
              <label className="block text-sm text-text-secondary mb-1.5">
                Title
              </label>
              <input
                type="text"
                value={newTitle}
                onChange={(e) => setNewTitle(e.target.value)}
                placeholder="The untold story of..."
                autoFocus
                className="w-full px-4 py-2.5 bg-surface-2 border border-border-default rounded-xl text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange transition"
              />
            </div>
            <div>
              <label className="block text-sm text-text-secondary mb-1.5">
                Logline (optional)
              </label>
              <input
                type="text"
                value={newLogline}
                onChange={(e) => setNewLogline(e.target.value)}
                placeholder="A brief summary of your story..."
                className="w-full px-4 py-2.5 bg-surface-2 border border-border-default rounded-xl text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange transition"
              />
            </div>
            <div>
              <label className="block text-sm text-text-secondary mb-1.5">
                Format
              </label>
              <div className="flex flex-wrap gap-2">
                {["novel", "screenplay", "comic", "series", "game", "mixed"].map(
                  (format) => (
                    <button
                      key={format}
                      type="button"
                      onClick={() => setNewFormat(format)}
                      className={`flex items-center gap-2 px-3 py-2 rounded-lg text-sm border transition ${
                        newFormat === format
                          ? "border-slapp-orange bg-slapp-orange/10 text-slapp-orange"
                          : "border-border-default text-text-secondary hover:border-border-strong"
                      }`}
                    >
                      {formatIcons[format]}
                      <span className="capitalize">{format}</span>
                    </button>
                  )
                )}
              </div>
            </div>
            <div className="flex gap-3 pt-2">
              <button
                type="submit"
                disabled={creating || !newTitle.trim()}
                className="flex items-center gap-2 px-5 py-2.5 bg-slapp-orange text-white font-medium rounded-xl hover:bg-slapp-orange/90 transition disabled:opacity-50"
              >
                {creating ? (
                  <Loader2 className="w-4 h-4 animate-spin" />
                ) : (
                  <>
                    Create Story
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
              <button
                type="button"
                onClick={() => setShowNewProject(false)}
                className="px-5 py-2.5 text-text-secondary hover:text-text-primary transition"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Projects Grid */}
      {projects.length === 0 && !showNewProject ? (
        <div className="text-center py-20">
          <Image
            src="/Images/slapp-logo.png"
            alt="SLAPP"
            width={120}
            height={120}
            className="mx-auto mb-6 rounded-3xl"
          />
          <h2 className="text-xl font-semibold text-text-primary mb-2">
            Your story starts here
          </h2>
          <p className="text-text-secondary max-w-md mx-auto mb-8">
            SLAPP — the Story Layering And Production Platform. Create characters,
            places, scenes, and visuals in a deeply connected system.
          </p>
          <button
            onClick={() => setShowNewProject(true)}
            className="inline-flex items-center gap-2 px-6 py-3 bg-slapp-orange text-white font-medium rounded-xl hover:bg-slapp-orange/90 transition"
          >
            <Plus className="w-5 h-5" />
            Create Your First Story
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {projects.map((project) => (
            <button
              key={project.id}
              onClick={() => openProject(project)}
              className="group text-left bg-surface-1 border border-border-subtle rounded-2xl p-5 hover:border-border-strong hover:bg-surface-2 transition animate-fade-in"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-2 text-text-muted">
                  {formatIcons[project.target_format] ?? (
                    <BookOpen className="w-4 h-4" />
                  )}
                  <span className="text-xs capitalize">
                    {project.target_format}
                  </span>
                </div>
                <ArrowRight className="w-4 h-4 text-text-muted opacity-0 group-hover:opacity-100 transition" />
              </div>
              <h3 className="font-semibold text-text-primary mb-1 group-hover:text-slapp-orange transition">
                {project.title}
              </h3>
              {project.logline && (
                <p className="text-sm text-text-secondary line-clamp-2">
                  {truncate(project.logline, 100)}
                </p>
              )}
              <div className="mt-4 flex items-center gap-3 text-xs text-text-muted">
                {project.genre && (
                  <span className="px-2 py-0.5 bg-surface-3 rounded-full">
                    {project.genre}
                  </span>
                )}
                <span>{formatRelativeTime(project.updated_at)}</span>
              </div>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
