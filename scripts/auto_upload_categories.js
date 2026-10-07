const fs = require('fs');
const path = require('path');

const BACKEND_UPLOAD_URL = 'http://200.234.34.162:4055/api/media/upload';
const CATEGORIES_FILE = path.join(__dirname, '..', 'moder-store.categories.json');
const OUTPUT_FILE = path.join(__dirname, '..', 'moder-store.categories.updated.json');

const CATEGORY_SEARCH_QUERIES = {
  "Vegetable": "fresh vegetables assortment isolated white background",
  "Fruits": "fresh fruits assortment basket isolated white background",
  "Stationary": "school office stationary supplies isolated white background",
  "Bakery": "fresh bakery bread pastry isolated white background",
  "Cleaning Products": "cleaning supplies detergents spray bottles isolated white background",
  "Personal Care": "personal care shampoo soap toiletries isolated white background",
  "Sweets": "traditional sweet dessert isolated white background",
  "Soft Drinks": "cold soft drinks soda cans bottles isolated white background",
  "Ice Creams": "ice cream scoop cone bowl isolated white background",
  "Dairy Products": "dairy products milk cheese butter yogurt isolated white background",
  "Household Items": "household essential items grocery isolated white background",
  "Electronics": "consumer electronics accessories isolated white background",
  "Food Products": "grocery food items packaged isolated white background",
  "Baby Care Products": "baby care lotion diaper wipes isolated white background",
  "Species": "indian spices whole and powder spices isolated white background",
  "ICE CREAMS": "delicious ice cream dessert isolated white background"
};

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function searchBingImages(query) {
  try {
    const url = `https://www.bing.com/images/search?q=${encodeURIComponent(query)}&form=HDRSC2&first=1`;
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      }
    });
    const html = await res.text();
    const matches = [...html.matchAll(/&quot;murl&quot;:&quot;(https?:[^&]+)&quot;/g)];
    return matches.map(m => m[1]);
  } catch (err) {
    console.error('  [!] Bing search error:', err.message);
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

async function processCategories() {
  console.log('--- STARTING CATEGORIES IMAGE AUTO-UPLOAD (BING ENGINE) ---');
  let categories;
  if (fs.existsSync(OUTPUT_FILE)) {
    categories = JSON.parse(fs.readFileSync(OUTPUT_FILE, 'utf8'));
  } else {
    categories = JSON.parse(fs.readFileSync(CATEGORIES_FILE, 'utf8'));
  }
  console.log(`Loaded ${categories.length} categories.`);

  let updatedCount = 0;
  for (let i = 0; i < categories.length; i++) {
    const cat = categories[i];
    const catName = cat.name;

    // Check if already updated with working image
    if (cat.image && cat.image.includes('179093') && !cat.image.includes('test.jpg')) {
      console.log(`[${i + 1}/${categories.length}] [ALREADY UPDATED] "${catName}": ${cat.image}`);
      updatedCount++;
      continue;
    }

    const query = CATEGORY_SEARCH_QUERIES[catName] || `${catName} grocery isolated white background`;
    console.log(`\n[${i + 1}/${categories.length}] Processing Category: "${catName}"`);
    console.log(`  Query: ${query}`);

    const candidateUrls = await searchBingImages(query);
    if (!candidateUrls || candidateUrls.length === 0) {
      console.log('  [-] No candidate images found, skipping.');
      continue;
    }

    let uploadedUrl = null;
    for (let r = 0; r < Math.min(candidateUrls.length, 3); r++) {
      try {
        console.log(`  -> Trying image (${r + 1}): ${candidateUrls[r].slice(0, 70)}...`);
        uploadedUrl = await downloadAndUploadImage(candidateUrls[r], `cat_${catName}`);
        console.log(`  [SUCCESS] Uploaded: ${uploadedUrl}`);
        break;
      } catch (err) {
        console.log(`  [!] Attempt ${r + 1} failed: ${err.message}`);
      }
    }

    if (uploadedUrl) {
      cat.image = uploadedUrl;
      updatedCount++;
    }

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(categories, null, 2));
    await sleep(1000);
  }

  console.log(`\n=== CATEGORIES COMPLETED: ${updatedCount}/${categories.length} updated ===`);
  console.log(`Saved updated categories to: ${OUTPUT_FILE}`);
}

processCategories().catch(console.error);
