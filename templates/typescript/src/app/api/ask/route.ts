import { z } from "zod";
import { complete } from "@/lib/llm";

const body = z.object({ prompt: z.string().min(1) });

export async function POST(request: Request) {
  const parsed = body.safeParse(await request.json());
  if (!parsed.success) {
    return Response.json(
      { error: z.prettifyError(parsed.error) },
      { status: 400 },
    );
  }
  const answer = await complete(parsed.data.prompt, { functionId: "ask" });
  return Response.json({ answer });
}
