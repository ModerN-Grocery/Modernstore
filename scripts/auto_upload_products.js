const fs = require('fs');
const path = require('path');

const BACKEND_UPLOAD_URL = 'http://200.234.34.162:4055/api/media/upload';
const PRODUCTS_FILE = path.join(__dirname, '..', 'moder-store.products.json');
const CATEGORIES_FILE = path.join(__dirname, '..', 'moder-store.categories.json');
const CATEGORIES_UPDATED_FILE = path.join(__dirname, '..', 'moder-store.categories.updated.json');
const OUTPUT_FILE = path.join(__dirname, '..', 'moder-store.products.updated.json');
const PREVIEW_HTML_FILE = path.join(__dirname, '..', 'preview.html');

// Domains with watermarks or stock labels to strictly avoid
const BLOCKED_WATERMARK_DOMAINS = [
  'alamy.com',
  '123rf.com',
  'istockphoto.com',
  'depositphotos.com',
  'gettyimages.com',
  'dreamstime.com/comp',
  'shutterstock.com/image-vector'
];

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function getCategoryMap() {
  try {
    const catFile = fs.existsSync(CATEGORIES_UPDATED_FILE) ? CATEGORIES_UPDATED_FILE : CATEGORIES_FILE;
    const cats = JSON.parse(fs.readFileSync(catFile, 'utf8'));
    const map = {};
    for (const c of cats) {
      const id = c._id?.$oid || c._id;
      if (id) {
        map[id] = c.name;
      }
    }
    return map;
  } catch (e) {
    return {};
  }
}

function buildCleanProductQuery(product, categoryName) {
  const name = product.name || '';
  const subName = product.subName || '';
  
  const englishSubParts = subName
    .split(/[,/]+/)
    .map(s => s.trim())
    .filter(s => /^[a-zA-Z0-9\s-]+$/.test(s) && s.length > 1);

  let primarySubject = name;
  if (englishSubParts.length > 0) {
    primarySubject = `${englishSubParts[0]} ${name}`;
  }

  const cleanTokens = [...new Set(primarySubject.split(/\s+/))].filter(w => !/^[0-9]+[a-zA-Z]*$/.test(w));
  let subjectText = cleanTokens.join(' ');

  let catHint = '';
  if (categoryName && !subjectText.toLowerCase().includes(categoryName.toLowerCase())) {
    if (categoryName === 'Vegetable' || categoryName === 'Fruits') {
      catHint = `fresh ${categoryName.toLowerCase()}`;
    } else if (categoryName === 'Species') {
      catHint = 'indian spice';
    } else {
      catHint = categoryName;
    }
  }

  return `${catHint} ${subjectText} isolated white background product photography -text -watermark -logo -poster -banner`
    .replace(/\s+/g, ' ')
    .trim();
}

async function searchBingCleanPhotos(query) {
  try {
    const url = `https://www.bing.com/images/search?q=${encodeURIComponent(query)}&qft=+filterui:photo-photo+filterui:aspect-square&form=IRFLTR&first=1`;
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      }
    });
    const html = await res.text();
    const matches = [...html.matchAll(/&quot;murl&quot;:&quot;(https?:[^&]+)&quot;/g)];
    const urls = matches.map(m => m[1]);

    const cleanUrls = urls.filter(u => {
      const lower = u.toLowerCase();
      return !BLOCKED_WATERMARK_DOMAINS.some(domain => lower.includes(domain));
    });

    return cleanUrls.length > 0 ? cleanUrls : urls;
  } catch (err) {
    console.error('  [!] Search error:', err.message);
    return [];
  }
}

async function downloadAndUploadImage(imageUrl, filenameBase) {
  const imgRes = await fetch(imageUrl, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
    signal: AbortSignal.timeout(10000)
  });
  if (!imgRes.ok) throw new Error(`HTTP ${imgRes.status} downloading image`);
  const buffer = Buffer.from(await imgRes.arrayBuffer());

  const cleanName = filenameBase.replace(/[^a-zA-Z0-9_-]/g, '_').toLowerCase();
  const form = new FormData();
  form.append('image', new Blob([buffer], { type: 'image/jpeg' }), `${cleanName}.jpg`);

  const uploadRes = await fetch(BACKEND_UPLOAD_URL, {
    method: 'POST',
    body: form,
    signal: AbortSignal.timeout(15000)
  });

  if (!uploadRes.ok) throw new Error(`Upload failed with status ${uploadRes.status}`);
  const json = await uploadRes.json();
  return json.data?.url || json.url;
}

function updatePreviewHtml(products, categories) {
  const catMap = {};
  for (const c of categories) {
    const id = c._id?.$oid || c._id;
    catMap[id] = c.name;
  }

  const updatedProducts = products.filter(p => p.images && p.images[0] && p.images[0].includes('179093'));
  
  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Modern Store - Full Product & Category Catalog</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0b0f17; color: #f8fafc; padding: 24px; }
    header { margin-bottom: 24px; text-align: center; }
    h1 { font-size: 28px; color: #22c55e; margin-bottom: 6px; }
    p { color: #94a3b8; font-size: 15px; }
    .stats { display: flex; justify-content: center; gap: 16px; margin-top: 14px; flex-wrap: wrap; }
    .stat-badge { background: #1e293b; padding: 6px 16px; border-radius: 999px; font-size: 13px; font-weight: 500; border: 1px solid #334155; }
    .stat-badge b { color: #38bdf8; }
    .search-box { margin: 24px auto; max-width: 500px; }
    .search-box input { width: 100%; padding: 12px 16px; border-radius: 8px; border: 1px solid #334155; background: #1e293b; color: #fff; font-size: 15px; outline: none; }
    .search-box input:focus { border-color: #22c55e; }
    .section-title { font-size: 22px; margin: 36px 0 16px; border-bottom: 1px solid #1e293b; padding-bottom: 10px; color: #f1f5f9; display: flex; justify-content: space-between; align-items: center; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(210px, 1fr)); gap: 16px; }
    .card { background: #151d2a; border-radius: 12px; overflow: hidden; border: 1px solid #233147; display: flex; flex-direction: column; transition: transform 0.15s, border-color 0.15s; }
    .card:hover { transform: translateY(-3px); border-color: #22c55e; }
    .img-box { width: 100%; height: 170px; background: #ffffff; display: flex; align-items: center; justify-content: center; padding: 10px; }
    .img-box img { max-width: 100%; max-height: 100%; object-fit: contain; }
    .info { padding: 12px; flex: 1; display: flex; flex-direction: column; justify-content: space-between; }
    .name { font-weight: 600; font-size: 14px; color: #f8fafc; margin-bottom: 4px; line-height: 1.3; }
    .sub { font-size: 12px; color: #94a3b8; margin-bottom: 8px; }
    .tag { font-size: 11px; padding: 2px 8px; background: #0b1320; border-radius: 6px; color: #38bdf8; width: fit-content; }
    .tag-ok { color: #22c55e; font-size: 11px; font-weight: 600; margin-top: 6px; }
  </style>
</head>
<body>
  <header>
    <h1>Modern Store Catalog</h1>
    <p>Live Studio Quality Images &bull; Text-Free &bull; 100% Isolated White Background</p>
    <div class="stats">
      <div class="stat-badge">Categories: <b>${categories.length} / ${categories.length}</b></div>
      <div class="stat-badge">Updated Products: <b>${updatedProducts.length} / ${products.length}</b></div>
      <div class="stat-badge">Backend Host: <b>200.234.34.162:4055</b></div>
    </div>
  </header>

  <div class="search-box">
    <input type="text" id="searchInput" placeholder="Search by name, category, or subName..." onkeyup="filterItems()">
  </div>

  <h2 class="section-title">📂 Categories (${categories.length})</h2>
  <div class="grid" id="catGrid">
    ${categories.map(c => `
      <div class="card cat-card">
        <div class="img-box"><img src="${c.image}" alt="${c.name}" loading="lazy"></div>
        <div class="info">
          <div class="name">${c.name}</div>
          <div class="tag-ok">✓ Active</div>
        </div>
      </div>
    `).join('')}
  </div>

  <h2 class="section-title">🛍️ Products (${updatedProducts.length} uploaded so far)</h2>
  <div class="grid" id="prodGrid">
    ${products.map(p => {
      const catId = p.category?.$oid || p.category;
      const catName = catMap[catId] || 'Grocery';
      const img = p.images && p.images[0] ? p.images[0] : '';
      const isNew = img.includes('179093');
      return `
        <div class="card prod-card" data-name="${(p.name || '').toLowerCase()} ${(p.subName || '').toLowerCase()} ${catName.toLowerCase()}">
          <div class="img-box"><img src="${img}" alt="${p.name}" loading="lazy"></div>
          <div class="info">
            <div>
              <div class="name">${p.name}</div>
              <div class="sub">${p.subName || ''}</div>
              <div class="tag">${catName}</div>
            </div>
            <div class="tag-ok">${isNew ? '✓ Studio Photo' : '⏳ Pending'}</div>
          </div>
        </div>
      `;
    }).join('')}
  </div>

  <script>
    function filterItems() {
      const q = document.getElementById('searchInput').value.toLowerCase().trim();
      const cards = document.querySelectorAll('.prod-card');
      cards.forEach(card => {
        const text = card.getAttribute('data-name');
        card.style.display = (!q || text.includes(q)) ? 'flex' : 'none';
      });
    }
  </script>
</body>
</html>`;

  fs.writeFileSync(PREVIEW_HTML_FILE, html, 'utf8');
}

async function processAllProducts() {
  console.log('=== STARTING BATCH AUTO-UPLOAD FOR ALL 480 PRODUCTS ===');

  const catMap = getCategoryMap();
  const categories = fs.existsSync(CATEGORIES_UPDATED_FILE) 
    ? JSON.parse(fs.readFileSync(CATEGORIES_UPDATED_FILE, 'utf8'))
    : JSON.parse(fs.readFileSync(CATEGORIES_FILE, 'utf8'));

  let products;
  if (fs.existsSync(OUTPUT_FILE)) {
    console.log(`Resuming from existing output file: ${OUTPUT_FILE}`);
    products = JSON.parse(fs.readFileSync(OUTPUT_FILE, 'utf8'));
  } else {
    products = JSON.parse(fs.readFileSync(PRODUCTS_FILE, 'utf8'));
  }

  console.log(`Total products: ${products.length}`);
  updatePreviewHtml(products, categories);

  let updatedCount = 0;
  let skippedCount = 0;
  let failedCount = 0;

  for (let i = 0; i < products.length; i++) {
    const prod = products[i];
    const catId = prod.category?.$oid || prod.category;
    const catName = catMap[catId] || '';

    // Check if already updated with valid new upload
    const existingImg = prod.images && prod.images[0];
    if (existingImg && existingImg.includes('179093') && !existingImg.includes('test.jpg')) {
      skippedCount++;
      continue;
    }

    const query = buildCleanProductQuery(prod, catName);
    console.log(`\n[${i + 1}/${products.length}] "${prod.name}" (${catName})`);
    console.log(`  Query: ${query}`);

    const candidateUrls = await searchBingCleanPhotos(query);
    if (!candidateUrls || candidateUrls.length === 0) {
      console.log(`  [-] No search results for "${query}"`);
      failedCount++;
      continue;
    }

    let uploadedUrl = null;
    for (let r = 0; r < Math.min(candidateUrls.length, 4); r++) {
      const candidateUrl = candidateUrls[r];
      if (!candidateUrl) continue;
      try {
        console.log(`  -> Trying (${r + 1}): ${candidateUrl.slice(0, 75)}...`);
        uploadedUrl = await downloadAndUploadImage(candidateUrl, `prod_${prod.name}_${prod.sku || i}`);
        console.log(`  [SUCCESS] -> ${uploadedUrl}`);
        break;
      } catch (err) {
        console.log(`  [!] Attempt ${r + 1} failed: ${err.message}`);
      }
    }

    if (uploadedUrl) {
      prod.images = [uploadedUrl];
      updatedCount++;
    } else {
      console.log(`  [FAILED] Could not download/upload for "${prod.name}"`);
      failedCount++;
    }

    // Save progress continuously after each product
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(products, null, 2));

    // Update HTML preview every 10 products
    if ((updatedCount + skippedCount) % 10 === 0) {
      updatePreviewHtml(products, categories);
    }

    await sleep(700);
  }

  // Final preview update
  updatePreviewHtml(products, categories);

  console.log(`\n================ BATCH COMPLETE ================`);
  console.log(`Total Products: ${products.length}`);
  console.log(`Newly Updated: ${updatedCount}`);
  console.log(`Already Completed: ${skippedCount}`);
  console.log(`Failed: ${failedCount}`);
  console.log(`Saved to: ${OUTPUT_FILE}`);
  console.log(`Preview: ${PREVIEW_HTML_FILE}`);
  console.log(`================================================`);
}

processAllProducts().catch(console.error);
