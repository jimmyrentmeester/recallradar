// B6 — Publish-stap, geabstraheerd zodat omschakelen van GitHub Pages naar bijv.
// Cloudflare R2 triviaal blijft (Fase 3 §2.1). Nu: schrijf naar OUTPUT_DIR; de
// GitHub Action deployt die map naar de gh-pages branch.

import { mkdir, writeFile, readFile } from 'node:fs/promises';
import path from 'node:path';
import { OUTPUT_DIR } from './config.js';

export async function readPublishedMeta() {
  try {
    const txt = await readFile(path.join(OUTPUT_DIR, 'meta.json'), 'utf8');
    return JSON.parse(txt);
  } catch {
    return null;
  }
}

export async function readPublishedIndex() {
  try {
    const txt = await readFile(path.join(OUTPUT_DIR, 'index.json'), 'utf8');
    return JSON.parse(txt);
  } catch {
    return null;
  }
}

export async function publish({ index, meta }) {
  await mkdir(OUTPUT_DIR, { recursive: true });
  await writeFile(path.join(OUTPUT_DIR, 'index.json'), JSON.stringify(index));
  await writeFile(path.join(OUTPUT_DIR, 'meta.json'), JSON.stringify(meta, null, 2));
  // GitHub Pages serveert dan ook .json-bestanden zonder Jekyll-verwerking.
  await writeFile(path.join(OUTPUT_DIR, '.nojekyll'), '');
  return { dir: OUTPUT_DIR, files: ['index.json', 'meta.json'] };
}
