// record-frames.mjs — deterministic frame-perfect recording of DOT DASH.
// Usage: node record-frames.mjs <day-one|day-seven> <seconds> <outdir> [repo-root]
// Drives the game page (game/game.html?mode=<mode>&drive=1) in headless
// Chromium over CDP: for every 1/30 s it calls window.renderAt(t) in the
// page and screenshots the result. The game is a pure function of time, so
// every frame is exact — no wall-clock drift, no fast-forward.
// Requires the Chromium from the Playwright cache (~/.cache/ms-playwright).
import { spawn } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const CHROME = process.env.HOME + "/.cache/ms-playwright/chromium-1255/chrome-linux64/chrome";
const [mode, secondsArg, outDir, repoArg] = process.argv.slice(2);
const REPO = resolve(repoArg ?? new URL("..", import.meta.url).pathname);
const SECONDS = Number(secondsArg);
const FPS = 30;
mkdirSync(outDir, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function waitFor(url, tries = 60) {
  for (let i = 0; i < tries; i++) {
    try { const r = await fetch(url); if (r.ok) return await r.json(); } catch {}
    await sleep(500);
  }
  throw new Error("chrome devtools did not come up: " + url);
}

const chrome = spawn(CHROME, [
  "--headless=new", "--remote-debugging-port=9223",
  "--window-size=540,960", "--hide-scrollbars", "--no-sandbox",
  "--disable-gpu", "--mute-audio", "--force-device-scale-factor=1",
  "about:blank",
], { stdio: "ignore" });

try {
  await waitFor("http://127.0.0.1:9223/json/version");
  const targets = await waitFor("http://127.0.0.1:9223/json/list");
  const page = targets.find((t) => t.type === "page");
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });

  let id = 0;
  const pending = new Map();
  let loadFired = null;
  const loadPromise = new Promise((r) => { loadFired = r; });
  ws.onmessage = (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id && pending.has(msg.id)) { pending.get(msg.id)(msg); pending.delete(msg.id); }
    if (msg.method === "Page.loadEventFired") loadFired();
  };
  function send(method, params = {}) {
    return new Promise((resolve) => {
      const mid = ++id;
      pending.set(mid, resolve);
      ws.send(JSON.stringify({ id: mid, method, params }));
    });
  }

  await send("Page.enable");
  await send("Emulation.setDeviceMetricsOverride", {
    width: 540, height: 960, deviceScaleFactor: 1, mobile: false,
  });
  await send("Page.navigate", {
    url: "file://" + join(REPO, "game", "game.html") + "?mode=" + mode + "&drive=1",
  });
  await loadPromise;
  await sleep(400);

  const n = SECONDS * FPS;
  const t0 = Date.now();
  for (let i = 0; i < n; i++) {
    const t = i / FPS;
    const ev = await send("Runtime.evaluate", {
      expression: `window.renderAt(${t.toFixed(4)})`,
      returnByValue: true, awaitPromise: false,
    });
    if (ev.result?.exceptionDetails) {
      throw new Error("renderAt failed at t=" + t + ": " + JSON.stringify(ev.result.exceptionDetails));
    }
    const shot = await send("Page.captureScreenshot", { format: "jpeg", quality: 85 });
    writeFileSync(join(outDir, `frame-${String(i).padStart(4, "0")}.jpg`),
      Buffer.from(shot.result.data, "base64"));
  }
  const took = (Date.now() - t0) / 1000;
  console.log(`${mode}: ${n} frames in ${took.toFixed(1)}s`);
  writeFileSync(join(outDir, "manifest.json"), JSON.stringify({
    mode, seconds: SECONDS, fps: FPS, frames: n, took_s: took,
  }, null, 2));
  ws.close();
} finally {
  chrome.kill("SIGKILL");
}
console.log("done -> " + outDir);
