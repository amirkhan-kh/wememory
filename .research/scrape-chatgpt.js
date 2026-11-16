const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const OUT = path.join(__dirname);
const URL = 'https://chatgpt.com/share/6af8a793-4920-83eb-bbad-2effa81cfadc';

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : http;
    const file = fs.createWriteStream(dest);
    mod
      .get(url, { headers: { 'User-Agent': 'Mozilla/5.0' } }, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          file.close();
          fs.unlinkSync(dest);
          return download(res.headers.location, dest).then(resolve).catch(reject);
        }
        res.pipe(file);
        file.on('finish', () => file.close(() => resolve(dest)));
      })
      .on('error', reject);
  });
}

(async () => {
  const browser = await chromium.launch({
    channel: 'chrome',
    headless: true,
  });
  const page = await browser.newPage({
    viewport: { width: 1440, height: 900 },
    userAgent:
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  });

  console.log('Opening share page...');
  await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 90000 });
  await page.waitForTimeout(5000);

  // Dismiss cookie / consent if present
  for (const sel of [
    'button:has-text("Accept")',
    'button:has-text("Agree")',
    'button:has-text("Accept all")',
    '[data-testid="cookie-banner-accept"]',
  ]) {
    const btn = page.locator(sel).first();
    if (await btn.isVisible().catch(() => false)) {
      await btn.click().catch(() => {});
    }
  }

  await page.waitForTimeout(3000);

  // Scroll to load full conversation
  for (let i = 0; i < 40; i++) {
    await page.evaluate(() => window.scrollBy(0, window.innerHeight));
    await page.waitForTimeout(400);
  }
  await page.evaluate(() => window.scrollTo(0, 0));
  await page.waitForTimeout(1000);

  await page.screenshot({
    path: path.join(OUT, 'chatgpt-share-full.png'),
    fullPage: true,
  });
  console.log('Saved full page screenshot');

  // Extract text content
  const text = await page.evaluate(() => {
    const root =
      document.querySelector('main') ||
      document.querySelector('[role="main"]') ||
      document.body;
    return root.innerText;
  });
  fs.writeFileSync(path.join(OUT, 'chatgpt-share.txt'), text, 'utf8');
  console.log('Saved text, length:', text.length);

  // Collect image URLs
  const images = await page.evaluate(() => {
    const urls = new Set();
    document.querySelectorAll('img').forEach((img) => {
      const src = img.currentSrc || img.src || img.getAttribute('src');
      if (src && src.startsWith('http') && !src.includes('avatar') && !src.includes('logo')) {
        urls.add(src);
      }
    });
    // also background images in style
    document.querySelectorAll('[style*="background"]').forEach((el) => {
      const m = (el.getAttribute('style') || '').match(/url\(["']?(https?:[^"')]+)/);
      if (m) urls.add(m[1]);
    });
    return [...urls];
  });
  fs.writeFileSync(path.join(OUT, 'image-urls.json'), JSON.stringify(images, null, 2));
  console.log('Found images:', images.length);

  const imgDir = path.join(OUT, 'ui-images');
  fs.mkdirSync(imgDir, { recursive: true });
  let i = 0;
  for (const src of images.slice(0, 30)) {
    i += 1;
    const ext = src.includes('.png') ? 'png' : src.includes('.webp') ? 'webp' : 'jpg';
    const dest = path.join(imgDir, `ui-${String(i).padStart(2, '0')}.${ext}`);
    try {
      await download(src, dest);
      console.log('Downloaded', dest);
    } catch (e) {
      console.log('Failed', src, e.message);
    }
  }

  // Also try to expand / click any “show more” buttons
  const moreButtons = page.locator('button:has-text("Show more"), button:has-text("Continue")');
  const count = await moreButtons.count();
  for (let j = 0; j < Math.min(count, 5); j++) {
    await moreButtons.nth(j).click().catch(() => {});
  }

  await page.screenshot({
    path: path.join(OUT, 'chatgpt-share-bottom.png'),
    fullPage: true,
  });

  await browser.close();
  console.log('Done');
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
