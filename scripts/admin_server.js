const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = 4000;
const BACKEND_UPLOAD_URL = 'http://200.234.34.162:4055/api/media/upload';
const BACKEND_BASE = 'http://200.234.34.162:4055/api';
const PRODUCTS_FILE = path.join(__dirname, '..', 'moder-store.products.updated.json');
const CATEGORIES_FILE = path.join(__dirname, '..', 'moder-store.categories.updated.json');

// Blacklisted watermarked domains
const BLOCKED_DOMAINS = ['alamy.com', '123rf.com', 'istockphoto.com', 'depositphotos.com', 'gettyimages.com'];

async function searchBingCleanPhotos(query) {
  try {
    const cleanQuery = `${query} isolated white background product photography -text -watermark -logo -poster`;
    const searchUrl = `https://www.bing.com/images/search?q=${encodeURIComponent(cleanQuery)}&qft=+filterui:photo-photo+filterui:aspect-square&form=IRFLTR&first=1`;
    const res = await fetch(searchUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9'
      }
    });
    const html = await res.text();
    const matches = [...html.matchAll(/&quot;murl&quot;:&quot;(https?:[^&]+)&quot;/g)];
    const urls = matches.map(m => m[1]);
    const filtered = urls.filter(u => !BLOCKED_DOMAINS.some(d => u.toLowerCase().includes(d)));
    return filtered.slice(0, 8);
  } catch (err) {
    console.error('Search error:', err);
    return [];
  }
}

async function uploadBufferToBackend(buffer, filename) {
  const form = new FormData();
  form.append('image', new Blob([buffer], { type: 'image/jpeg' }), filename);
  const uploadRes = await fetch(BACKEND_UPLOAD_URL, {
    method: 'POST',
    body: form
  });
  if (!uploadRes.ok) throw new Error('Backend upload failed: ' + uploadRes.status);
  const json = await uploadRes.json();
  return json.data?.url || json.url;
}

async function uploadUrlToBackend(imageUrl, filenameBase) {
  const imgRes = await fetch(imageUrl, {
    headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
    signal: AbortSignal.timeout(12000)
  });
  if (!imgRes.ok) throw new Error('Failed to fetch candidate image: ' + imgRes.status);
  const buffer = Buffer.from(await imgRes.arrayBuffer());
  const cleanName = filenameBase.replace(/[^a-zA-Z0-9_-]/g, '_').toLowerCase();
  return uploadBufferToBackend(buffer, `${cleanName}.jpg`);
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (e) {
        resolve(body);
      }
    });
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // API: Get all products and categories
  if (pathname === '/api/data' && req.method === 'GET') {
    const products = JSON.parse(fs.readFileSync(PRODUCTS_FILE, 'utf8'));
    const categories = JSON.parse(fs.readFileSync(CATEGORIES_FILE, 'utf8'));
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ products, categories }));
    return;
  }

  // API: Live Search Suggestions
  if (pathname === '/api/search-images' && req.method === 'GET') {
    const query = parsedUrl.query.q || '';
    if (!query) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ results: [] }));
      return;
    }
    const results = await searchBingCleanPhotos(query);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ results }));
    return;
  }

  // API: Save / Update Product Image
  if (pathname === '/api/update-product' && req.method === 'POST') {
    try {
      const data = await parseBody(req);
      const { productId, newImageUrl, base64Data, adminToken } = data;

      let finalServerUrl = newImageUrl;

      // If user uploaded a local image or selected external URL
      if (base64Data) {
        const matches = base64Data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
        const buffer = Buffer.from(matches ? matches[2] : base64Data, 'base64');
        finalServerUrl = await uploadBufferToBackend(buffer, `custom_prod_${productId}.jpg`);
      } else if (newImageUrl && !newImageUrl.includes('200.234.34.162:4055')) {
        // Download from web and re-upload to our backend
        finalServerUrl = await uploadUrlToBackend(newImageUrl, `custom_prod_${productId}`);
      }

      // Update in products JSON
      const products = JSON.parse(fs.readFileSync(PRODUCTS_FILE, 'utf8'));
      const product = products.find(p => {
        const id = p._id?.$oid || p._id;
        return id === productId;
      });

      if (!product) {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: false, message: 'Product not found' }));
        return;
      }

      product.images = [finalServerUrl];
      fs.writeFileSync(PRODUCTS_FILE, JSON.stringify(products, null, 2), 'utf8');

      // Also try updating the live server directly if admin token is provided!
      let liveServerResult = null;
      if (adminToken) {
        try {
          const catId = product.category?.$oid || product.category;
          const liveRes = await fetch(`${BACKEND_BASE}/product/update/${productId}`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${adminToken.trim()}`
            },
            body: JSON.stringify({
              name: product.name,
              subName: product.subName || '',
              basePrice: product.basePrice || 0,
              discountPercentage: product.discountPercentage || 0,
              unit: product.unit || 'Piece',
              description: product.description || '',
              categoryId: catId,
              selectableQuantities: product.selectableQuantities || [],
              images: [finalServerUrl]
            })
          });
          liveServerResult = await liveRes.json();
          console.log(`Live server update for ${product.name}:`, liveServerResult);
        } catch (e) {
          console.warn('Live server update warning:', e.message);
        }
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ 
        success: true, 
        newUrl: finalServerUrl, 
        liveServerResult,
        message: 'Product image updated successfully!' 
      }));
    } catch (err) {
      console.error('Error in /api/update-product:', err);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: err.message }));
    }
    return;
  }

  // API: Update Category Image
  if (pathname === '/api/update-category' && req.method === 'POST') {
    try {
      const data = await parseBody(req);
      const { categoryId, newImageUrl, base64Data, adminToken } = data;

      let finalServerUrl = newImageUrl;
      if (base64Data) {
        const matches = base64Data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
        const buffer = Buffer.from(matches ? matches[2] : base64Data, 'base64');
        finalServerUrl = await uploadBufferToBackend(buffer, `custom_cat_${categoryId}.jpg`);
      } else if (newImageUrl && !newImageUrl.includes('200.234.34.162:4055')) {
        finalServerUrl = await uploadUrlToBackend(newImageUrl, `custom_cat_${categoryId}`);
      }

      const categories = JSON.parse(fs.readFileSync(CATEGORIES_FILE, 'utf8'));
      const cat = categories.find(c => (c._id?.$oid || c._id) === categoryId);
      if (cat) {
        cat.image = finalServerUrl;
        fs.writeFileSync(CATEGORIES_FILE, JSON.stringify(categories, null, 2), 'utf8');
      }

      if (adminToken && cat) {
        try {
          await fetch(`${BACKEND_BASE}/category/update/${categoryId}`, {
            method: 'PUT',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${adminToken.trim()}`
            },
            body: JSON.stringify({ name: cat.name, image: finalServerUrl })
          });
        } catch (e) {
          console.warn('Category live update warning:', e.message);
        }
      }

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, newUrl: finalServerUrl }));
    } catch (err) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: false, error: err.message }));
    }
    return;
  }

  // Serve Main Frontend UI
  if (pathname === '/' || pathname === '/index.html') {
    const html = getAdminHtml();
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(html);
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

function getAdminHtml() {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Modern Store - Image Manager & Live Editor</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0b0f17; color: #f8fafc; padding-bottom: 60px; }
    
    header { background: #131b2a; border-bottom: 1px solid #1e293b; padding: 18px 24px; position: sticky; top: 0; z-index: 100; box-shadow: 0 4px 20px rgba(0,0,0,0.4); }
    .header-content { max-width: 1400px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 14px; }
    h1 { font-size: 22px; color: #22c55e; display: flex; align-items: center; gap: 8px; }
    
    .token-box { display: flex; align-items: center; gap: 8px; background: #0b0f17; padding: 6px 12px; border-radius: 8px; border: 1px solid #334155; }
    .token-box input { background: transparent; border: none; color: #38bdf8; outline: none; font-size: 13px; width: 220px; }
    .token-box button { background: #22c55e; color: #000; border: none; padding: 5px 12px; border-radius: 6px; font-weight: 600; cursor: pointer; font-size: 12px; }

    .main-container { max-width: 1400px; margin: 24px auto; padding: 0 20px; }
    
    .controls { display: flex; gap: 14px; margin-bottom: 24px; flex-wrap: wrap; align-items: center; }
    .search-input { flex: 1; min-width: 280px; padding: 12px 18px; border-radius: 10px; border: 1px solid #334155; background: #151d2a; color: #fff; font-size: 15px; outline: none; }
    .search-input:focus { border-color: #22c55e; box-shadow: 0 0 0 2px rgba(34,197,94,0.2); }
    
    .filter-pills { display: flex; gap: 8px; overflow-x: auto; padding-bottom: 6px; margin-bottom: 20px; }
    .pill { padding: 6px 14px; background: #1e293b; border-radius: 20px; font-size: 13px; cursor: pointer; white-space: nowrap; border: 1px solid #334155; transition: 0.15s; }
    .pill:hover, .pill.active { background: #22c55e; color: #000; font-weight: 600; border-color: #22c55e; }

    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(230px, 1fr)); gap: 18px; }
    .card { background: #151d2a; border-radius: 12px; overflow: hidden; border: 1px solid #233147; display: flex; flex-direction: column; transition: transform 0.15s, border-color 0.15s; position: relative; }
    .card:hover { transform: translateY(-4px); border-color: #38bdf8; box-shadow: 0 8px 24px rgba(0,0,0,0.3); }
    
    .img-box { width: 100%; height: 180px; background: #ffffff; display: flex; align-items: center; justify-content: center; padding: 12px; position: relative; }
    .img-box img { max-width: 100%; max-height: 100%; object-fit: contain; }
    
    .info { padding: 14px; flex: 1; display: flex; flex-direction: column; justify-content: space-between; }
    .title { font-weight: 600; font-size: 15px; color: #f8fafc; margin-bottom: 4px; }
    .sub { font-size: 12px; color: #94a3b8; margin-bottom: 8px; line-height: 1.3; }
    .tag { font-size: 11px; padding: 3px 8px; background: #0b1320; border-radius: 6px; color: #38bdf8; width: fit-content; margin-bottom: 12px; }
    
    .edit-btn { background: #2563eb; color: #fff; border: none; padding: 8px 12px; border-radius: 6px; font-size: 13px; font-weight: 600; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px; width: 100%; transition: 0.15s; }
    .edit-btn:hover { background: #1d4ed8; }

    /* Modal */
    .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.75); display: none; align-items: center; justify-content: center; z-index: 1000; padding: 20px; backdrop-filter: blur(4px); }
    .modal { background: #131b2a; border: 1px solid #334155; border-radius: 16px; width: 100%; max-width: 700px; max-height: 90vh; overflow-y: auto; padding: 24px; box-shadow: 0 20px 40px rgba(0,0,0,0.6); }
    .modal-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; border-bottom: 1px solid #1e293b; padding-bottom: 12px; }
    .modal-header h2 { font-size: 18px; color: #22c55e; }
    .close-btn { background: transparent; border: none; color: #94a3b8; font-size: 22px; cursor: pointer; }
    
    .tabs { display: flex; gap: 10px; margin-bottom: 18px; border-bottom: 1px solid #1e293b; padding-bottom: 10px; }
    .tab-btn { background: none; border: none; color: #94a3b8; font-size: 14px; font-weight: 600; padding: 6px 14px; cursor: pointer; border-radius: 6px; }
    .tab-btn.active { color: #22c55e; background: #1e293b; }
    
    .tab-content { display: none; }
    .tab-content.active { display: block; }
    
    .search-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-top: 14px; max-height: 280px; overflow-y: auto; padding: 4px; }
    .thumb-choice { height: 120px; background: #ffffff; border-radius: 8px; border: 2px solid transparent; cursor: pointer; display: flex; align-items: center; justify-content: center; padding: 6px; overflow: hidden; }
    .thumb-choice:hover { border-color: #38bdf8; }
    .thumb-choice.selected { border-color: #22c55e; box-shadow: 0 0 0 2px #22c55e; }
    .thumb-choice img { max-width: 100%; max-height: 100%; object-fit: contain; }

    .preview-box { display: flex; gap: 16px; align-items: center; margin-top: 20px; background: #0b0f17; padding: 14px; border-radius: 10px; border: 1px solid #1e293b; }
    .preview-img { width: 90px; height: 90px; background: #fff; border-radius: 8px; object-fit: contain; padding: 6px; }

    .save-btn { margin-top: 20px; width: 100%; background: #22c55e; color: #000; font-size: 15px; font-weight: 700; padding: 12px; border: none; border-radius: 8px; cursor: pointer; transition: 0.15s; }
    .save-btn:hover { background: #16a34a; }
    .save-btn:disabled { opacity: 0.5; cursor: not-allowed; }

    /* Toast */
    #toast { position: fixed; bottom: 24px; right: 24px; background: #22c55e; color: #000; padding: 12px 22px; border-radius: 8px; font-weight: 600; display: none; z-index: 2000; box-shadow: 0 4px 14px rgba(0,0,0,0.4); }
  </style>
</head>
<body>

  <header>
    <div class="header-content">
      <h1>⚡ Modern Store Image Studio</h1>
      <div class="token-box">
        <label style="font-size:12px; color:#94a3b8;">Admin Token:</label>
        <input type="password" id="adminTokenInput" placeholder="Paste Token for Instant App Sync">
        <button onclick="saveToken()">Save</button>
      </div>
    </div>
  </header>

  <div class="main-container">
    <div class="controls">
      <input type="text" class="search-input" id="searchBar" placeholder="🔍 Search any product by name, malayalam name, or category..." oninput="handleSearch()">
    </div>

    <div class="filter-pills" id="categoryPills">
      <div class="pill active" onclick="filterCategory('ALL')">All Products (<span id="totalCount">0</span>)</div>
    </div>

    <div class="grid" id="productGrid">
      <div style="grid-column: 1/-1; text-align: center; padding: 40px; color: #94a3b8;">Loading 480 products...</div>
    </div>
  </div>

  <!-- Edit Image Modal -->
  <div class="modal-overlay" id="editModal">
    <div class="modal">
      <div class="modal-header">
        <h2 id="modalProductName">Edit Product Image</h2>
        <button class="close-btn" onclick="closeModal()">&times;</button>
      </div>

      <div class="tabs">
        <button class="tab-btn active" onclick="switchTab('searchTab')">🔍 Auto Search (Clean HD)</button>
        <button class="tab-btn" onclick="switchTab('uploadTab')">📁 Upload from PC</button>
        <button class="tab-btn" onclick="switchTab('urlTab')">🔗 Paste Web URL</button>
      </div>

      <!-- Tab 1: Auto Search -->
      <div class="tab-content active" id="searchTab">
        <div style="display:flex; gap:10px;">
          <input type="text" id="modalSearchQuery" class="search-input" style="padding:8px 12px; font-size:14px;" placeholder="Search query...">
          <button class="edit-btn" style="width:110px;" onclick="runModalSearch()">Search</button>
        </div>
        <div class="search-grid" id="searchChoices">
          <div style="grid-column: 1/-1; color: #94a3b8; font-size: 13px; text-align: center; padding: 20px;">Click Search to view text-free studio options</div>
        </div>
      </div>

      <!-- Tab 2: Upload File -->
      <div class="tab-content" id="uploadTab">
        <input type="file" id="filePicker" accept="image/*" onchange="handleFileSelect(event)" style="margin-top:10px;">
      </div>

      <!-- Tab 3: Paste URL -->
      <div class="tab-content" id="urlTab">
        <input type="text" id="customUrlInput" class="search-input" style="padding:10px 14px; font-size:14px;" placeholder="https://example.com/image.jpg" oninput="handleUrlInput()">
      </div>

      <!-- Selected Preview -->
      <div class="preview-box">
        <img src="" id="selectedPreviewImg" class="preview-img" alt="Selected">
        <div>
          <div style="font-weight:600; font-size:14px;" id="previewStatus">No image chosen</div>
          <div style="font-size:12px; color:#94a3b8; margin-top:2px;">Clean white background, no text/watermark.</div>
        </div>
      </div>

      <button class="save-btn" id="saveBtn" onclick="submitImageChange()">🚀 Save & Sync to Server & App</button>
    </div>
  </div>

  <div id="toast">✓ Image Changed & Synced Successfully!</div>

  <script>
    let allProducts = [];
    let allCategories = [];
    let currentFiltered = [];
    let selectedCategory = 'ALL';
    let activeEditingProduct = null;
    let selectedNewImageUrl = null;
    let selectedBase64 = null;

    // Load saved token from localStorage
    const savedToken = localStorage.getItem('modern_admin_token') || '';
    if (savedToken) {
      document.getElementById('adminTokenInput').value = savedToken;
    }

    function saveToken() {
      const val = document.getElementById('adminTokenInput').value.trim();
      localStorage.setItem('modern_admin_token', val);
      showToast('Admin Token Saved in Browser!');
    }

    function showToast(msg) {
      const t = document.getElementById('toast');
      t.innerText = msg;
      t.style.display = 'block';
      setTimeout(() => { t.style.display = 'none'; }, 3000);
    }

    async function loadData() {
      try {
        const res = await fetch('/api/data');
        const data = await res.json();
        allProducts = data.products || [];
        allCategories = data.categories || [];
        document.getElementById('totalCount').innerText = allProducts.length;
        renderCategoryPills();
        renderProducts(allProducts);
      } catch (e) {
        console.error('Failed to load products:', e);
      }
    }

    function renderCategoryPills() {
      const container = document.getElementById('categoryPills');
      const catMap = {};
      allCategories.forEach(c => {
        const id = c._id?.$oid || c._id;
        catMap[id] = c.name;
      });

      const counts = {};
      allProducts.forEach(p => {
        const cid = p.category?.$oid || p.category;
        counts[cid] = (counts[cid] || 0) + 1;
      });

      allCategories.forEach(c => {
        const id = c._id?.$oid || c._id;
        const count = counts[id] || 0;
        const pill = document.createElement('div');
        pill.className = 'pill';
        pill.innerText = \`\${c.name} (\${count})\`;
        pill.onclick = () => filterCategory(id);
        container.appendChild(pill);
      });
    }

    function filterCategory(catId) {
      selectedCategory = catId;
      document.querySelectorAll('.pill').forEach(p => p.classList.remove('active'));
      event.target.classList.add('active');
      handleSearch();
    }

    function handleSearch() {
      const query = document.getElementById('searchBar').value.toLowerCase().trim();
      currentFiltered = allProducts.filter(p => {
        const cid = p.category?.$oid || p.category;
        if (selectedCategory !== 'ALL' && cid !== selectedCategory) return false;
        if (!query) return true;
        const str = \`\${p.name || ''} \${p.subName || ''}\`.toLowerCase();
        return str.includes(query);
      });
      renderProducts(currentFiltered);
    }

    function renderProducts(list) {
      const grid = document.getElementById('productGrid');
      if (list.length === 0) {
        grid.innerHTML = '<div style="grid-column: 1/-1; text-align: center; padding: 40px; color: #94a3b8;">No products found</div>';
        return;
      }

      const catMap = {};
      allCategories.forEach(c => {
        const id = c._id?.$oid || c._id;
        catMap[id] = c.name;
      });

      grid.innerHTML = list.map(p => {
        const pid = p._id?.$oid || p._id;
        const img = p.images && p.images[0] ? p.images[0] : '';
        const cid = p.category?.$oid || p.category;
        const cname = catMap[cid] || 'Grocery';
        return \`
          <div class="card" id="card-\${pid}">
            <div class="img-box">
              <img src="\${img}" id="img-\${pid}" alt="\${p.name}" loading="lazy">
            </div>
            <div class="info">
              <div>
                <div class="title">\${p.name}</div>
                <div class="sub">\${p.subName || ''}</div>
                <div class="tag">\${cname}</div>
              </div>
              <button class="edit-btn" onclick="openEditModal('\${pid}')">✏️ Change Image</button>
            </div>
          </div>
        \`;
      }).join('');
    }

    function openEditModal(productId) {
      activeEditingProduct = allProducts.find(p => (p._id?.$oid || p._id) === productId);
      if (!activeEditingProduct) return;

      selectedNewImageUrl = null;
      selectedBase64 = null;

      document.getElementById('modalProductName').innerText = \`Change Image: \${activeEditingProduct.name}\`;
      const currentImg = activeEditingProduct.images && activeEditingProduct.images[0] ? activeEditingProduct.images[0] : '';
      document.getElementById('selectedPreviewImg').src = currentImg;
      document.getElementById('previewStatus').innerText = 'Current Active Image';

      // Default search query
      const sub = (activeEditingProduct.subName || '').split(/[,/]+/)[0].trim();
      const q = sub && /^[a-zA-Z\\s]+$/.test(sub) ? sub : activeEditingProduct.name;
      document.getElementById('modalSearchQuery').value = q;

      document.getElementById('editModal').style.display = 'flex';
      runModalSearch();
    }

    function closeModal() {
      document.getElementById('editModal').style.display = 'none';
      activeEditingProduct = null;
    }

    function switchTab(tabId) {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
      event.target.classList.add('active');
      document.getElementById(tabId).classList.add('active');
    }

    async function runModalSearch() {
      const q = document.getElementById('modalSearchQuery').value.trim();
      if (!q) return;
      const choices = document.getElementById('searchChoices');
      choices.innerHTML = '<div style="grid-column: 1/-1; text-align: center; color: #38bdf8;">Finding text-free studio images...</div>';
      
      try {
        const res = await fetch(\`/api/search-images?q=\${encodeURIComponent(q)}\`);
        const data = await res.json();
        if (!data.results || data.results.length === 0) {
          choices.innerHTML = '<div style="grid-column: 1/-1; text-align: center; color: #f87171;">No clean images found. Try a different word!</div>';
          return;
        }

        choices.innerHTML = data.results.map((u, i) => \`
          <div class="thumb-choice" onclick="selectChoice('\${u}', this)">
            <img src="\${u}" alt="Option \${i+1}" loading="lazy">
          </div>
        \`).join('');
      } catch (e) {
        choices.innerHTML = '<div style="grid-column: 1/-1; text-align: center; color: #f87171;">Error searching images.</div>';
      }
    }

    function selectChoice(url, el) {
      document.querySelectorAll('.thumb-choice').forEach(t => t.classList.remove('selected'));
      el.classList.add('selected');
      selectedNewImageUrl = url;
      selectedBase64 = null;
      document.getElementById('selectedPreviewImg').src = url;
      document.getElementById('previewStatus').innerText = 'Selected New Image ✓';
    }

    function handleUrlInput() {
      const val = document.getElementById('customUrlInput').value.trim();
      if (val.startsWith('http')) {
        selectedNewImageUrl = val;
        selectedBase64 = null;
        document.getElementById('selectedPreviewImg').src = val;
        document.getElementById('previewStatus').innerText = 'Web Link Selected ✓';
      }
    }

    function handleFileSelect(e) {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = function(evt) {
        selectedBase64 = evt.target.result;
        selectedNewImageUrl = null;
        document.getElementById('selectedPreviewImg').src = selectedBase64;
        document.getElementById('previewStatus').innerText = 'Local File Selected ✓';
      };
      reader.readAsDataURL(file);
    }

    async function submitImageChange() {
      if (!activeEditingProduct) return;
      if (!selectedNewImageUrl && !selectedBase64) {
        alert('Please choose or upload a new image first!');
        return;
      }

      const saveBtn = document.getElementById('saveBtn');
      saveBtn.disabled = true;
      saveBtn.innerText = '⏳ Uploading to Server & Syncing...';

      const pid = activeEditingProduct._id?.$oid || activeEditingProduct._id;
      const token = document.getElementById('adminTokenInput').value.trim();

      try {
        const res = await fetch('/api/update-product', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            productId: pid,
            newImageUrl: selectedNewImageUrl,
            base64Data: selectedBase64,
            adminToken: token
          })
        });

        const json = await res.json();
        if (json.success) {
          activeEditingProduct.images = [json.newUrl];
          // Update live DOM card
          const imgEl = document.getElementById(\`img-\${pid}\`);
          if (imgEl) imgEl.src = json.newUrl;
          
          closeModal();
          showToast('✓ Image successfully changed and updated in server!');
        } else {
          alert('Upload failed: ' + json.error);
        }
      } catch (err) {
        alert('Error saving image: ' + err.message);
      } finally {
        saveBtn.disabled = false;
        saveBtn.innerText = '🚀 Save & Sync to Server & App';
      }
    }

    loadData();
  </script>
</body>
</html>`;
}

server.listen(PORT, '127.0.0.1', () => {
  console.log(`Modern Store Image Studio is running at: http://127.0.0.1:${PORT}`);
});
