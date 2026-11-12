import Anthropic from "@anthropic-ai/sdk";

export interface Env {
  ANTHROPIC_API_KEY: string;
  WATCH_TOKEN: string;
}

// The only questions the proxy will answer. Keys must match the ids in
// watch-app/source/Prompts.mc.
const PROMPTS: Record<string, string> = {
  recovery:
    "How recovered am I right now, and how hard should I train today?",
  today:
    "Suggest one specific run for today (type, duration or distance, and effort or heart-rate zone).",
  lastrun:
    "Give me a short review of my most recent activity and one thing to improve next time.",
  pacing: "Give me one practical pacing tip for my next run, based on my recent runs.",
  motivate: "Give me a short, genuine boost of motivation to get out the door.",
};

const SYSTEM = `You are a running coach whose answers appear on a small round watch screen.
Rules:
- Answer in at most 60 words, plain text only. No markdown, no bullet symbols, no emoji.
- Use the athlete's watch data when it is relevant. Give concrete numbers (minutes, km, pace, heart-rate zone).
- If a value you would need is missing, work with what you have; don't ask questions back.
- Distances are km and paces are min/km.
- You are not a doctor. If the data suggests illness or injury, say to rest and check with a professional.`;

const client = (env: Env) => new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method !== "POST" || url.pathname !== "/ask") {
      return json({ error: "Not found" }, 404);
    }
    if (!safeEqual(request.headers.get("X-Watch-Token") ?? "", env.WATCH_TOKEN ?? "")) {
      return json({ error: "Bad token" }, 401);
    }

    let body: { prompt?: unknown; data?: unknown };
    try {
      body = await request.json();
    } catch {
      return json({ error: "Bad JSON" }, 400);
    }

    const question = typeof body.prompt === "string" ? PROMPTS[body.prompt] : undefined;
    if (!question) {
      return json({ error: "Unknown question" }, 400);
    }
    // Watch data is small; cap it anyway so nobody can send us a novel.
    const data = JSON.stringify(body.data ?? {}).slice(0, 4000);

    try {
      const response = await client(env).beta.messages.create({
        model: "claude-opus-5-5",
        max_tokens: 4000,
        // Low effort keeps replies quick; this is a short coaching answer.
        output_config: { effort: "low" },
        // If the model declines on a safety classifier, retry on a fallback model.
        betas: ["server-side-fallback-2026-07-01"],
        fallbacks: "default",
        system: SYSTEM,
        messages: [
          {
            role: "user",
            content: `My watch data right now (JSON):\n${data}\n\nQuestion: ${question}`,
          },
        ],
      });

      if (response.stop_reason === "refusal") {
        return json({ reply: "Sorry, I can't help with that one. Try another question." });
      }

      const text = response.content
        .filter((b): b is Anthropic.Beta.BetaTextBlock => b.type === "text")
        .map((b) => b.text)
        .join("\n");

      return json({ reply: forWatch(text) || "No answer came back. Try again." });
    } catch (error) {
      if (error instanceof Anthropic.AuthenticationError) {
        return json({ error: "Proxy's Anthropic API key is invalid" }, 502);
      } else if (error instanceof Anthropic.RateLimitError) {
        return json({ error: "Rate limited, try again in a minute" }, 503);
      } else if (error instanceof Anthropic.APIError) {
        console.error("Anthropic API error", error.status, error.message);
        return json({ error: `AI service error ${error.status ?? ""}`.trim() }, 502);
      }
      console.error(error);
      return json({ error: "Proxy error" }, 500);
    }
  },
};

// Watch fonts cover basic Latin only, and the screen is tiny: strip markdown,
// swap fancy punctuation for ASCII, and cap the length.
function forWatch(text: string): string {
  return text
    .replace(/[*_#`]/g, "")
    .replace(/[‘’]/g, "'")
    .replace(/[“”]/g, '"')
    .replace(/[–—]/g, "-")
    .replace(/…/g, "...")
    .replace(/[^\x20-\x7E\n]/g, "")
    .replace(/\n{2,}/g, "\n")
    .trim()
    .slice(0, 600);
}

function json(obj: unknown, status = 200): Response {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function safeEqual(a: string, b: string): boolean {
  if (!b || a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
