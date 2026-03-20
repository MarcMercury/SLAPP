import { clsx, type ClassValue } from "clsx";

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

export function formatDate(date: string | Date): string {
  return new Date(date).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export function formatRelativeTime(date: string | Date): string {
  const now = new Date();
  const then = new Date(date);
  const diffMs = now.getTime() - then.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return "just now";
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  return formatDate(date);
}

export function truncate(str: string, length: number): string {
  if (str.length <= length) return str;
  return str.slice(0, length) + "…";
}

export function getObjectTypeIcon(type: string): string {
  const icons: Record<string, string> = {
    character: "👤",
    place: "🏛️",
    scene: "🎬",
    sequence: "📑",
    chapter: "📖",
    storyline: "🧵",
    item: "🗡️",
    faction: "⚔️",
    theme: "💡",
    relationship: "💞",
    secret: "🤫",
    mystery: "❓",
    clue: "🔍",
    reveal: "💥",
    visual_moment: "🖼️",
    dialogue_fragment: "💬",
    lore_entry: "📜",
    timeline_event: "⏰",
    rule: "📏",
    unused_idea: "💭",
    alternate_version: "🔀",
  };
  return icons[type] ?? "📄";
}

export function getObjectTypeLabel(type: string): string {
  return type
    .split("_")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

export function getStatusColor(status: string): string {
  const colors: Record<string, string> = {
    draft: "bg-zinc-500",
    rough: "bg-amber-500",
    good: "bg-blue-500",
    polished: "bg-emerald-500",
    locked: "bg-purple-500",
  };
  return colors[status] ?? "bg-zinc-500";
}

export function getSeverityColor(severity: string): string {
  const colors: Record<string, string> = {
    info: "text-blue-400",
    warning: "text-amber-400",
    error: "text-red-400",
  };
  return colors[severity] ?? "text-zinc-400";
}
