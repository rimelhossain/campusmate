import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type JsonObject = Record<string, unknown>;

const json = (body: JsonObject, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });

function encodeBase64Url(value: Uint8Array | string): string {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_")
    .replace(/=+$/, "");
}

function constantTimeEqual(left: string, right: string): boolean {
  const encoder = new TextEncoder();
  const a = encoder.encode(left);
  const b = encoder.encode(right);
  let mismatch = a.length ^ b.length;
  const length = Math.max(a.length, b.length);
  for (let index = 0; index < length; index++) {
    mismatch |= (a[index] ?? 0) ^ (b[index] ?? 0);
  }
  return mismatch === 0;
}

async function getFcmAccessToken(serviceAccount: JsonObject): Promise<string> {
  const clientEmail = serviceAccount.client_email;
  const privateKeyPem = serviceAccount.private_key;
  if (typeof clientEmail !== "string" || typeof privateKeyPem !== "string") {
    throw new Error("Firebase service account is missing its signing credentials.");
  }

  const now = Math.floor(Date.now() / 1000);
  const header = encodeBase64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = encodeBase64Url(JSON.stringify({
    iss: clientEmail,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;
  const pemContents = privateKeyPem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  const keyBytes = Uint8Array.from(atob(pemContents), (character) =>
    character.charCodeAt(0)
  );
  const signingKey = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    signingKey,
    new TextEncoder().encode(unsigned),
  );
  const assertion = `${unsigned}.${encodeBase64Url(new Uint8Array(signature))}`;
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!tokenResponse.ok) {
    throw new Error("Google rejected the Firebase service account credentials.");
  }
  const tokenResult = await tokenResponse.json();
  if (typeof tokenResult.access_token !== "string") {
    throw new Error("Google did not return an FCM access token.");
  }
  return tokenResult.access_token;
}

async function supabaseRequest(
  path: string,
  serviceKey: string,
  init: RequestInit = {},
): Promise<Response> {
  const baseUrl = Deno.env.get("SUPABASE_URL");
  if (!baseUrl) throw new Error("SUPABASE_URL is not configured.");
  return await fetch(`${baseUrl}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: serviceKey,
      authorization: `Bearer ${serviceKey}`,
      "content-type": "application/json",
      ...init.headers,
    },
  });
}

async function getPushTokens(
  userId: string,
  serviceKey: string,
): Promise<Array<{ id: string; fcm_token: string }>> {
  const query = new URLSearchParams({
    select: "id,fcm_token",
    user_id: `eq.${userId}`,
    platform: "eq.android",
  });
  const response = await supabaseRequest(
    `push_devices?${query}`,
    serviceKey,
  );
  if (!response.ok) throw new Error("Could not load registered devices.");
  return await response.json();
}

async function sendPush(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>,
  serviceKey: string,
  fcmProjectId: string,
  accessToken: string,
): Promise<number> {
  const devices = await getPushTokens(userId, serviceKey);
  const results = await Promise.all(devices.map(async (device) => {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(fcmProjectId)}/messages:send`,
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${accessToken}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: device.fcm_token,
            notification: { title, body },
            data,
            android: {
              priority: "HIGH",
              notification: { channel_id: "campusmate_updates" },
            },
          },
        }),
      },
    );
    if (response.ok) return true;
    const errorBody = await response.text();
    if (errorBody.includes("UNREGISTERED")) {
      await supabaseRequest(
        `push_devices?id=eq.${encodeURIComponent(device.id)}`,
        serviceKey,
        { method: "DELETE" },
      );
    }
    return false;
  }));
  return results.filter(Boolean).length;
}

function stringifyData(data: JsonObject): Record<string, string> {
  return Object.fromEntries(
    Object.entries(data)
      .filter(([, value]) => value !== null && value !== undefined)
      .map(([key, value]) => [
        key,
        typeof value === "string" ? value : JSON.stringify(value),
      ]),
  );
}

async function handleNotificationRecord(
  record: JsonObject,
  serviceKey: string,
  fcmProjectId: string,
  accessToken: string,
): Promise<number> {
  const userId = record.user_id;
  const rawData = record.data;
  if (typeof userId !== "string" || !rawData || typeof rawData !== "object") {
    return 0;
  }
  const data = rawData as JsonObject;
  const type = data.type;
  if (type !== "tuition_reminder" && type !== "lost_found_response") return 0;

  const title = type === "lost_found_response"
    ? "Someone responded to your post in lost and found"
    : String(record.title ?? "Tuition fee reminder");
  return await sendPush(
    userId,
    title,
    String(record.body ?? ""),
    stringifyData(data),
    serviceKey,
    fcmProjectId,
    accessToken,
  );
}

async function handleChatMessage(
  record: JsonObject,
  serviceKey: string,
  fcmProjectId: string,
  accessToken: string,
): Promise<number> {
  const chatId = record.chat_id;
  const senderId = record.sender_id;
  if (
    record.message_kind === "post_preview" ||
    typeof chatId !== "string" ||
    typeof senderId !== "string"
  ) return 0;
  const chatQuery = new URLSearchParams({
    select: "id,author_id,responder_id,author_name,author_student_id,responder_name,responder_student_id,author_closed_at,responder_closed_at",
    id: `eq.${chatId}`,
    limit: "1",
  });
  const chatResponse = await supabaseRequest(
    `study_help_chats?${chatQuery}`,
    serviceKey,
  );
  if (!chatResponse.ok) throw new Error("Could not load the chat recipient.");
  const chats = await chatResponse.json();
  const chat = chats[0] as JsonObject | undefined;
  if (!chat) return 0;

  const senderIsAuthor = chat.author_id === senderId;
  const recipientClosedAt = senderIsAuthor
    ? chat.responder_closed_at
    : chat.author_closed_at;
  if (recipientClosedAt != null) return 0;
  const recipientId = senderIsAuthor ? chat.responder_id : chat.author_id;
  const senderName = senderIsAuthor
    ? chat.author_name
    : chat.responder_name;
  const senderStudentId = senderIsAuthor
    ? chat.author_student_id
    : chat.responder_student_id;
  if (typeof recipientId !== "string") return 0;

  const messageKind = record.message_kind;
  const rawBody = typeof record.body === "string"
    ? record.body
    : messageKind === "image"
    ? "Sent you an image"
    : "Sent you a message";
  const firstLine = rawBody.split(/\r?\n/, 1)[0].trim();
  const displayBody = firstLine.length > 160
    ? `${firstLine.slice(0, 157).trimEnd()}...`
    : firstLine;
  return await sendPush(
    recipientId,
    `${String(senderName ?? "A student")} (${String(senderStudentId ?? "")})`,
    displayBody,
    { type: "chat_message", chat_id: chatId },
    serviceKey,
    fcmProjectId,
    accessToken,
  );
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);

  const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  const authorization = request.headers.get("authorization") ?? "";
  if (
    webhookSecret.length < 32 ||
    !constantTimeEqual(authorization, `Bearer ${webhookSecret}`)
  ) {
    return json({ error: "Unauthorized." }, 401);
  }

  try {
    const payload = await request.json() as JsonObject;
    if (payload.type !== "INSERT" || payload.schema !== "public") {
      return json({ ignored: true });
    }
    const record = payload.record as JsonObject | undefined;
    if (!record) return json({ ignored: true });

    const table = payload.table;
    if (table === "notifications") {
      const data = record.data;
      const type = data && typeof data === "object"
        ? (data as JsonObject).type
        : null;
      if (type !== "tuition_reminder" && type !== "lost_found_response") {
        return json({ ignored: true });
      }
    } else if (table === "study_help_messages") {
      if (record.message_kind === "post_preview") return json({ ignored: true });
    } else {
      return json({ ignored: true });
    }

    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const firebaseSecret = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!serviceKey || !firebaseSecret) {
      return json({ error: "Push sender secrets are not configured." }, 503);
    }

    const serviceAccount = JSON.parse(firebaseSecret) as JsonObject;
    const projectId = serviceAccount.project_id;
    if (typeof projectId !== "string" || projectId.length === 0) {
      throw new Error("Firebase service account has no project ID.");
    }
    const accessToken = await getFcmAccessToken(serviceAccount);
    let sent = 0;
    if (table === "notifications") {
      sent = await handleNotificationRecord(
        record,
        serviceKey,
        projectId,
        accessToken,
      );
    } else if (table === "study_help_messages") {
      sent = await handleChatMessage(
        record,
        serviceKey,
        projectId,
        accessToken,
      );
    }
    return json({ sent });
  } catch (error) {
    console.error("Push notification delivery failed:", error);
    return json({ error: "Push notification delivery failed." }, 500);
  }
});
