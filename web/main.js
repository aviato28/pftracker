// Best-effort only: shows the live release version/size next to the
// download button. If GitHub is unreachable or rate-limited, the button
// still works (it points at the stable /releases/latest/download/ URL) —
// this just fails silently, same philosophy as the app's own update check.
(async () => {
  try {
    const res = await fetch(
      "https://api.github.com/repos/aviato28/pftracker/releases/latest",
      { headers: { Accept: "application/vnd.github+json" } }
    );
    if (!res.ok) return;
    const data = await res.json();

    const apk = (data.assets || []).find((a) => a.name.endsWith(".apk"));
    if (!apk) return;

    const sizeMb = (apk.size / (1024 * 1024)).toFixed(0);
    const version = (data.tag_name || "").replace(/^v/, "").split("+")[0];

    const meta = document.getElementById("release-meta");
    meta.textContent = `v${version} · ${sizeMb} MB · Android 5.0+`;
    meta.classList.add("ready");
  } catch (_) {
    // Offline or rate-limited — the download button is static and still works.
  }
})();
