"use client";

import { useState } from "react";
import type { AISpecialist } from "@/lib/types";
import {
  Sparkles,
  Building2,
  Brain,
  BookCheck,
  Camera,
  Globe2,
  MessageSquare,
  Compass,
  FileEdit,
  Send,
  Loader2,
  X,
  Copy,
  Check,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface AIAssistantProps {
  projectId: string;
  storyContext?: string;
  selectedText?: string;
  canonRules?: string[];
  onInsert?: (text: string) => void;
  onClose: () => void;
}

const SPECIALISTS: { id: AISpecialist; label: string; icon: React.ReactNode; description: string }[] = [
  { id: "architect", label: "Structure", icon: <Building2 className="w-4 h-4" />, description: "Plot logic, causality, arcs" },
  { id: "psychologist", label: "Character", icon: <Brain className="w-4 h-4" />, description: "Motivation, voice, psychology" },
  { id: "continuity", label: "Continuity", icon: <BookCheck className="w-4 h-4" />, description: "Facts, timeline, consistency" },
  { id: "visual_director", label: "Visual", icon: <Camera className="w-4 h-4" />, description: "Storyboard, imagery, mood" },
  { id: "worldbuilder", label: "World", icon: <Globe2 className="w-4 h-4" />, description: "Lore, places, systems" },
  { id: "dialogue_coach", label: "Dialogue", icon: <MessageSquare className="w-4 h-4" />, description: "Speech, subtext, voice" },
  { id: "genre_guide", label: "Genre", icon: <Compass className="w-4 h-4" />, description: "Conventions, tropes, style" },
  { id: "dev_editor", label: "Overall", icon: <FileEdit className="w-4 h-4" />, description: "Big picture fixes" },
];

const QUICK_ACTIONS = [
  "Raise the stakes",
  "Make this clearer",
  "Make this weirder",
  "More emotional tension",
  "Increase mystery",
  "Reduce exposition",
  "Tighten dialogue",
  "Stronger ending options",
  "Show alternate path",
];

export function AIAssistant({
  projectId,
  storyContext,
  selectedText,
  canonRules,
  onInsert,
  onClose,
}: AIAssistantProps) {
  const [specialist, setSpecialist] = useState<AISpecialist>("dev_editor");
  const [instruction, setInstruction] = useState("");
  const [response, setResponse] = useState("");
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  async function handleSubmit(customInstruction?: string) {
    const text = customInstruction || instruction;
    if (!text.trim()) return;

    setLoading(true);
    setResponse("");

    try {
      const res = await fetch("/api/ai", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          specialist,
          context: {
            project_id: projectId,
            instruction: text,
            selection: selectedText,
            storyContext,
            canonRules,
          },
        }),
      });

      const data = await res.json();
      setResponse(data.response || data.error || "No response");
    } catch {
      setResponse("Failed to connect to AI. Please try again.");
    } finally {
      setLoading(false);
    }
  }

  function handleCopy() {
    navigator.clipboard.writeText(response);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  return (
    <div className="flex flex-col h-full bg-surface-1 border-l border-border-subtle w-80 flex-shrink-0 animate-slide-in-right">
      {/* Header */}
      <div className="flex items-center justify-between px-4 h-12 border-b border-border-subtle flex-shrink-0">
        <div className="flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-slapp-gold" />
          <span className="text-sm font-medium text-text-primary">AI Studio</span>
        </div>
        <button
          onClick={onClose}
          className="p-1 text-text-muted hover:text-text-primary transition"
        >
          <X className="w-4 h-4" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto">
        {/* Specialist Selector */}
        <div className="p-3 border-b border-border-subtle">
          <label className="block text-xs text-text-muted mb-2">
            Who do you want help from?
          </label>
          <div className="grid grid-cols-2 gap-1.5">
            {SPECIALISTS.map((s) => (
              <button
                key={s.id}
                onClick={() => setSpecialist(s.id)}
                className={cn(
                  "flex items-center gap-2 px-2.5 py-2 rounded-lg text-xs transition",
                  specialist === s.id
                    ? "bg-slapp-orange/15 text-slapp-orange border border-slapp-orange/30"
                    : "bg-surface-2 text-text-secondary hover:text-text-primary border border-transparent"
                )}
              >
                {s.icon}
                <span>{s.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="p-3 border-b border-border-subtle">
          <label className="block text-xs text-text-muted mb-2">Quick actions</label>
          <div className="flex flex-wrap gap-1.5">
            {QUICK_ACTIONS.map((action) => (
              <button
                key={action}
                onClick={() => handleSubmit(action)}
                disabled={loading}
                className="px-2.5 py-1 bg-surface-2 text-text-secondary text-xs rounded-full hover:text-text-primary hover:bg-surface-3 transition disabled:opacity-50"
              >
                {action}
              </button>
            ))}
          </div>
        </div>

        {/* Custom Instruction */}
        <div className="p-3 border-b border-border-subtle">
          <div className="flex gap-2">
            <input
              type="text"
              value={instruction}
              onChange={(e) => setInstruction(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSubmit()}
              placeholder="Ask for help..."
              className="flex-1 px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition"
            />
            <button
              onClick={() => handleSubmit()}
              disabled={loading || !instruction.trim()}
              className="p-2 bg-slapp-orange text-white rounded-lg hover:bg-slapp-orange/90 transition disabled:opacity-50"
            >
              {loading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Send className="w-4 h-4" />
              )}
            </button>
          </div>
          {selectedText && (
            <p className="mt-2 text-[10px] text-text-muted">
              Context: &quot;{selectedText.slice(0, 80)}
              {selectedText.length > 80 ? "..." : ""}&quot;
            </p>
          )}
        </div>

        {/* Response */}
        {(response || loading) && (
          <div className="p-3">
            {loading ? (
              <div className="flex items-center gap-2 text-sm text-text-muted py-4">
                <Loader2 className="w-4 h-4 animate-spin" />
                Thinking...
              </div>
            ) : (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs text-text-muted">Response</span>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={handleCopy}
                      className="p-1 text-text-muted hover:text-text-primary transition"
                      title="Copy"
                    >
                      {copied ? (
                        <Check className="w-3.5 h-3.5 text-slapp-mint" />
                      ) : (
                        <Copy className="w-3.5 h-3.5" />
                      )}
                    </button>
                    {onInsert && (
                      <button
                        onClick={() => onInsert(response)}
                        className="px-2 py-0.5 text-xs bg-slapp-orange/20 text-slapp-orange rounded hover:bg-slapp-orange/30 transition"
                      >
                        Insert
                      </button>
                    )}
                  </div>
                </div>
                <div className="text-sm text-text-secondary whitespace-pre-wrap leading-relaxed bg-surface-2 rounded-lg p-3 border border-border-subtle">
                  {response}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
