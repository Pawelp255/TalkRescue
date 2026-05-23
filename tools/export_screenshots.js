#!/usr/bin/env node
/**
 * Resize iPhone screenshots to App Store Connect required dimensions.
 * Letterboxes with black padding; no overlays or text.
 */

import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..");
const RAW_DIR = path.join(REPO_ROOT, "appstore", "raw");
const EXPORT_DIR = path.join(REPO_ROOT, "appstore", "export");

/** App Store Connect iPhone screenshot sizes (portrait). */
const SIZES = [
  { width: 1290, height: 2796, label: "1290x2796" },
  { width: 1284, height: 2778, label: "1284x2778" },
  { width: 1242, height: 2688, label: "1242x2688" },
];

const IMAGE_EXTENSIONS = new Set([
  ".png",
  ".jpg",
  ".jpeg",
  ".webp",
  ".heic",
  ".heif",
]);

async function listSourceImages(dir) {
  let entries;
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch (err) {
    if (err.code === "ENOENT") {
      throw new Error(
        `Source folder missing: ${dir}\nCreate it and add screenshots, then run again.`,
      );
    }
    throw err;
  }

  return entries
    .filter((e) => e.isFile())
    .map((e) => e.name)
    .filter((name) => IMAGE_EXTENSIONS.has(path.extname(name).toLowerCase()))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
}

async function exportOne(inputPath, outputPath, width, height) {
  await sharp(inputPath)
    .rotate()
    .resize(width, height, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 1 },
      kernel: sharp.kernel.lanczos3,
    })
    .png({ compressionLevel: 9, adaptiveFiltering: true })
    .toFile(outputPath);
}

async function main() {
  const sources = await listSourceImages(RAW_DIR);
  if (sources.length === 0) {
    console.error(`No images found in ${RAW_DIR}`);
    console.error("Supported: .png .jpg .jpeg .webp .heic .heif");
    process.exit(1);
  }

  await fs.mkdir(EXPORT_DIR, { recursive: true });
  for (const { label } of SIZES) {
    await fs.mkdir(path.join(EXPORT_DIR, label), { recursive: true });
  }

  let exported = 0;
  for (const filename of sources) {
    const inputPath = path.join(RAW_DIR, filename);
    const base = path.parse(filename).name;

    for (const { width, height, label } of SIZES) {
      const outputPath = path.join(EXPORT_DIR, label, `${base}.png`);
      await exportOne(inputPath, outputPath, width, height);
      exported += 1;
      console.log(`✓ ${label}/${base}.png`);
    }
  }

  console.log(
    `\nDone: ${sources.length} source(s) → ${exported} file(s) in ${EXPORT_DIR}`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
