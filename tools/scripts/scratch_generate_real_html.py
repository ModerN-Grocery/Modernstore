import json

# Load unified 480 products
with open('all_480_products_stock.json', 'r', encoding='utf-8') as f:
    products = json.load(f)

# Extract unique categories
categories = sorted(list(set(p['category'] for p in products)))

# Format products for HTML
html_products = []
for p in products:
    html_products.append({
        'slNo': p['slNo'],
        'id': p['id'],
        'name': p['name'],
        'subName': p['subName'],
        'category': p['category'],
        'sku': p['sku'],
        'unit': p['unit'],
        'mrp': p['basePrice'],
        'sp': p['sellingPrice'],
        'currentStock': p['currentStock'],
        'soldQty': p['soldQuantity'],
        'stockToAdd': 0
    })

products_json_str = json.dumps(html_products, ensure_ascii=False)
categories_options_html = '<option value="ALL">All Categories (' + str(len(products)) + ' Items)</option>\n'
for cat in categories:
    count = sum(1 for p in products if p['category'] == cat)
    categories_options_html += f'        <option value="{cat}">{cat} ({count} items)</option>\n'

html_content = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Modern Store - Real 480 Products Stock Manager</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <!-- SheetJS for client-side Excel handling -->
  <script src="https://cdn.sheetjs.com/xlsx-0.20.1/package/dist/xlsx.full.min.js"></script>
  <style>
    :root {{
      --bg-dark: #0A0909;
      --card-bg: #141313;
      --card-border: #2A2825;
      --gold-primary: #F5E9B5;
      --gold-hover: #E8D896;
      --green-accent: #2E7D32;
      --green-light: #4CAF50;
      --red-alert: #EF5350;
      --orange-warn: #FFA726;
      --text-main: #FCFAF4;
      --text-muted: #9E9B91;
      --row-hover: #1E1C1A;
    }}

    * {{
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Plus Jakarta Sans', -apple-system, sans-serif;
    }}

    body {{
      background-color: var(--bg-dark);
      color: var(--text-main);
      padding: 24px;
      min-height: 100vh;
    }}

    .container {{
      max-width: 1540px;
      margin: 0 auto;
    }}

    /* Header */
    header {{
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
      margin-bottom: 24px;
      padding-bottom: 20px;
      border-bottom: 1px solid var(--card-border);
    }}

    .brand {{
      display: flex;
      align-items: center;
      gap: 14px;
    }}

    .logo-badge {{
      width: 48px;
      height: 48px;
      background: linear-gradient(135deg, #F5E9B5, #D4AF37);
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #000;
      font-size: 24px;
      font-weight: 800;
      box-shadow: 0 4px 14px rgba(245, 233, 181, 0.25);
    }}

    .brand h1 {{
      font-size: 24px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }}

    .brand h1 span {{
      color: var(--gold-primary);
    }}

    .brand p {{
      font-size: 13px;
      color: var(--text-muted);
    }}

    .actions-top {{
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }}

    .btn {{
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 11px 18px;
      border-radius: 10px;
      font-size: 13.5px;
      font-weight: 600;
      cursor: pointer;
      border: none;
      transition: all 0.2s ease;
      text-decoration: none;
    }}

    .btn-gold {{
      background: var(--gold-primary);
      color: #121008;
      box-shadow: 0 3px 10px rgba(245, 233, 181, 0.2);
    }}

    .btn-gold:hover {{
      background: var(--gold-hover);
      transform: translateY(-1px);
    }}

    .btn-green {{
      background: #1B5E20;
      color: #FFF;
      border: 1px solid #2E7D32;
    }}

    .btn-green:hover {{
      background: #2E7D32;
      transform: translateY(-1px);
    }}

    .btn-outline {{
      background: transparent;
      border: 1px solid var(--card-border);
      color: var(--text-main);
    }}

    .btn-outline:hover {{
      background: var(--card-bg);
      border-color: var(--gold-primary);
    }}

    /* Notice Banner */
    .sync-banner {{
      background: rgba(46, 125, 50, 0.12);
      border: 1px solid rgba(76, 175, 80, 0.3);
      padding: 12px 18px;
      border-radius: 12px;
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 13.5px;
      color: #A5D6A7;
    }}

    /* KPI Cards */
    .kpi-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }}

    .kpi-card {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 14px;
      padding: 16px 20px;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }}

    .kpi-title {{
      font-size: 12.5px;
      color: var(--text-muted);
      font-weight: 500;
    }}

    .kpi-value {{
      font-size: 26px;
      font-weight: 800;
    }}

    .kpi-sub {{
      font-size: 11.5px;
      color: var(--text-muted);
    }}

    /* Filters Bar */
    .filter-bar {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 14px;
      padding: 16px;
      display: flex;
      gap: 14px;
      align-items: center;
      flex-wrap: wrap;
      margin-bottom: 20px;
    }}

    .search-box {{
      flex: 1;
      min-width: 280px;
      position: relative;
    }}

    .search-box input {{
      width: 100%;
      background: #0D0C0C;
      border: 1px solid var(--card-border);
      border-radius: 10px;
      padding: 10px 14px 10px 38px;
      color: #FFF;
      font-size: 13.5px;
      outline: none;
      transition: border 0.2s;
    }}

    .search-box input:focus {{
      border-color: var(--gold-primary);
    }}

    .search-icon {{
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--text-muted);
      font-size: 15px;
    }}

    select.filter-select {{
      background: #0D0C0C;
      border: 1px solid var(--card-border);
      color: var(--text-main);
      padding: 10px 14px;
      border-radius: 10px;
      font-size: 13px;
      outline: none;
      cursor: pointer;
    }}

    select.filter-select:focus {{
      border-color: var(--gold-primary);
    }}

    /* Table Container */
    .table-container {{
      background: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      overflow: hidden;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
    }}

    .table-responsive {{
      max-height: 65vh;
      overflow-y: auto;
      overflow-x: auto;
    }}

    table {{
      width: 100%;
      border-collapse: collapse;
      text-align: left;
      font-size: 13px;
    }}

    thead {{
      background: #191817;
      position: sticky;
      top: 0;
      z-index: 10;
    }}

    th {{
      padding: 14px 14px;
      font-weight: 700;
      color: var(--gold-primary);
      border-bottom: 1px solid var(--card-border);
      white-space: nowrap;
    }}

    th.col-add {{
      background: #2E1B0E;
      color: #FFB74D;
      text-align: right;
    }}

    td {{
      padding: 12px 14px;
      border-bottom: 1px solid rgba(255,255,255,0.04);
      color: #E6E3D8;
      vertical-align: middle;
      white-space: nowrap;
    }}

    tr:hover td {{
      background-color: var(--row-hover);
    }}

    .input-qty {{
      width: 85px;
      background: #252219;
      border: 1.5px solid #FFB74D;
      border-radius: 8px;
      color: #FFD54F;
      font-weight: 700;
      padding: 6px 10px;
      font-size: 13.5px;
      text-align: right;
      outline: none;
    }}

    .input-qty:focus {{
      background: #382F1D;
      box-shadow: 0 0 8px rgba(255, 183, 77, 0.4);
    }}

    .text-center {{ text-align: center; }}
    .text-right {{ text-align: right; }}

    .badge {{
      display: inline-block;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.3px;
    }}

    .badge-instock {{
      background: rgba(76, 175, 80, 0.15);
      color: #81C784;
      border: 1px solid rgba(76, 175, 80, 0.3);
    }}

    .badge-lowstock {{
      background: rgba(255, 167, 38, 0.15);
      color: #FFB74D;
      border: 1px solid rgba(255, 167, 38, 0.3);
    }}

    .badge-nostock {{
      background: rgba(239, 83, 80, 0.15);
      color: #EF9A9A;
      border: 1px solid rgba(239, 83, 80, 0.3);
    }}

    .code-tag {{
      font-family: monospace;
      font-size: 11.5px;
      background: #1E1D1B;
      padding: 3px 6px;
      border-radius: 5px;
      color: #BDBAAE;
    }}

    .footer-bar {{
      padding: 16px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #141313;
      border-top: 1px solid var(--card-border);
      font-size: 12.5px;
      color: var(--text-muted);
    }}

    /* Toast */
    .toast {{
      position: fixed;
      bottom: 24px;
      right: 24px;
      background: #1B5E20;
      color: #FFF;
      padding: 14px 20px;
      border-radius: 10px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.6);
      font-weight: 600;
      display: none;
      align-items: center;
      gap: 10px;
      z-index: 9999;
      animation: fadeIn 0.3s;
    }}

    @keyframes fadeIn {{
      from {{ opacity: 0; transform: translateY(10px); }}
      to {{ opacity: 1; transform: translateY(0); }}
    }}
  </style>
</head>
<body>

  <div class="container">
    <!-- Header -->
    <header>
      <div class="brand">
        <div class="logo-badge">M</div>
        <div>
          <h1>Modern Store <span>Live Stock Hub</span></h1>
          <p>480 Real Database Products & Actual Inventory Sync</p>
        </div>
      </div>
      <div class="actions-top">
        <input type="file" id="excelFileInput" accept=".xlsx, .xls, .csv" style="display:none;" onchange="handleExcelUpload(event)">
        <button class="btn btn-outline" onclick="exportModelTemplate()">
          📋 Download Model Template (.xlsx)
        </button>
        <button class="btn btn-outline" onclick="document.getElementById('excelFileInput').click()">
          📂 Upload / Import Excel
        </button>
        <button class="btn btn-green" onclick="exportToExcel()">
          📥 Download All 480 Products (.xlsx)
        </button>
        <button class="btn btn-gold" onclick="saveAndExportUpdated()">
          💾 Save & Download Updated Excel
        </button>
      </div>
    </header>

    <div class="sync-banner">
      <span>🔗</span>
      <span><b>Database Synced:</b> Actual stock numbers loaded from <code>moder-store.inventories.json</code>. Unstocked products show <b>0</b>. Type new incoming quantities into <b>Stock To Add</b> and click <b>Save & Download</b>!</span>
    </div>

    <!-- KPI Grid -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <span class="kpi-title">Total Products in DB</span>
        <span class="kpi-value" id="kpiTotal">{len(products)}</span>
        <span class="kpi-sub">Across {len(categories)} Store Categories</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-title">No Stock Added Yet (=0)</span>
        <span class="kpi-value" style="color: var(--red-alert);" id="kpiNoStock">0</span>
        <span class="kpi-sub">Pending Initial Stock Entry</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-title">Active In Stock (&gt;0)</span>
        <span class="kpi-value" style="color: #81C784;" id="kpiInStock">0</span>
        <span class="kpi-sub">Already in Inventory</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-title">Total Units To Add</span>
        <span class="kpi-value" style="color: #FFB74D;" id="kpiToAdd">0</span>
        <span class="kpi-sub">From Input Column</span>
      </div>
    </div>

    <!-- Filters Bar -->
    <div class="filter-bar">
      <div class="search-box">
        <span class="search-icon">🔍</span>
        <input type="text" id="searchInput" placeholder="Search by English Name, Malayalam Name (ഉരുളക്കിഴങ്), SKU, or ID..." oninput="filterTable()">
      </div>

      <select class="filter-select" id="categoryFilter" onchange="filterTable()">
{categories_options_html}      </select>

      <select class="filter-select" id="statusFilter" onchange="filterTable()">
        <option value="ALL">All Stock Statuses</option>
        <option value="NO_STOCK">No Stock Added Yet (0 Units)</option>
        <option value="IN_STOCK">In Stock (&gt;0 Units)</option>
        <option value="HAS_ADDED">Has Stock To Add (&gt;0)</option>
      </select>
    </div>

    <!-- Table Container -->
    <div class="table-container">
      <div class="table-responsive">
        <table id="productTable">
          <thead>
            <tr>
              <th class="text-center">#</th>
              <th>Product Name</th>
              <th>Malayalam / Sub Name</th>
              <th>Category</th>
              <th class="text-center">SKU</th>
              <th class="text-center">Unit</th>
              <th class="text-right">Price (₹)</th>
              <th class="text-right">Current DB Stock</th>
              <th class="col-add">Stock To Add (Qty)</th>
              <th class="text-right">New Total Stock</th>
              <th class="text-center">Status</th>
              <th>Database Product ID</th>
            </tr>
          </thead>
          <tbody id="productTableBody">
            <!-- Populated via Javascript -->
          </tbody>
        </table>
      </div>
      <div class="footer-bar">
        <span id="footerCount">Showing 480 of 480 products</span>
        <span>Tip: Type stock quantities in the orange column and click <b>"Save & Download Updated Excel"</b></span>
      </div>
    </div>
  </div>

  <div class="toast" id="toastMessage">
    <span>✅</span>
    <span id="toastText">Action completed successfully</span>
  </div>

  <script>
    // 480 Real Products Array loaded from MongoDB Database
    let products = {products_json_str};

    function renderTable(dataToRender) {{
      const tbody = document.getElementById('productTableBody');
      tbody.innerHTML = '';

      let noStockCount = 0;
      let inStockCount = 0;
      let totalUnitsToAdd = 0;

      dataToRender.forEach((item) => {{
        if (item.currentStock === 0) {{
          noStockCount++;
        }} else {{
          inStockCount++;
        }}
        totalUnitsToAdd += (Number(item.stockToAdd) || 0);

        const row = document.createElement('tr');
        
        let statusBadge = '';
        if (item.currentStock === 0) {{
          statusBadge = '<span class="badge badge-nostock">No Stock Yet (0)</span>';
        }} else if (item.currentStock <= 5) {{
          statusBadge = '<span class="badge badge-lowstock">Low (' + item.currentStock + ')</span>';
        }} else {{
          statusBadge = '<span class="badge badge-instock">In Stock (' + item.currentStock + ')</span>';
        }}

        const newTotal = (Number(item.currentStock) || 0) + (Number(item.stockToAdd) || 0);

        row.innerHTML = `
          <td class="text-center">${{item.slNo}}</td>
          <td style="font-weight: 600; color: #FFF;">${{item.name}}</td>
          <td><span style="color: var(--text-muted); font-size: 12px;">${{item.subName || '-'}}</span></td>
          <td><span style="color: var(--text-muted); font-size: 12px;">${{item.category}}</span></td>
          <td class="text-center"><span class="code-tag">${{item.sku}}</span></td>
          <td class="text-center"><span class="code-tag">${{item.unit}}</span></td>
          <td class="text-right" style="color: #81C784; font-weight: 600;">₹${{item.sp}}</td>
          <td class="text-right" style="font-weight: 700; color: ${{item.currentStock > 0 ? '#A5D6A7' : '#EF9A9A'}};">${{item.currentStock}}</td>
          <td class="text-right" style="background: rgba(255, 183, 77, 0.04);">
            <input type="number" min="0" class="input-qty" value="${{item.stockToAdd || 0}}" 
                   oninput="onQtyChange('${{item.id}}', this.value)">
          </td>
          <td class="text-right" id="total-${{item.id}}" style="font-weight: 800; color: var(--gold-primary);">
            ${{newTotal}}
          </td>
          <td class="text-center">${{statusBadge}}</td>
          <td><span class="code-tag" style="font-size: 10px;">${{item.id}}</span></td>
        `;

        tbody.appendChild(row);
      }});

      // Update KPI
      const allNoStock = products.filter(p => p.currentStock === 0).length;
      const allInStock = products.filter(p => p.currentStock > 0).length;
      const allUnitsToAdd = products.reduce((acc, p) => acc + (Number(p.stockToAdd) || 0), 0);

      document.getElementById('kpiNoStock').textContent = allNoStock;
      document.getElementById('kpiInStock').textContent = allInStock;
      document.getElementById('kpiToAdd').textContent = allUnitsToAdd;
      document.getElementById('footerCount').textContent = `Showing ${{dataToRender.length}} of ${{products.length}} products`;
    }}

    function onQtyChange(id, value) {{
      const qty = parseInt(value, 10) || 0;
      const product = products.find(p => p.id === id);
      if (product) {{
        product.stockToAdd = qty;
        const totalCell = document.getElementById(`total-${{id}}`);
        if (totalCell) {{
          totalCell.textContent = (product.currentStock || 0) + qty;
        }}
        const allUnitsToAdd = products.reduce((acc, p) => acc + (Number(p.stockToAdd) || 0), 0);
        document.getElementById('kpiToAdd').textContent = allUnitsToAdd;
      }}
    }}

    function filterTable() {{
      const searchTerm = document.getElementById('searchInput').value.toLowerCase().trim();
      const selectedCategory = document.getElementById('categoryFilter').value;
      const selectedStatus = document.getElementById('statusFilter').value;

      const filtered = products.filter(p => {{
        const matchesSearch = !searchTerm || 
          p.name.toLowerCase().includes(searchTerm) || 
          (p.subName && p.subName.toLowerCase().includes(searchTerm)) ||
          p.sku.toLowerCase().includes(searchTerm) || 
          p.id.toLowerCase().includes(searchTerm);

        const matchesCat = selectedCategory === 'ALL' || p.category === selectedCategory;

        let matchesStatus = true;
        if (selectedStatus === 'NO_STOCK') {{
          matchesStatus = p.currentStock === 0;
        }} else if (selectedStatus === 'IN_STOCK') {{
          matchesStatus = p.currentStock > 0;
        }} else if (selectedStatus === 'HAS_ADDED') {{
          matchesStatus = (p.stockToAdd || 0) > 0;
        }}

        return matchesSearch && matchesCat && matchesStatus;
      }});

      renderTable(filtered);
    }}

    function exportToExcel() {{
      const headers = [
        "Sl No",
        "Product ID (Do Not Change)",
        "Product Name",
        "Malayalam / Sub Name",
        "SKU Code",
        "Category",
        "Unit",
        "Base Price (₹)",
        "Selling Price (₹)",
        "Current Stock in DB",
        "Sold Qty",
        "Stock To Add (Type New Qty Here)",
        "Projected Total Stock (=Current+Add)",
        "Status / Remarks"
      ];

      const sheetData = [headers];

      products.forEach((p, index) => {{
        const rowNum = index + 2;
        sheetData.push([
          p.slNo,
          p.id,
          p.name,
          p.subName || "",
          p.sku,
          p.category,
          p.unit,
          p.mrp,
          p.sp,
          p.currentStock,
          p.soldQty || 0,
          p.stockToAdd || 0,
          {{ f: `J${{rowNum}}+L${{rowNum}}` }},
          p.currentStock === 0 ? "No Stock Added Yet" : (p.currentStock <= 5 ? "Low Stock" : "In Stock")
        ]);
      }});

      const worksheet = XLSX.utils.aoa_to_sheet(sheetData);

      worksheet['!cols'] = [
        {{ wch: 8 }},   // Sl No
        {{ wch: 28 }},  // Product ID
        {{ wch: 32 }},  // Product Name
        {{ wch: 26 }},  // Sub Name
        {{ wch: 16 }},  // SKU
        {{ wch: 22 }},  // Category
        {{ wch: 12 }},  // Unit
        {{ wch: 14 }},  // Base Price
        {{ wch: 16 }},  // Selling Price
        {{ wch: 20 }},  // Current Stock in DB
        {{ wch: 14 }},  // Sold Qty
        {{ wch: 28 }},  // Stock To Add
        {{ wch: 26 }},  // Projected Total
        {{ wch: 22 }}   // Status
      ];

      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, "Stock Update Sheet");

      // Instructions Sheet
      const guideData = [
        ["MODERN STORE - REAL 480 PRODUCTS BULK STOCK UPDATE INSTRUCTIONS"],
        [],
        ["Column Header", "Description", "Required / Action", "Example"],
        ["Product ID (Do Not Change)", "Exact MongoDB ObjectID required by backend API.", "LOCKED (DO NOT EDIT)", "6992a174f62501122c4c8c0c"],
        ["Product Name", "Real registered product title from database.", "Read Only", "Urulakizhangu"],
        ["Malayalam / Sub Name", "Malayalam / Regional search name.", "Read Only", "potato, ഉരുളക്കിഴങ്"],
        ["SKU Code", "Unique Stock Keeping Unit.", "Read Only", "VEG-POT-1198"],
        ["Category", "Store Category (Vegetables, Fruits, etc.).", "Read Only", "Vegetable"],
        ["Unit", "Unit of measurement (KG, PACK, PCS, etc.).", "Read Only", "KG"],
        ["Current Stock in DB", "Real stock remaining as per moder-store.inventories.json.", "Database Value (Read Only)", "11 (or 0 if not added yet)"],
        ["Stock To Add (Type New Qty Here)", "ENTER THE NEW STOCK QUANTITY HERE!", "TYPE NUMBER HERE", "Enter 50 to add 50 units"],
        ["Projected Total Stock", "Automatic formula: =Current Stock + Stock To Add.", "Formula (=J2+L2)", "Auto-calculates"]
      ];
      const guideSheet = XLSX.utils.aoa_to_sheet(guideData);
      guideSheet['!cols'] = [{{ wch: 28 }}, {{ wch: 55 }}, {{ wch: 25 }}, {{ wch: 30 }}];
      XLSX.utils.book_append_sheet(workbook, guideSheet, "Instructions & Guide");

      XLSX.writeFile(workbook, "ModernStore_All_480_Products_Stock.xlsx");
      showToast('Downloaded ModernStore_All_480_Products_Stock.xlsx with real data!');
    }}

    function saveAndExportUpdated() {{
      exportToExcel();
      showToast('All changes saved and exported to Excel!');
    }}

    function exportModelTemplate() {{
      const templateData = [
        [
          "Sl No",
          "Product ID (Do Not Change)",
          "Product Name",
          "Malayalam / Sub Name",
          "SKU Code",
          "Category",
          "Unit",
          "Selling Price (₹)",
          "Current Stock in DB",
          "Stock To Add (Enter Qty)",
          "Projected Total Stock",
          "Supplier / Vendor Name",
          "Invoice / Batch No",
          "Notes / Remarks"
        ],
        [
          1,
          "6992a174f62501122c4c8c0c",
          "Urulakizhangu",
          "potato, ഉരുളക്കിഴങ്",
          "VEG-POT-1198",
          "Vegetable",
          "KG",
          25,
          11,
          50,
          {{ f: "I2+J2" }},
          "Metro Fresh Farms",
          "INV-2026-001",
          "Fresh morning delivery"
        ],
        [
          2,
          "6992a1aaf62501122c4c8c12",
          "Onion",
          "onion, സവാള",
          "VEG-ONI-5130",
          "Vegetable",
          "KG",
          29.7,
          1,
          100,
          {{ f: "I3+J3" }},
          "Nasik Onion Wholesale",
          "INV-2026-002",
          "Restock low stock"
        ],
        [
          3,
          "6992a1fdf62501122c4c8c18",
          "Tomato",
          "tomato, തക്കാളി",
          "VEG-TOM-7161",
          "Vegetable",
          "KG",
          30,
          0,
          40,
          {{ f: "I4+J4" }},
          "Local Farmers Market",
          "INV-2026-003",
          "Restock out of stock"
        ]
      ];

      const worksheet = XLSX.utils.aoa_to_sheet(templateData);
      worksheet['!cols'] = [
        {{ wch: 8 }}, {{ wch: 28 }}, {{ wch: 32 }}, {{ wch: 24 }}, {{ wch: 16 }},
        {{ wch: 18 }}, {{ wch: 10 }}, {{ wch: 16 }}, {{ wch: 20 }}, {{ wch: 25 }},
        {{ wch: 22 }}, {{ wch: 24 }}, {{ wch: 20 }}, {{ wch: 25 }}
      ];

      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, "Stock Bulk Update Model");
      XLSX.writeFile(workbook, "Stock_Bulk_Update_Model.xlsx");
      showToast('Downloaded Stock_Bulk_Update_Model.xlsx!');
    }}

    function handleExcelUpload(event) {{
      const file = event.target.files[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = function(e) {{
        try {{
          const data = new Uint8Array(e.target.result);
          const workbook = XLSX.read(data, {{ type: 'array' }});
          const firstSheetName = workbook.SheetNames[0];
          const worksheet = workbook.Sheets[firstSheetName];
          const importedJson = XLSX.utils.sheet_to_json(worksheet);

          let updatedCount = 0;
          importedJson.forEach(row => {{
            const id = row['Product ID (Do Not Change)'] || row['Product ID'] || row['id'];
            const toAdd = row['Stock To Add (Type New Qty Here)'] || row['Stock To Add (Enter Qty)'] || row['Stock To Add'] || row['stockToAdd'];
            
            if (id) {{
              const match = products.find(p => p.id === String(id).trim());
              if (match && toAdd !== undefined) {{
                match.stockToAdd = parseInt(toAdd, 10) || 0;
                updatedCount++;
              }}
            }}
          }});

          filterTable();
          showToast(`Successfully imported stock values for ${{updatedCount}} products!`);
        }} catch (err) {{
          alert('Error parsing Excel: ' + err.message);
        }}
      }};
      reader.readAsArrayBuffer(file);
    }}

    function showToast(msg) {{
      const toast = document.getElementById('toastMessage');
      document.getElementById('toastText').textContent = msg;
      toast.style.display = 'flex';
      setTimeout(() => {{
        toast.style.display = 'none';
      }}, 3500);
    }}

    // Initial Load
    renderTable(products);
  </script>
</body>
</html>
'''

with open('stock_inventory_hub.html', 'w', encoding='utf-8') as f:
    f.write(html_content)

print("Updated stock_inventory_hub.html successfully with REAL database products and stock!")
