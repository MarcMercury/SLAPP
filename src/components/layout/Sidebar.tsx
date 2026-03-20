"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { cn } from "@/lib/utils";
import {
  Home,
  PenTool,
  LayoutGrid,
  Network,
  Globe2,
  Clock,
  FolderOpen,
  Sparkles,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Plus,
} from "lucide-react";
import { useUIStore, useProjectStore } from "@/lib/stores";

const navItems = [
  { href: "/", icon: Home, label: "Home", shortLabel: "H" },
  { href: "/write", icon: PenTool, label: "Write", shortLabel: "W" },
  {
    href: "/storyboard",
    icon: LayoutGrid,
    label: "Storyboard",
    shortLabel: "S",
  },
  {
    href: "/bigpicture",
    icon: Network,
    label: "Big Picture",
    shortLabel: "B",
  },
  { href: "/world", icon: Globe2, label: "World", shortLabel: "Wo" },
  { href: "/timeline", icon: Clock, label: "Timeline", shortLabel: "T" },
  { href: "/assets", icon: FolderOpen, label: "Assets", shortLabel: "A" },
  { href: "/ai", icon: Sparkles, label: "AI Studio", shortLabel: "AI" },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { sidebarOpen, setSidebarOpen } = useUIStore();
  const currentProject = useProjectStore((s) => s.currentProject);
  const supabase = createClient();

  async function handleSignOut() {
    await supabase.auth.signOut();
    router.push("/auth");
  }

  return (
    <aside
      className={cn(
        "flex flex-col h-full bg-surface-1 border-r border-border-subtle transition-all duration-200",
        sidebarOpen ? "w-56" : "w-16"
      )}
    >
      {/* Brand */}
      <div className="flex items-center gap-3 px-4 h-14 border-b border-border-subtle">
        <img src="/Images/slapp-icon.png" alt="SLAPP" className="w-8 h-8 rounded-lg flex-shrink-0" />
        {sidebarOpen && (
          <div className="min-w-0">
            <span className="text-sm font-bold text-text-primary tracking-tight block">
              SLAPP
            </span>
            {currentProject && (
              <span className="text-[10px] text-text-muted truncate block">
                {currentProject.title}
              </span>
            )}
          </div>
        )}
      </div>

      {/* Quick Add */}
      <div className="px-3 py-3">
        <Link
          href="/new"
          className={cn(
            "flex items-center gap-2 px-3 py-2 rounded-lg bg-slapp-orange/10 text-slapp-orange hover:bg-slapp-orange/20 transition text-sm font-medium",
            !sidebarOpen && "justify-center"
          )}
        >
          <Plus className="w-4 h-4 flex-shrink-0" />
          {sidebarOpen && <span>New Project</span>}
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 space-y-0.5 overflow-y-auto">
        {navItems.map((item) => {
          const isActive =
            pathname === item.href ||
            (item.href !== "/" && pathname.startsWith(item.href));
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors",
                isActive
                  ? "bg-surface-3 text-text-primary font-medium"
                  : "text-text-secondary hover:text-text-primary hover:bg-surface-2",
                !sidebarOpen && "justify-center"
              )}
              title={!sidebarOpen ? item.label : undefined}
            >
              <item.icon className="w-4 h-4 flex-shrink-0" />
              {sidebarOpen && <span>{item.label}</span>}
            </Link>
          );
        })}
      </nav>

      {/* Bottom */}
      <div className="px-3 py-3 border-t border-border-subtle space-y-1">
        <button
          onClick={handleSignOut}
          className={cn(
            "flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-text-muted hover:text-slapp-coral hover:bg-surface-2 transition w-full",
            !sidebarOpen && "justify-center"
          )}
        >
          <LogOut className="w-4 h-4 flex-shrink-0" />
          {sidebarOpen && <span>Sign out</span>}
        </button>

        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="flex items-center justify-center w-full py-2 text-text-muted hover:text-text-secondary transition"
        >
          {sidebarOpen ? (
            <ChevronLeft className="w-4 h-4" />
          ) : (
            <ChevronRight className="w-4 h-4" />
          )}
        </button>
      </div>
    </aside>
  );
}
