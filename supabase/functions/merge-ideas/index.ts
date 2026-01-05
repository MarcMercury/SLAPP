// Supabase Edge Function for AI-powered idea merging
// This proxies OpenAI calls to avoid CORS issues
// Uses Context-Aware Routing to detect note type and merge appropriately

import "https://deno.land/x/xhr@0.3.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// The Brain: Context-aware system prompt that detects intent and merges accordingly
const SYSTEM_PROMPT = `You are the "Synthesis Engine" for SLAP, a sticky note app. Merge two notes into one "Super Note."

STEP 1: ANALYZE - Detect the intent of both notes:

📋 LIST KEEPER (To-dos, groceries, bullet points, numbered items)
   → IF notes contain lists, bullets, commas, or short fragments
   → ACTION: Combine into a clean bulleted list. Remove duplicates. Keep terse. NO paragraphs.

📖 STORYTELLER (Creative writing, brainstorming, concepts, ideas)
   → IF notes are sentences, paragraphs, or abstract concepts
   → ACTION: Weave into ONE cohesive sentence or short phrase. Find the deeper connection.

📅 SCHEDULER (Dates, times, plans, meetings)
   → IF notes contain times, dates, or locations
   → ACTION: Create a structured mini-agenda. Chronological order.

⚖️ DEBATER (Conflicting or contrasting ideas)
   → IF notes contradict or present alternatives
   → ACTION: Present both clearly: "X vs Y" or "Consider both: X and Y"

STEP 2: EXECUTE - Merge using the appropriate rule above.

RULES:
- Output ONLY the merged content (no labels, no "Category:", no explanations)
- Keep output BRIEF - suitable for a sticky note (max 2-3 lines)
- Lists stay as lists. Stories stay as stories.
- Be practical, not flowery.`;

// Fallback synthesis when AI is unavailable
function synthesizeFallback(idea1: string, idea2: string): string {
  if (!idea1 && !idea2) return 'Combined idea';
  if (!idea1) return idea2;
  if (!idea2) return idea1;
  
  const clean1 = idea1.trim();
  const clean2 = idea2.trim();
  
  // Detect if either looks like a list (has bullets, numbers, or commas)
  const listPattern = /^[-•*\d]|,\s+\w|;\s+\w/;
  const isListy = listPattern.test(clean1) || listPattern.test(clean2) || 
                  (clean1.split(',').length > 2) || (clean2.split(',').length > 2);
  
  if (isListy) {
    // Combine as list items
    const items1 = clean1.split(/[,;\n]/).map(s => s.trim()).filter(s => s);
    const items2 = clean2.split(/[,;\n]/).map(s => s.trim()).filter(s => s);
    const combined = [...new Set([...items1, ...items2])];
    return combined.map(item => `• ${item.replace(/^[-•*\d.)\s]+/, '')}`).join('\n');
  }
  
  // For short phrases, keep it simple
  const words1 = clean1.split(' ').length;
  const words2 = clean2.split(' ').length;
  
  if (words1 <= 5 && words2 <= 5) {
    return `${clean1} + ${clean2}`;
  }
  
  return `${clean1}\n↔️\n${clean2}`;
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { idea1, idea2 } = await req.json();

    const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
    console.log('[merge-ideas] API key exists:', !!openaiApiKey);
    console.log('[merge-ideas] API key length:', openaiApiKey?.length || 0);
    
    if (!openaiApiKey) {
      // Fallback to simple merge if no API key
      console.log('[merge-ideas] No API key, using fallback');
      const merged = synthesizeFallback(idea1, idea2);
      return new Response(
        JSON.stringify({ merged }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('[merge-ideas] Calling OpenAI...');
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'system',
            content: SYSTEM_PROMPT
          },
          {
            role: 'user',
            content: `Note A: "${idea1}"\n\nNote B: "${idea2}"`
          }
        ],
        max_tokens: 150,
        temperature: 0.4, // Lower = more logical/practical, Higher = more creative
      }),
    });

    const data = await response.json();
    console.log('[merge-ideas] OpenAI response status:', response.status);
    console.log('[merge-ideas] OpenAI response:', JSON.stringify(data).substring(0, 500));
    
    if (data.choices && data.choices[0]?.message?.content) {
      const merged = data.choices[0].message.content.trim();
      console.log('[merge-ideas] AI merged result:', merged);
      return new Response(
        JSON.stringify({ merged }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    } else {
      // Fallback
      console.log('[merge-ideas] No choices in response, using fallback');
      const merged = synthesizeFallback(idea1, idea2);
      return new Response(
        JSON.stringify({ merged }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});
