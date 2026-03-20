"use client";

import { useState, useEffect } from "react";
import { cn, getObjectTypeIcon, getObjectTypeLabel, getStatusColor } from "@/lib/utils";
import type { StoryObject, ObjectStatus, CanonState, StoryObjectType } from "@/lib/types";
import {
  X,
  Save,
  Tag,
  Link2,
  Lock,
  Unlock,
  ChevronDown,
} from "lucide-react";

interface ObjectPanelProps {
  object: StoryObject;
  onUpdate: (updates: Partial<StoryObject>) => void;
  onClose: () => void;
}

const STATUS_OPTIONS: ObjectStatus[] = ["draft", "rough", "good", "polished", "locked"];
const CANON_OPTIONS: CanonState[] = ["draft", "canonical", "alternate"];

export function ObjectPanel({ object, onUpdate, onClose }: ObjectPanelProps) {
  const [name, setName] = useState(object.name);
  const [description, setDescription] = useState(object.description || "");
  const [notes, setNotes] = useState(object.notes || "");
  const [status, setStatus] = useState(object.status);
  const [canon, setCanon] = useState(object.canon_state);
  const [tags, setTags] = useState<string[]>(object.tags || []);
  const [newTag, setNewTag] = useState("");
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    setName(object.name);
    setDescription(object.description || "");
    setNotes(object.notes || "");
    setStatus(object.status);
    setCanon(object.canon_state);
    setTags(object.tags || []);
    setDirty(false);
  }, [object.id]);

  function handleSave() {
    onUpdate({
      name,
      description: description || null,
      notes: notes || null,
      status,
      canon_state: canon,
      tags,
    });
    setDirty(false);
  }

  function addTag() {
    if (newTag.trim() && !tags.includes(newTag.trim())) {
      setTags([...tags, newTag.trim()]);
      setNewTag("");
      setDirty(true);
    }
  }

  function removeTag(tag: string) {
    setTags(tags.filter((t) => t !== tag));
    setDirty(true);
  }

  // Build the metadata form based on object type
  const metadata = object.metadata || {};

  return (
    <div className="flex flex-col h-full bg-surface-1 border-l border-border-subtle w-80 flex-shrink-0 animate-slide-in-right">
      {/* Header */}
      <div className="flex items-center justify-between px-4 h-12 border-b border-border-subtle flex-shrink-0">
        <div className="flex items-center gap-2">
          <span>{getObjectTypeIcon(object.type)}</span>
          <span className="text-xs text-text-muted uppercase tracking-wider">
            {getObjectTypeLabel(object.type)}
          </span>
        </div>
        <div className="flex items-center gap-1">
          {dirty && (
            <button
              onClick={handleSave}
              className="flex items-center gap-1 px-2 py-1 bg-slapp-orange/20 text-slapp-orange rounded-md text-xs hover:bg-slapp-orange/30 transition"
            >
              <Save className="w-3 h-3" />
              Save
            </button>
          )}
          <button
            onClick={onClose}
            className="p-1 text-text-muted hover:text-text-primary transition"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-5">
        {/* Name */}
        <div>
          <label className="block text-xs text-text-muted mb-1">Name</label>
          <input
            type="text"
            value={name}
            onChange={(e) => {
              setName(e.target.value);
              setDirty(true);
            }}
            className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary focus:outline-none focus:border-slapp-orange/50 transition"
          />
        </div>

        {/* Status & Canon */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-xs text-text-muted mb-1">Status</label>
            <select
              value={status}
              onChange={(e) => {
                setStatus(e.target.value as ObjectStatus);
                setDirty(true);
              }}
              className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary focus:outline-none focus:border-slapp-orange/50 transition appearance-none"
            >
              {STATUS_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s.charAt(0).toUpperCase() + s.slice(1)}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs text-text-muted mb-1">Canon</label>
            <select
              value={canon}
              onChange={(e) => {
                setCanon(e.target.value as CanonState);
                setDirty(true);
              }}
              className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary focus:outline-none focus:border-slapp-orange/50 transition appearance-none"
            >
              {CANON_OPTIONS.map((c) => (
                <option key={c} value={c}>
                  {c.charAt(0).toUpperCase() + c.slice(1)}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Description */}
        <div>
          <label className="block text-xs text-text-muted mb-1">
            Description
          </label>
          <textarea
            value={description}
            onChange={(e) => {
              setDescription(e.target.value);
              setDirty(true);
            }}
            rows={4}
            className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition resize-none"
            placeholder="Describe this object..."
          />
        </div>

        {/* AI Summary */}
        {object.ai_summary && (
          <div>
            <label className="block text-xs text-text-muted mb-1">
              AI Summary
            </label>
            <div className="px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-secondary">
              {object.ai_summary}
            </div>
          </div>
        )}

        {/* Tags */}
        <div>
          <label className="block text-xs text-text-muted mb-1">Tags</label>
          <div className="flex flex-wrap gap-1.5 mb-2">
            {tags.map((tag) => (
              <span
                key={tag}
                className="flex items-center gap-1 px-2 py-0.5 bg-surface-3 text-text-secondary rounded-full text-xs group"
              >
                <Tag className="w-2.5 h-2.5" />
                {tag}
                <button
                  onClick={() => removeTag(tag)}
                  className="opacity-0 group-hover:opacity-100 transition"
                >
                  <X className="w-2.5 h-2.5" />
                </button>
              </span>
            ))}
          </div>
          <div className="flex gap-2">
            <input
              type="text"
              value={newTag}
              onChange={(e) => setNewTag(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && addTag()}
              placeholder="Add tag..."
              className="flex-1 px-3 py-1.5 bg-surface-2 border border-border-default rounded-lg text-xs text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition"
            />
          </div>
        </div>

        {/* Notes */}
        <div>
          <label className="block text-xs text-text-muted mb-1">Notes</label>
          <textarea
            value={notes}
            onChange={(e) => {
              setNotes(e.target.value);
              setDirty(true);
            }}
            rows={3}
            className="w-full px-3 py-2 bg-surface-2 border border-border-default rounded-lg text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition resize-none"
            placeholder="Internal notes..."
          />
        </div>

        {/* Character-specific fields */}
        {object.type === "character" && (
          <CharacterFields
            metadata={metadata}
            onChange={(m) => {
              onUpdate({ metadata: m });
            }}
          />
        )}

        {/* Scene-specific fields */}
        {object.type === "scene" && (
          <SceneFields
            metadata={metadata}
            onChange={(m) => {
              onUpdate({ metadata: m });
            }}
          />
        )}
      </div>
    </div>
  );
}

function CharacterFields({
  metadata,
  onChange,
}: {
  metadata: Record<string, unknown>;
  onChange: (m: Record<string, unknown>) => void;
}) {
  const fields = [
    { key: "age", label: "Age" },
    { key: "archetype", label: "Archetype" },
    { key: "role_in_story", label: "Role in Story" },
    { key: "external_goal", label: "External Goal" },
    { key: "fear", label: "Fear" },
    { key: "flaw", label: "Flaw" },
    { key: "secret", label: "Secret" },
    { key: "voice", label: "Voice / Speech Pattern" },
    { key: "internal_contradiction", label: "Internal Contradiction" },
  ];

  return (
    <div className="space-y-3 border-t border-border-subtle pt-4">
      <h4 className="text-xs font-semibold text-text-muted uppercase tracking-wider">
        Character Profile
      </h4>
      {fields.map((field) => (
        <div key={field.key}>
          <label className="block text-xs text-text-muted mb-1">
            {field.label}
          </label>
          <input
            type="text"
            value={(metadata[field.key] as string) || ""}
            onChange={(e) =>
              onChange({ ...metadata, [field.key]: e.target.value })
            }
            className="w-full px-3 py-1.5 bg-surface-2 border border-border-default rounded-lg text-xs text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition"
          />
        </div>
      ))}
    </div>
  );
}

function SceneFields({
  metadata,
  onChange,
}: {
  metadata: Record<string, unknown>;
  onChange: (m: Record<string, unknown>) => void;
}) {
  const fields = [
    { key: "purpose", label: "Purpose" },
    { key: "pov", label: "POV Character" },
    { key: "time", label: "Time" },
    { key: "emotional_turn", label: "Emotional Turn" },
    { key: "conflict_type", label: "Conflict Type" },
  ];

  return (
    <div className="space-y-3 border-t border-border-subtle pt-4">
      <h4 className="text-xs font-semibold text-text-muted uppercase tracking-wider">
        Scene Details
      </h4>
      {fields.map((field) => (
        <div key={field.key}>
          <label className="block text-xs text-text-muted mb-1">
            {field.label}
          </label>
          <input
            type="text"
            value={(metadata[field.key] as string) || ""}
            onChange={(e) =>
              onChange({ ...metadata, [field.key]: e.target.value })
            }
            className="w-full px-3 py-1.5 bg-surface-2 border border-border-default rounded-lg text-xs text-text-primary placeholder:text-text-muted focus:outline-none focus:border-slapp-orange/50 transition"
          />
        </div>
      ))}
    </div>
  );
}
