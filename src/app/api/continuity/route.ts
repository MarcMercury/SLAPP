import { NextRequest, NextResponse } from "next/server";
import OpenAI from "openai";

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

/**
 * Continuity Check API
 * Analyzes story objects for contradictions, timeline issues, and plot holes.
 */
export async function POST(req: NextRequest) {
  try {
    const { objects, links, existingFlags } = await req.json();

    if (!objects || !Array.isArray(objects)) {
      return NextResponse.json({ error: "objects array required" }, { status: 400 });
    }

    const prompt = buildContinuityPrompt(objects, links, existingFlags);

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are the SLAPP Continuity Engine — a ruthless, detail-obsessed story continuity checker. 
You analyze story objects (characters, scenes, places, items, etc.) and their relationships to find:
- Timeline contradictions (event ordering conflicts)
- Character inconsistencies (abilities, knowledge, personality shifts without justification)
- Plot holes (unresolved setups, dangling threads)
- World-building contradictions (rules established then broken)
- Missing connections (characters who should know each other but have no link)
- Tone drift (scenes that break established tone without purpose)

Return ONLY valid JSON. No markdown, no explanation outside JSON.`,
        },
        { role: "user", content: prompt },
      ],
      temperature: 0.3,
      response_format: { type: "json_object" },
    });

    const result = JSON.parse(completion.choices[0].message.content || "{}");

    return NextResponse.json(result);
  } catch (err) {
    console.error("Continuity check error:", err);
    return NextResponse.json(
      { error: "Continuity check failed" },
      { status: 500 }
    );
  }
}

function buildContinuityPrompt(
  objects: Array<{ id: string; name: string; type: string; description?: string; content?: string; metadata?: Record<string, unknown>; tags?: string[] }>,
  links: Array<{ source_id: string; target_id: string; link_type: string }> | undefined,
  existingFlags: Array<{ flag_type: string; message: string }> | undefined
): string {
  const objectSummary = objects
    .map(
      (o) =>
        `[${o.type}] "${o.name}" (id: ${o.id})${o.description ? ` — ${o.description}` : ""}${
          o.metadata ? ` | metadata: ${JSON.stringify(o.metadata)}` : ""
        }`
    )
    .join("\n");

  const linkSummary = links
    ? links
        .map((l) => {
          const src = objects.find((o) => o.id === l.source_id);
          const tgt = objects.find((o) => o.id === l.target_id);
          return `"${src?.name || l.source_id}" —[${l.link_type}]→ "${tgt?.name || l.target_id}"`;
        })
        .join("\n")
    : "No links defined yet.";

  const flagSummary =
    existingFlags && existingFlags.length > 0
      ? existingFlags.map((f) => `- [${f.flag_type}] ${f.message}`).join("\n")
      : "No existing flags.";

  return `Analyze these story objects for continuity issues.

STORY OBJECTS:
${objectSummary}

RELATIONSHIPS:
${linkSummary}

EXISTING FLAGS (already known):
${flagSummary}

Return JSON with this structure:
{
  "flags": [
    {
      "flag_type": "timeline_conflict" | "character_inconsistency" | "plot_hole" | "world_contradiction" | "missing_connection" | "tone_drift" | "knowledge_error" | "motivation_gap" | "power_inconsistency",
      "severity": "error" | "warning" | "info",
      "message": "Clear description of the issue",
      "source_object_name": "Name of first object involved",
      "target_object_name": "Name of second object involved (if applicable)",
      "suggestion": "How to fix it"
    }
  ],
  "health_score": 0-100,
  "summary": "One paragraph overall assessment"
}

Only return NEW flags not already in existing flags. Be thorough but avoid false positives.`;
}
