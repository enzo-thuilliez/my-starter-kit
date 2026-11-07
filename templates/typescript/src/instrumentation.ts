/**
 * Next.js calls register() once per server start.
 * Langfuse tracing turns on only when its keys are set.
 */
export async function register() {
  if (process.env.NEXT_RUNTIME !== "nodejs") return;
  if (!process.env.LANGFUSE_PUBLIC_KEY || !process.env.LANGFUSE_SECRET_KEY)
    return;

  const { registerTelemetry } = await import("ai");
  const { LangfuseSpanProcessor } = await import("@langfuse/otel");
  const { LangfuseVercelAiSdkIntegration } = await import(
    "@langfuse/vercel-ai-sdk"
  );
  const { NodeSDK } = await import("@opentelemetry/sdk-node");

  new NodeSDK({ spanProcessors: [new LangfuseSpanProcessor()] }).start();
  registerTelemetry(new LangfuseVercelAiSdkIntegration());
}
