const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const OUT = path.join(__dirname, 'ui-images');
fs.mkdirSync(OUT, { recursive: true });

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const mod = url.startsWith('https') ? https : http;
    const file = fs.createWriteStream(dest);
    const req = mod.get(
      url,
      {
        headers: {
          'User-Agent':
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          Referer: 'https://dribbble.com/',
        },
      },
      (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
          file.close();
          try {
            fs.unlinkSync(dest);
          } catch (_) {}
          return download(res.headers.location, dest).then(resolve).catch(reject);
        }
        if (res.statusCode !== 200) {
          file.close();
          try {
            fs.unlinkSync(dest);
          } catch (_) {}
          return reject(new Error(`HTTP ${res.statusCode}`));
        }
        res.pipe(file);
        file.on('finish', () => file.close(() => resolve(dest)));
      }
    );
    req.on('error', reject);
  });
}

async function capturePage(browser, url, name) {
  const page = await browser.newPage({
    viewport: { width: 1400, height: 900 },
  });
  console.log('Open', url);
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(4000);
  await page.screenshot({ path: path.join(OUT, `${name}.png`), fullPage: false });

  const imgs = await page.evaluate(() => {
    const set = new Set();
    document.querySelectorAll('img').forEach((img) => {
      const s = img.currentSrc || img.src;
      if (
        s &&
        s.startsWith('http') &&
        (s.includes('cdn') || s.includes('cloudfront') || s.includes('dribbble') || s.includes('pinimg'))
      ) {
        set.add(s.split('?')[0]);
      }
    });
    return [...set];
  });
  console.log(name, 'images', imgs.length);
  let i = 0;
  for (const src of imgs.slice(0, 8)) {
    i += 1;
    const dest = path.join(OUT, `${name}-${i}.jpg`);
    try {
      await download(src, dest);
      console.log('saved', dest);
    } catch (e) {
      console.log('fail', e.message, src.slice(0, 80));
    }
  }
  await page.close();
}

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  await capturePage(
    browser,
    'https://dribbble.com/shots/7350676-WhatsApp-Dark-Mode',
    'sarf-pearl-dark'
  );
  await capturePage(
    browser,
    'https://dribbble.com/shots/10486859-WhatsApp-Dark-Mode-iOS',
    'whatsapp-dark-ios'
  );
  await capturePage(
    browser,
    'https://www.pinterest.com/search/pins/?q=whatsapp%20redesign%20concept%20mobile%20app%20dark',
    'pinterest-redesign'
  );
  await browser.close();
  console.log('UI refs done');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
