import { NextRequest, NextResponse } from "next/server";
import OpenAI from "openai";

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

/**
 * Living Bio API
 * Auto-generates / updates character profiles based on scene content.
 */
export async function POST(req: NextRequest) {
  try {
    const { character, scenes } = await req.json();

    if (!character || !scenes) {
      return NextResponse.json({ error: "character and scenes required" }, { status: 400 });
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `You are the SLAPP Living Bio engine. Given a character and the scenes they appear in, 
you synthesize a living, evolving character profile. Track how the character changes across scenes.
Return ONLY valid JSON. No markdown.`,
        },
        {
          role: "user",
          content: `Character: "${character.name}"
Current metadata: ${JSON.stringify(character.metadata || {})}

Scenes they appear in (in order):
${scenes.map((s: { name: string; content?: string; description?: string }, i: number) => `${i + 1}. "${s.name}" — ${s.content?.slice(0, 500) || s.description || "(no content)"}`).join("\n\n")}

Analyze the character's arc across these scenes and return:
{
  "updated_bio": "A living bio paragraph reflecting who they are NOW (end of latest scene)",
  "arc_summary": "How they've changed from first to last scene",
  "emotional_state": "Current emotional state",
  "knowledge_gained": ["Things they've learned"],
  "relationships_changed": ["Relationship shifts noted"],
  "contradictions_found": ["Any inconsistencies in how they're portrayed"],
  "suggested_metadata": {
    "archetype": "...",
    "role": "...",
    "goal": "...",
    "fear": "...",
    "flaw": "...",
    "voice_note": "..."
  }
}`,
        },
      ],
      temperature: 0.4,
      response_format: { type: "json_object" },
    });

    const result = JSON.parse(completion.choices[0].message.content || "{}");

    return NextResponse.json(result);
  } catch (err) {
    console.error("Living bio error:", err);
    return NextResponse.json(
      { error: "Living bio generation failed" },
      { status: 500 }
    );
  }
}
