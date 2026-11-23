// main.ts — DOT DASH entry for make.fun.
//
// The whole job of this program is to hand VIDEO.json to the grader:
// it copies VIDEO.json from the repository root into the output directory.
//
// It runs twice in the grader, and the second run happens with the output
// directory's files read-only. A plain copy would keep the first run's
// read-only mode on the destination and the second run would die with
// EACCES, so the destination is removed first and then written fresh.
import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const botDir = process.env.MAKEFUN_BOT_DIR ?? "/bot";
const outDir = process.env.MAKEFUN_OUTPUT_DIR ?? "/output";

const src = join(botDir, "VIDEO.json");
const dst = join(outDir, "VIDEO.json");

mkdirSync(outDir, { recursive: true });
const data = readFileSync(src);
// Validate before copying: a malformed VIDEO.json must fail here, loudly,
// instead of being handed to the grader silently.
const parsed = JSON.parse(data.toString("utf8")) as unknown;
if (typeof parsed !== "object" || parsed === null || typeof (parsed as { url?: unknown }).url !== "string") {
  throw new Error(`${src} is not a JSON object with a string "url"`);
}
if (existsSync(dst)) unlinkSync(dst);
writeFileSync(dst, data);
console.log(`copied ${src} -> ${dst} (${data.length} bytes, url=${(parsed as { url: string }).url})`);
