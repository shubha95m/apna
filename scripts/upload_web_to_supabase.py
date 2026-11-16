import os
import mimetypes
import urllib.request
import urllib.error

SUPABASE_URL = "https://jkmdshurqjjcwshnfihi.supabase.co"
ANON_KEY = "sb_publishable_YPGrNtYbfx5UER0nzeLz5g_n8plHmxe"
BUCKET = "web"
DIR = "build/web-supabase"

MIME_OVERRIDES = {
    ".html": "text/html; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".mjs": "application/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".wasm": "application/wasm",
    ".png": "image/png",
    ".otf": "font/otf",
    ".ttf": "font/ttf",
    ".frag": "text/plain",
    ".bin": "application/octet-stream",
    ".map": "application/json",
    ".css": "text/css; charset=utf-8",
}

def get_mime(path):
    ext = os.path.splitext(path)[1].lower()
    if ext in MIME_OVERRIDES:
        return MIME_OVERRIDES[ext]
    mime, _ = mimetypes.guess_type(path)
    return mime or "application/octet-stream"

def upload_file(local_path, remote_path):
    content_type = get_mime(local_path)
    with open(local_path, "rb") as f:
        data = f.read()

    url = f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{remote_path}"
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "apikey": ANON_KEY,
            "Authorization": f"Bearer {ANON_KEY}",
            "Content-Type": content_type,
            "x-upsert": "true",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        print(f"Error {remote_path}: {e.code} - {e.read().decode()}")
        return e.code

def main():
    print(f"Uploading files from {DIR} to Supabase bucket '{BUCKET}'...")
    uploaded = 0
    for root, _, files in os.walk(DIR):
        for file in files:
            local_path = os.path.join(root, file)
            rel_path = os.path.relpath(local_path, DIR)
            status = upload_file(local_path, rel_path)
            if status == 200:
                uploaded += 1
                print(f"[{uploaded}] Uploaded: {rel_path}")
            else:
                print(f"FAILED: {rel_path} ({status})")

    print(f"\nCompleted! Total {uploaded} files uploaded.")
    print(f"Live Web App URL: {SUPABASE_URL}/storage/v1/object/public/{BUCKET}/index.html")

if __name__ == "__main__":
    main()
