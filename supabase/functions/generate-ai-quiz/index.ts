const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return jsonResponse({ error: "Use POST to generate a quiz." }, 405);
  }

  const apiKey = Deno.env.get("GROQ_API_KEY");
  if (!apiKey) {
    return jsonResponse(
      { error: "Quiz generation is not configured yet. Add GROQ_API_KEY to the Supabase Edge Function secrets." },
      503,
    );
  }

  try {
    const input = await request.json();
    const courseName = typeof input.courseName === "string" ? input.courseName.trim() : "";
    const topicName = typeof input.topicName === "string" ? input.topicName.trim() : "";
    if (!courseName || courseName.length > 120 || !topicName || topicName.length > 160) {
      return jsonResponse({ error: "Provide a course (up to 120 characters) and topic (up to 160 characters)." }, 400);
    }

    const response = await fetch(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: "openai/gpt-oss-20b",
          temperature: 0.4,
          max_completion_tokens: 6000,
          response_format: { type: "json_object" },
          messages: [
            {
              role: "system",
              content: "You create accurate university-level multiple-choice practice quizzes. Return only valid JSON with this shape: {\"questions\":[{\"question\":string,\"options\":[string,string,string,string],\"correctIndex\":integer}]}. Make exactly 10 questions. Each question must have exactly four distinct options and one correct answer. correctIndex is zero-based from 0 to 3. Vary the correct answer position. Do not add explanations or extra fields.",
            },
            {
              role: "user",
              content: `Create a self-test for this course and topic.\nCourse: ${courseName}\nTopic: ${topicName}`,
            },
          ],
        }),
      },
    );

    if (!response.ok) {
      console.error("Groq quiz generation failed with status", response.status);
      if (response.status === 401 || response.status === 403) {
        return jsonResponse({
          error: "Groq denied access to the API key. Check that the key is active, then update GROQ_API_KEY in Supabase Edge Function secrets.",
        }, 502);
      }
      if (response.status === 429) {
        return jsonResponse({
          error: "The free Groq API request limit has been reached. Wait for the limit to reset, then try again.",
        }, 502);
      }
      return jsonResponse({ error: "The AI quiz service could not generate questions. Please try again." }, 502);
    }

    const result = await response.json();
    const generatedText = result.choices?.[0]?.message?.content;
    if (!generatedText) {
      return jsonResponse({ error: "The AI service returned no quiz questions. Please try again." }, 502);
    }

    const generated = JSON.parse(generatedText);
    if (!Array.isArray(generated.questions) || generated.questions.length !== 10) {
      return jsonResponse({ error: "The AI service returned an incomplete quiz. Please try again." }, 502);
    }

    const questions = generated.questions.map((item: Record<string, unknown>) => {
      if (
        typeof item.question !== "string" ||
        !item.question.trim() ||
        !Array.isArray(item.options) ||
        item.options.length !== 4 ||
        !item.options.every((option: unknown) => typeof option === "string" && option.trim()) ||
        !Number.isInteger(item.correctIndex) ||
        (item.correctIndex as number) < 0 ||
        (item.correctIndex as number) > 3
      ) {
        throw new Error("The AI service returned an invalid question.");
      }
      return {
        question: item.question.trim(),
        options: (item.options as string[]).map((option) => option.trim()),
        correctIndex: item.correctIndex,
      };
    });

    return jsonResponse({ courseName, topicName, questions });
  } catch (error) {
    console.error("Quiz generation request failed", error);
    return jsonResponse({ error: "Quiz generation failed. Check your inputs and try again." }, 500);
  }
});
