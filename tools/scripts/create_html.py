import json

with open(r"d:\modern\Modernstore-main\all_480_products_stock.json", "r", encoding="utf-8") as f:
    products_json = f.read()

html_content = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Modern Store - 480 Products Stock Manager</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  <!-- SheetJS for pure client-side Excel reading & writing -->
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
      max-width: 1480px;
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

    /* KPI Cards */
    .kpi-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
      min-width: 250px;
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

    /* Form Inputs inside cells */
    .input-qty {{
      width: 80px;
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

    /* Badges */
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

    .badge-outofstock {{
      background: rgba(239, 83, 80, 0.15);
      color: #E57373;
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

    /* Toast Notification */
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
          <h1>Modern Store <span>Stock Hub</span></h1>
          <p>480 Live Products Inventory & Bulk Excel Sync</p>
        </div>
      </div>
      <div class="actions-top">
        <input type="file" id="excelFileInput" accept=".xlsx, .xls, .csv" style="display:none;" onchange="handleExcelUpload(event)">
        <button class="btn btn-outline" onclick="document.getElementById('excelFileInput').click()">
          📂 Upload / Import Excel
        </button>
        <button class="btn btn-green" onclick="exportToExcel()">
          📥 Download Excel (.xlsx)
        </button>
        <button class="btn btn-gold" onclick="saveAndExportUpdated()">
          💾 Save & Download Updated Excel
        </button>
      </div>
    </header>

    <!-- KPI Grid -->
    <div class="kpi-grid">
      <div class="kpi-card">
        <span class="kpi-title">Total Registered Items</span>
        <span class="kpi-value" id="kpiTotal">480</span>
        <span class="kpi-sub">Across 8 Categories</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-title">Out of Stock</span>
        <span class="kpi-value" style="color: var(--red-alert);" id="kpiOutOfStock">0</span>
        <span class="kpi-sub">Needs Immediate Restock</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-title">Low Stock Alert (&le;10)</span>
        <span class="kpi-value" style="color: var(--orange-warn);" id="kpiLowStock">0</span>
        <span class="kpi-sub">Reorder Threshold Reached</span>
      </div>
      <div class="kpi-card">
        <span class="kpi-title">Total Units To Add</span>
        <span class="kpi-value" style="color: #4CAF50;" id="kpiToAdd">0</span>
        <span class="kpi-sub">From Input Column</span>
      </div>
    </div>

    <!-- Filters Bar -->
    <div class="filter-bar">
      <div class="search-box">
        <span class="search-icon">🔍</span>
        <input type="text" id="searchInput" placeholder="Search by Product Name, SKU, or ID..." oninput="filterTable()">
      </div>

      <select class="filter-select" id="categoryFilter" onchange="filterTable()">
        <option value="ALL">All Categories (480 Items)</option>
        <option value="Fresh Fruits">Fresh Fruits</option>
        <option value="Fresh Vegetables">Fresh Vegetables</option>
        <option value="Dairy & Breakfast">Dairy & Breakfast</option>
        <option value="Beverages & Cool Drinks">Beverages & Cool Drinks</option>
        <option value="Staples, Rice & Atta">Staples, Rice & Atta</option>
        <option value="Snacks & Instant Food">Snacks & Instant Food</option>
        <option value="Spices & Masalas">Spices & Masalas</option>
        <option value="Personal Care & Cleaning">Personal Care & Cleaning</option>
      </select>

      <select class="filter-select" id="statusFilter" onchange="filterTable()">
        <option value="ALL">All Stock Statuses</option>
        <option value="Out of Stock">Out of Stock Only</option>
        <option value="Low Stock">Low Stock Only</option>
        <option value="In Stock">In Stock Only</option>
      </select>

      <button class="btn btn-outline" style="padding: 10px 14px;" onclick="resetFilters()">Reset Filters</button>
    </div>

    <!-- Table Container -->
    <div class="table-container">
      <div class="table-responsive">
        <table>
          <thead>
            <tr>
              <th class="text-center">Sl</th>
              <th>Product Name</th>
              <th>Category</th>
              <th class="text-center">SKU</th>
              <th class="text-center">Unit</th>
              <th class="text-right">MRP (₹)</th>
              <th class="text-right">Price (₹)</th>
              <th class="text-right">Current Stock</th>
              <th class="col-add">Stock To Add (Qty)</th>
              <th class="text-right">New Total Stock</th>
              <th class="text-center">Status</th>
              <th>Product ID (DB Key)</th>
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
    // 480 Products Array
    let products = {products_json};

    function renderTable(dataToRender) {{
      const tbody = document.getElementById('productTableBody');
      tbody.innerHTML = '';

      let outOfStockCount = 0;
      let lowStockCount = 0;
      let totalUnitsToAdd = 0;

      dataToRender.forEach((item, index) => {{
        if (item.currentStock === 0) outOfStockCount++;
        else if (item.currentStock <= 10) lowStockCount++;
        totalUnitsToAdd += (Number(item.stockToAdd) || 0);

        const row = document.createElement('tr');
        
        let statusBadge = '';
        if (item.currentStock === 0) {{
          statusBadge = '<span class="badge badge-outofstock">Out of Stock</span>';
        }} else if (item.currentStock <= 10) {{
          statusBadge = '<span class="badge badge-lowstock">Low Stock</span>';
        }} else {{
          statusBadge = '<span class="badge badge-instock">In Stock</span>';
        }}

        const newTotal = (Number(item.currentStock) || 0) + (Number(item.stockToAdd) || 0);

        row.innerHTML = `
          <td class="text-center">${{item.slNo}}</td>
          <td style="font-weight: 600; color: #FFF;">${{item.name}}</td>
          <td><span style="color: var(--text-muted); font-size: 12px;">${{item.category}}</span></td>
          <td class="text-center"><span class="code-tag">${{item.sku}}</span></td>
          <td class="text-center"><span class="code-tag">${{item.unit}}</span></td>
          <td class="text-right">₹${{item.mrp}}</td>
          <td class="text-right" style="color: #81C784; font-weight: 600;">₹${{item.sp}}</td>
          <td class="text-right" style="font-weight: 700;">${{item.currentStock}}</td>
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

      // Update KPIs
      document.getElementById('kpiTotal').textContent = products.length;
      document.getElementById('kpiOutOfStock').textContent = outOfStockCount;
      document.getElementById('kpiLowStock').textContent = lowStockCount;
      document.getElementById('kpiToAdd').textContent = totalUnitsToAdd;
      document.getElementById('footerCount').textContent = `Showing ${{dataToRender.length}} of ${{products.length}} products`;
    }}

    function onQtyChange(id, value) {{
      const qty = parseInt(value, 10) || 0;
      const prod = products.find(p => p.id === id);
      if (prod) {{
        prod.stockToAdd = qty;
        const totalCell = document.getElementById(`total-${{id}}`);
        if (totalCell) {{
          totalCell.textContent = (prod.currentStock + qty);
        }}
      }}
      // Re-sum KPI to add
      let sum = products.reduce((acc, p) => acc + (Number(p.stockToAdd) || 0), 0);
      document.getElementById('kpiToAdd').textContent = sum;
    }}

    function filterTable() {{
      const query = document.getElementById('searchInput').value.trim().toLowerCase();
      const cat = document.getElementById('categoryFilter').value;
      const status = document.getElementById('statusFilter').value;

      const filtered = products.filter(item => {{
        const matchesQuery = query === '' || 
          item.name.toLowerCase().includes(query) ||
          item.sku.toLowerCase().includes(query) ||
          item.id.toLowerCase().includes(query);

        const matchesCat = cat === 'ALL' || item.category === cat;
        const matchesStatus = status === 'ALL' || item.status === status;

        return matchesQuery && matchesCat && matchesStatus;
      }});

      renderTable(filtered);
    }}

    function resetFilters() {{
      document.getElementById('searchInput').value = '';
      document.getElementById('categoryFilter').value = 'ALL';
      document.getElementById('statusFilter').value = 'ALL';
      renderTable(products);
    }}

    // Export to Excel (.xlsx) using SheetJS
    function exportToExcel() {{
      showToast('Generating Excel sheet...');
      
      const excelRows = products.map((p, idx) => ({{
        "Product ID (Do Not Change)": p.id,
        "Sl No": p.slNo,
        "Product Name": p.name,
        "Category": p.category,
        "SKU Code": p.sku,
        "Unit": p.unit,
        "MRP (Rs)": p.mrp,
        "Selling Price (Rs)": p.sp,
        "Current Stock": p.currentStock,
        "Sold Quantity": p.soldQty || 0,
        "Stock To Add (Enter Qty)": p.stockToAdd || 0,
        "Projected Total Stock": (p.currentStock + (p.stockToAdd || 0)),
        "Status": p.status,
        "Remarks": p.remarks || ""
      }}));

      const worksheet = XLSX.utils.json_to_sheet(excelRows);
      
      // Auto column widths
      worksheet['!cols'] = [
        {{ wch: 28 }}, // ID
        {{ wch: 8 }},  // Sl
        {{ wch: 36 }}, // Name
        {{ wch: 24 }}, // Category
        {{ wch: 16 }}, // SKU
        {{ wch: 10 }}, // Unit
        {{ wch: 12 }}, // MRP
        {{ wch: 16 }}, // SP
        {{ wch: 14 }}, // Current Stock
        {{ wch: 14 }}, // Sold
        {{ wch: 26 }}, // Stock to Add
        {{ wch: 22 }}, // Total
        {{ wch: 14 }}, // Status
        {{ wch: 18 }}  // Remarks
      ];

      const workbook = XLSX.utils.book_new();
      XLSX.utils.book_append_sheet(workbook, worksheet, "Stock Update Sheet");

      // Instructions Sheet
      const guideData = [
        ["MODERN STORE - 480 PRODUCTS BULK STOCK UPDATE INSTRUCTIONS"],
        [],
        ["Column Header", "Description", "Required / Action", "Example"],
        ["Product ID", "Unique database key used by backend. Do NOT alter.", "LOCKED", "67ec29000000000000000001"],
        ["Product Name", "Official registered product title.", "Read Only", "Fresh Shimla Apple"],
        ["Category", "Item category.", "Read Only", "Fresh Fruits"],
        ["Current Stock", "Live quantity currently remaining in the store.", "Read Only", "25"],
        ["Stock To Add", "ENTER THE NEW INCOMING STOCK QUANTITY HERE.", "TYPE HERE (Numbers)", "Enter 50 to add 50 units"],
        ["Projected Total", "Auto formula summing Current Stock + Stock To Add.", "Formula", "=I2+K2"]
      ];
      const guideSheet = XLSX.utils.aoa_to_sheet(guideData);
      guideSheet['!cols'] = [{{ wch: 22 }}, {{ wch: 45 }}, {{ wch: 20 }}, {{ wch: 25 }}];
      XLSX.utils.book_append_sheet(workbook, guideSheet, "Instructions & Guide");

      XLSX.writeFile(workbook, "ModernStore_All_480_Products_Stock.xlsx");
      showToast('Downloaded ModernStore_All_480_Products_Stock.xlsx!');
    }}

    function saveAndExportUpdated() {{
      exportToExcel();
      showToast('All changes saved and exported to Excel!');
    }}

    // Handle Uploading an Excel file back to web app
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
            const toAdd = row['Stock To Add (Enter Qty)'] || row['Stock To Add'] || row['stockToAdd'];
            
            if (id) {{
              const match = products.find(p => p.id === id);
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
</html>'''

with open(r"d:\modern\Modernstore-main\stock_inventory_hub.html", "w", encoding="utf-8") as f:
    f.write(html_content)

print("Generated stock_inventory_hub.html successfully!")
