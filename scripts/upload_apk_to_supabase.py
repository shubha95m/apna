import os
import urllib.request
import urllib.error

SUPABASE_URL = "https://jkmdshurqjjcwshnfihi.supabase.co"
ANON_KEY = "sb_publishable_YPGrNtYbfx5UER0nzeLz5g_n8plHmxe"
APK_PATH = "exports/apna-mobile.apk"

def main():
    if not os.path.exists(APK_PATH):
        print(f"Error: {APK_PATH} not found.")
        return

    file_size = os.path.getsize(APK_PATH)
    print(f"Uploading {file_size / (1024*1024):.1f} MB to Supabase releases bucket...")

    with open(APK_PATH, "rb") as f:
        data = f.read()

    url = f"{SUPABASE_URL}/storage/v1/object/releases/apna.apk"
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "apikey": ANON_KEY,
            "Authorization": f"Bearer {ANON_KEY}",
            "Content-Type": "application/vnd.android.package-archive",
            "x-upsert": "true",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            print("APK Upload Success:", resp.status)
            print(f"Download URL: {SUPABASE_URL}/storage/v1/object/public/releases/apna.apk")
    except urllib.error.HTTPError as e:
        print(f"Error uploading APK: {e.code} - {e.read().decode()}")

if __name__ == "__main__":
    main()
