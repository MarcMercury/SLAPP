import { create } from "zustand";
import type {
  Project,
  StoryObject,
  StoryTile,
  StoryLink,
  ContinuityFlag,
  ComplexityMode,
} from "@/lib/types";

// ── Project Store ───────────────────────────────────────────

interface ProjectState {
  currentProject: Project | null;
  projects: Project[];
  setCurrentProject: (project: Project | null) => void;
  setProjects: (projects: Project[]) => void;
  updateProject: (updates: Partial<Project>) => void;
}

export const useProjectStore = create<ProjectState>((set) => ({
  currentProject: null,
  projects: [],
  setCurrentProject: (project) => set({ currentProject: project }),
  setProjects: (projects) => set({ projects }),
  updateProject: (updates) =>
    set((state) => ({
      currentProject: state.currentProject
        ? { ...state.currentProject, ...updates }
        : null,
    })),
}));

// ── Story Objects Store ─────────────────────────────────────

interface StoryObjectState {
  objects: StoryObject[];
  selectedObjectId: string | null;
  setObjects: (objects: StoryObject[]) => void;
  addObject: (object: StoryObject) => void;
  updateObject: (id: string, updates: Partial<StoryObject>) => void;
  removeObject: (id: string) => void;
  setSelectedObjectId: (id: string | null) => void;
}

export const useStoryObjectStore = create<StoryObjectState>((set) => ({
  objects: [],
  selectedObjectId: null,
  setObjects: (objects) => set({ objects }),
  addObject: (object) =>
    set((state) => ({ objects: [...state.objects, object] })),
  updateObject: (id, updates) =>
    set((state) => ({
      objects: state.objects.map((o) =>
        o.id === id ? { ...o, ...updates } : o
      ),
    })),
  removeObject: (id) =>
    set((state) => ({
      objects: state.objects.filter((o) => o.id !== id),
      selectedObjectId:
        state.selectedObjectId === id ? null : state.selectedObjectId,
    })),
  setSelectedObjectId: (id) => set({ selectedObjectId: id }),
}));

// ── Storyboard Store ────────────────────────────────────────

interface StoryboardState {
  tiles: StoryTile[];
  selectedTileId: string | null;
  activeLane: string;
  viewMode: "beat" | "cinematic" | "comic" | "moodboard" | "structure";
  setTiles: (tiles: StoryTile[]) => void;
  addTile: (tile: StoryTile) => void;
  updateTile: (id: string, updates: Partial<StoryTile>) => void;
  removeTile: (id: string) => void;
  reorderTiles: (tiles: StoryTile[]) => void;
  setSelectedTileId: (id: string | null) => void;
  setActiveLane: (lane: string) => void;
  setViewMode: (
    mode: "beat" | "cinematic" | "comic" | "moodboard" | "structure"
  ) => void;
}

export const useStoryboardStore = create<StoryboardState>((set) => ({
  tiles: [],
  selectedTileId: null,
  activeLane: "main_plot",
  viewMode: "beat",
  setTiles: (tiles) => set({ tiles }),
  addTile: (tile) => set((state) => ({ tiles: [...state.tiles, tile] })),
  updateTile: (id, updates) =>
    set((state) => ({
      tiles: state.tiles.map((t) =>
        t.id === id ? { ...t, ...updates } : t
      ),
    })),
  removeTile: (id) =>
    set((state) => ({
      tiles: state.tiles.filter((t) => t.id !== id),
      selectedTileId:
        state.selectedTileId === id ? null : state.selectedTileId,
    })),
  reorderTiles: (tiles) => set({ tiles }),
  setSelectedTileId: (id) => set({ selectedTileId: id }),
  setActiveLane: (lane) => set({ activeLane: lane }),
  setViewMode: (mode) => set({ viewMode: mode }),
}));

// ── Links Store ─────────────────────────────────────────────

interface LinksState {
  links: StoryLink[];
  setLinks: (links: StoryLink[]) => void;
  addLink: (link: StoryLink) => void;
  removeLink: (id: string) => void;
}

export const useLinksStore = create<LinksState>((set) => ({
  links: [],
  setLinks: (links) => set({ links }),
  addLink: (link) => set((state) => ({ links: [...state.links, link] })),
  removeLink: (id) =>
    set((state) => ({ links: state.links.filter((l) => l.id !== id) })),
}));

// ── Continuity Store ────────────────────────────────────────

interface ContinuityState {
  flags: ContinuityFlag[];
  setFlags: (flags: ContinuityFlag[]) => void;
  addFlag: (flag: ContinuityFlag) => void;
  resolveFlag: (id: string) => void;
}

export const useContinuityStore = create<ContinuityState>((set) => ({
  flags: [],
  setFlags: (flags) => set({ flags }),
  addFlag: (flag) => set((state) => ({ flags: [...state.flags, flag] })),
  resolveFlag: (id) =>
    set((state) => ({
      flags: state.flags.map((f) =>
        f.id === id ? { ...f, resolved: true } : f
      ),
    })),
}));

// ── UI Store ────────────────────────────────────────────────

interface UIState {
  sidebarOpen: boolean;
  rightPanelOpen: boolean;
  rightPanelContent: "properties" | "ai" | "links" | null;
  activeView: "write" | "storyboard" | "bigpicture" | "world" | "timeline";
  complexityMode: ComplexityMode;
  commandPaletteOpen: boolean;
  setSidebarOpen: (open: boolean) => void;
  setRightPanelOpen: (open: boolean) => void;
  setRightPanelContent: (
    content: "properties" | "ai" | "links" | null
  ) => void;
  setActiveView: (
    view: "write" | "storyboard" | "bigpicture" | "world" | "timeline"
  ) => void;
  setComplexityMode: (mode: ComplexityMode) => void;
  setCommandPaletteOpen: (open: boolean) => void;
}

export const useUIStore = create<UIState>((set) => ({
  sidebarOpen: true,
  rightPanelOpen: false,
  rightPanelContent: null,
  activeView: "write",
  complexityMode: "creator",
  commandPaletteOpen: false,
  setSidebarOpen: (open) => set({ sidebarOpen: open }),
  setRightPanelOpen: (open) => set({ rightPanelOpen: open }),
  setRightPanelContent: (content) =>
    set({ rightPanelContent: content, rightPanelOpen: !!content }),
  setActiveView: (view) => set({ activeView: view }),
  setComplexityMode: (mode) => set({ complexityMode: mode }),
  setCommandPaletteOpen: (open) => set({ commandPaletteOpen: open }),
}));
