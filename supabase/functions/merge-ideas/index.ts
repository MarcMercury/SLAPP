// Supabase Edge Function for AI-powered idea merging
// This proxies OpenAI calls to avoid CORS issues

import "https://deno.land/x/xhr@0.3.0/mod.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Fallback synthesis when AI is unavailable
function synthesizeFallback(idea1: string, idea2: string): string {
  if (!idea1 && !idea2) return 'Combined idea';
  if (!idea1) return idea2;
  if (!idea2) return idea1;
  
  const clean1 = idea1.trim();
  const clean2 = idea2.trim();
  
  // For short phrases, create an exploration prompt
  const words1 = clean1.split(' ').length;
  const words2 = clean2.split(' ').length;
  
  if (words1 <= 3 && words2 <= 3) {
    return `💡 "${clean1}" meets "${clean2}" — explore how these concepts amplify each other`;
  }
  
  // For longer ideas, create a synthesis narrative
  return `✨ Synthesis:\n\n${clean1}\n\n↔️ Combined with:\n\n${clean2}\n\n💭 These ideas together suggest a bigger opportunity. Consider the intersection.`;
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
            content: `You are a strategic thinking assistant for a collaborative brainstorming app called SLAP.

When users drag sticky notes on top of each other (a "SLAP"), your job is to SYNTHESIZE their ideas into something greater than the sum of its parts.

Your approach:
1. UNDERSTAND the intent behind each idea - what problem are they solving? What goal are they working toward?
2. IDENTIFY connections - how do these ideas relate? Do they complement, contrast, or build on each other?
3. SYNTHESIZE creatively - don't just combine words, create a NEW insight that captures the best of both
4. ADD VALUE - contribute your own logical reasoning to enhance the merged idea
5. MAKE IT ACTIONABLE - the result should be something the user can act on

Rules:
- Maximum 3-4 sentences
- Start with the core synthesized insight
- Include any strategic implications or next steps
- Be inspiring but practical
- Never just concatenate - truly THINK about what these ideas mean together`
          },
          {
            role: 'user',
            content: `SLAP! Two ideas have been merged together. Think deeply about what combining these could mean:

IDEA 1: "${idea1}"

IDEA 2: "${idea2}"

What new insight emerges from combining these ideas? What's the bigger picture they're pointing to?`
          }
        ],
        max_tokens: 200,
        temperature: 0.85,
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
