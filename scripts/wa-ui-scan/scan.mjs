/**
 * Capture WhatsApp Web public chrome for WAMemory shell reference.
 * Does NOT log into WhatsApp — QR landing only (no session / credentials).
 *
 * Usage: node scan.mjs
 * Output: ../../.research/wa-web-scan/
 */
import { chromium } from 'playwright';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.resolve(__dirname, '../../.research/wa-web-scan');

async function main() {
  await mkdir(outDir, { recursive: true });
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    userAgent:
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  });

  await page.goto('https://web.whatsapp.com/', {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForTimeout(4000);

  const shot = path.join(outDir, 'web-whatsapp-mobile.png');
  await page.screenshot({ path: shot, fullPage: true });

  const desktop = await browser.newPage({
    viewport: { width: 1280, height: 800 },
  });
  await desktop.goto('https://web.whatsapp.com/', {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await desktop.waitForTimeout(4000);
  const deskShot = path.join(outDir, 'web-whatsapp-desktop.png');
  await desktop.screenshot({ path: deskShot, fullPage: true });

  const notes = {
    capturedAt: new Date().toISOString(),
    note:
      'Public QR landing only. Logged-in WA shell needs owner session — not automated.',
    layoutTargets: [
      'Bottom nav: Chats · Updates · Communities · Calls',
      'Chats: brand header · search · list rows · FAB',
      'Updates: My status · recent · channels',
      'Calls: favourites / call log',
      'Thread: avatar title · video · call · more · composer',
    ],
    files: [shot, deskShot],
  };
  await writeFile(
    path.join(outDir, 'notes.json'),
    JSON.stringify(notes, null, 2),
  );

  await browser.close();
  console.log(JSON.stringify(notes, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
