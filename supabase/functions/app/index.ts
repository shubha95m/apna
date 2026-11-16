import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const STORAGE_BASE = "https://jkmdshurqjjcwshnfihi.supabase.co/storage/v1/object/public/web";

const MIME_TYPES: Record<string, string> = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".mjs": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".wasm": "application/wasm",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".ttf": "font/ttf",
  ".otf": "font/otf",
  ".bin": "application/octet-stream",
  ".frag": "text/plain",
};

Deno.serve(async (req: Request) => {
  const url = new URL(req.url);
  let path = url.pathname
    .replace(/^\/functions\/v1\/app\/?/, "")
    .replace(/^\/app\/?/, "");

  if (!path || path === "/" || (!path.includes(".") && !path.startsWith("assets/"))) {
    path = "index.html";
  }

  const storageUrl = `${STORAGE_BASE}/${path}`;
  const response = await fetch(storageUrl);

  if (!response.ok) {
    if (!path.includes(".")) {
      // SPA route fallback (e.g. /login, /tasks, /documents)
      const indexResp = await fetch(`${STORAGE_BASE}/index.html`);
      let html = await indexResp.text();
      html = html.replace(/<base href="[^"]*">/, '<base href="/functions/v1/app/">');
      return new Response(html, {
        status: 200,
        headers: {
          "content-type": "text/html; charset=utf-8",
          "access-control-allow-origin": "*",
          "cache-control": "no-cache",
        },
      });
    }
    return new Response(`Not Found: ${path}`, { status: 404 });
  }

  if (path === "index.html" || path.endsWith("/index.html")) {
    let html = await response.text();
    html = html.replace(/<base href="[^"]*">/, '<base href="/functions/v1/app/">');
    return new Response(html, {
      status: 200,
      headers: {
        "content-type": "text/html; charset=utf-8",
        "access-control-allow-origin": "*",
        "cache-control": "no-cache",
      },
    });
  }

  const dotIdx = path.lastIndexOf(".");
  const ext = dotIdx !== -1 ? path.substring(dotIdx).toLowerCase() : "";
  const contentType = MIME_TYPES[ext] || response.headers.get("content-type") || "application/octet-stream";

  const headers = new Headers();
  headers.set("content-type", contentType);
  headers.set("access-control-allow-origin", "*");
  headers.set("cache-control", "public, max-age=31536000, immutable");

  return new Response(response.body, {
    status: response.status,
    headers,
  });
});
