import { NextRequest, NextResponse } from "next/server";
import OpenAI from "openai";

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { source, target, mergeMode, storyContext } = body;

    if (!source || !target || !mergeMode) {
      return NextResponse.json(
        { error: "Missing source, target, or mergeMode" },
        { status: 400 }
      );
    }

    const modeInstructions: Record<string, string> = {
      combine_visual: "Combine these two story elements into a single vivid visual moment. Merge their imagery, settings, and visual atmosphere into one cohesive scene.",
      combine_narrative: "Merge these two story elements into a single narrative beat. Combine their plot significance, character interactions, and dramatic purpose.",
      alternate_version: "Create an alternate version of this story beat by blending elements from both sources into something unexpected but coherent.",
      fuse_settings: "Fuse the settings/locations of these two elements into one unified environment that serves the story.",
      merge_emotions: "Merge the emotional beats of these two story elements into a single, more complex emotional moment.",
      hybrid_scene: "Create a hybrid scene that synthesizes both elements into something greater than the sum of its parts.",
      branching_options: "Generate 2-3 branching options for how these story elements could combine differently.",
    };

    const prompt = `You are SLAPP's merge engine. ${modeInstructions[mergeMode] || modeInstructions.combine_narrative}

SOURCE ELEMENT:
Title: ${source.title}
Summary: ${source.beat_summary || source.description || ""}
Type: ${source.tile_type || source.type || "beat"}
Emotional tone: ${source.emotional_tone || "neutral"}

TARGET ELEMENT:
Title: ${target.title}
Summary: ${target.beat_summary || target.description || ""}
Type: ${target.tile_type || target.type || "beat"}
Emotional tone: ${target.emotional_tone || "neutral"}

${storyContext ? `STORY CONTEXT:\n${storyContext}` : ""}

Respond with JSON:
{
  "merged_title": "...",
  "merged_summary": "...",
  "scene_draft": "...",
  "continuity_implications": ["..."],
  "arc_impact": ["..."],
  "emotional_tone": "..."
}`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a creative story merge engine. Always respond with valid JSON." },
        { role: "user", content: prompt },
      ],
      max_tokens: 1500,
      temperature: 0.8,
      response_format: { type: "json_object" },
    });

    const response = JSON.parse(completion.choices[0]?.message?.content ?? "{}");
    return NextResponse.json(response);
  } catch (err) {
    console.error("SLAPP merge error:", err);
    return NextResponse.json(
      { error: "Merge failed" },
      { status: 500 }
    );
  }
}
