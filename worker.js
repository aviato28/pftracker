const REPO = "aviato28/pftracker";
const FALLBACK_APK = `https://github.com/${REPO}/releases/latest/download/app-arm64-v8a-release.apk`;

// GitHub's signed S3 asset URLs stay valid for roughly 30-60 minutes, so
// caching the resolved redirect for 10 minutes at Cloudflare's edge is
// safe — and it keeps us far under GitHub's 60-req/hour anonymous API
// limit no matter how much traffic /download gets, without needing a
// GitHub token as a Worker secret.
const CACHE_TTL_SECONDS = 600;

async function resolveDownload() {
  const apiRes = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
    headers: { Accept: "application/vnd.github+json", "User-Agent": "pftracker-site" },
  });
  if (!apiRes.ok) return FALLBACK_APK;

  const release = await apiRes.json();
  const asset = (release.assets || []).find((a) => a.name.endsWith(".apk"));
  if (!asset) return FALLBACK_APK;

  // Follow github.com's own redirect chain (release page -> tag's asset
  // page -> signed S3 URL) ourselves so the browser lands straight on the
  // final file. It never loads a github.com page at all, which is what
  // was showing some visitors a sign-in prompt instead of a download —
  // GitHub's web UI occasionally interstitials a stale/logged-out session
  // even for a public release asset; its API and the S3 target never do.
  let target = asset.browser_download_url;
  for (let i = 0; i < 5; i++) {
    const res = await fetch(target, { redirect: "manual" });
    const location = res.headers.get("location");
    if (res.status >= 300 && res.status < 400 && location) {
      target = location;
    } else {
      break;
    }
  }
  return target;
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (url.pathname === "/download") {
      const cache = caches.default;
      const cacheKey = new Request(url.toString(), request);

      const cacheable = request.method === "GET";
      if (cacheable) {
        const cached = await cache.match(cacheKey);
        if (cached) return cached;
      }

      let target = FALLBACK_APK;
      try {
        target = await resolveDownload();
      } catch (_) {
        // fall back to the plain GitHub URL rather than a broken page
      }

      const response = new Response(null, {
        status: 302,
        headers: {
          Location: target,
          "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`,
        },
      });
      if (cacheable) ctx.waitUntil(cache.put(cacheKey, response.clone()));
      return response;
    }

    return env.ASSETS.fetch(request);
  },
};
