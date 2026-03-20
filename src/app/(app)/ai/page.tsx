"use client";

import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import {
  Bot,
  Brain,
  Eye,
  Heart,
  Shield,
  Palette,
  Globe,
  MessageSquare,
  BookOpen,
  Send,
  Loader2,
  Copy,
  RotateCcw,
} from "lucide-react";
import { cn } from "@/lib/utils";

const SPECIALISTS = [
  { id: "architect", label: "Story Architect", icon: <Brain className="w-5 h-5" />, desc: "Structure, pacing, and plot design", color: "text-purple-400" },
  { id: "psychologist", label: "Character Psychologist", icon: <Heart className="w-5 h-5" />, desc: "Motivation, depth, and authenticity", color: "text-pink-400" },
  { id: "continuity", label: "Continuity Cop", icon: <Shield className="w-5 h-5" />, desc: "Consistency and plot hole detection", color: "text-amber-400" },
  { id: "visual_director", label: "Visual Director", icon: <Eye className="w-5 h-5" />, desc: "Visual storytelling and scene blocking", color: "text-cyan-400" },
  { id: "worldbuilder", label: "World Builder", icon: <Globe className="w-5 h-5" />, desc: "World rules, systems, and atmosphere", color: "text-emerald-400" },
  { id: "dialogue_coach", label: "Dialogue Coach", icon: <MessageSquare className="w-5 h-5" />, desc: "Voice, subtext, and natural speech", color: "text-orange-400" },
  { id: "genre_guide", label: "Genre Guide", icon: <BookOpen className="w-5 h-5" />, desc: "Genre conventions and expectations", color: "text-indigo-400" },
  { id: "dev_editor", label: "Dev Editor", icon: <Palette className="w-5 h-5" />, desc: "Prose quality and developmental editing", color: "text-rose-400" },
] as const;

type Message = { role: "user" | "assistant"; content: string; specialist?: string };

export default function AIStudioPage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-full"><Loader2 className="w-8 h-8 text-slapp-orange animate-spin" /></div>}>
      <AIStudioInner />
    </Suspense>
  );
}

function AIStudioInner() {
  const searchParams = useSearchParams();
  const projectId = searchParams.get("project");

  const [activeSpecialist, setActiveSpecialist] = useState("architect");
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSend() {
    if (!input.trim() || loading) return;
    const userMsg: Message = { role: "user", content: input.trim() };
    setMessages((prev) => [...prev, userMsg]);
    setInput("");
    setLoading(true);

    try {
      const res = await fetch("/api/ai", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          specialist: activeSpecialist,
          context: {
            instruction: userMsg.content,
            storyContext: projectId ? `Project: ${projectId}` : undefined,
          },
        }),
      });
      const data = await res.json();
      setMessages((prev) => [
        ...prev,
        { role: "assistant", content: data.response || data.error || "No response", specialist: activeSpecialist },
      ]);
    } catch {
      setMessages((prev) => [
        ...prev,
        { role: "assistant", content: "Failed to get response. Check your connection.", specialist: activeSpecialist },
      ]);
    } finally {
      setLoading(false);
    }
  }

  function clearChat() {
    setMessages([]);
  }

  const spec = SPECIALISTS.find((s) => s.id === activeSpecialist)!;

  if (!projectId) {
    return (
      <div className="flex items-center justify-center h-full text-text-muted">
        Select a project from Home to use AI Studio.
      </div>
    );
  }

  return (
    <div className="flex h-full">
      {/* Left: Specialist Selector */}
      <div className="w-64 border-r border-border-subtle bg-surface-1 flex-shrink-0 flex flex-col">
        <div className="p-3 border-b border-border-subtle">
          <h2 className="text-sm font-semibold text-text-primary flex items-center gap-2">
            <Bot className="w-4 h-4 text-slapp-orange" />
            AI Specialists
          </h2>
        </div>

        <div className="flex-1 overflow-y-auto p-2 space-y-1">
          {SPECIALISTS.map((s) => (
            <button
              key={s.id}
              onClick={() => setActiveSpecialist(s.id)}
              className={cn(
                "w-full text-left p-3 rounded-xl transition",
                activeSpecialist === s.id
                  ? "bg-surface-2 border border-border-default"
                  : "hover:bg-surface-2"
              )}
            >
              <div className="flex items-center gap-2.5">
                <span className={s.color}>{s.icon}</span>
                <div>
                  <p className="text-sm font-medium text-text-primary">{s.label}</p>
                  <p className="text-[10px] text-text-muted">{s.desc}</p>
                </div>
              </div>
            </button>
          ))}
        </div>
      </div>

      {/* Right: Chat */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-4 h-12 border-b border-border-subtle">
          <div className="flex items-center gap-2">
            <span className={spec.color}>{spec.icon}</span>
            <span className="text-sm font-medium text-text-primary">{spec.label}</span>
          </div>
          <button
            onClick={clearChat}
            className="text-text-muted hover:text-text-secondary transition"
            title="Clear chat"
          >
            <RotateCcw className="w-4 h-4" />
          </button>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.length === 0 && (
            <div className="text-center py-16 text-text-muted text-sm space-y-2">
              <Bot className="w-10 h-10 text-slapp-orange/30 mx-auto" />
              <p>Ask {spec.label} anything about your story.</p>
              <p className="text-xs">{spec.desc}</p>
            </div>
          )}

          {messages.map((msg, i) => (
            <div
              key={i}
              className={cn(
                "max-w-[80%] rounded-xl p-3",
                msg.role === "user"
                  ? "ml-auto bg-slapp-orange/10 text-text-primary"
                  : "bg-surface-2 text-text-secondary"
              )}
            >
              {msg.role === "assistant" && msg.specialist && (
                <p className="text-[10px] text-text-muted mb-1 capitalize">
                  {SPECIALISTS.find((s) => s.id === msg.specialist)?.label}
                </p>
              )}
              <p className="text-sm whitespace-pre-wrap">{msg.content}</p>
              {msg.role === "assistant" && (
                <button
                  onClick={() => navigator.clipboard.writeText(msg.content)}
                  className="mt-2 text-text-muted hover:text-text-secondary transition"
                >
                  <Copy className="w-3 h-3" />
                </button>
              )}
            </div>
          ))}

          {loading && (
            <div className="flex items-center gap-2 text-text-muted text-sm">
              <Loader2 className="w-4 h-4 animate-spin" />
              {spec.label} is thinking...
            </div>
          )}
        </div>

        {/* Input */}
        <div className="p-4 border-t border-border-subtle">
          <div className="flex items-center gap-2">
            <input
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && !e.shiftKey && handleSend()}
              placeholder={`Ask ${spec.label}...`}
              className="flex-1 bg-surface-2 border border-border-subtle rounded-xl px-4 py-2.5 text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50"
            />
            <button
              onClick={handleSend}
              disabled={loading || !input.trim()}
              className="bg-slapp-orange hover:bg-slapp-orange/90 text-white rounded-xl p-2.5 disabled:opacity-50 transition"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
