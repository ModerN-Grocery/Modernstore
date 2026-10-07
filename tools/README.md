# Modern Store - Developer & Admin Tools 🛠️

Welcome to the **Modern Store Tools** directory. This directory centralizes all backend synchronization scripts, inventory data files, asset generation utilities, and web inspection dashboards away from the Flutter application root to maintain a clean project structure.

---

## 📁 Directory Structure

```text
tools/
├── README.md                          # Directory guide and script documentation
├── data/                              # Database exports, JSON dumps, and Excel spreadsheets
│   ├── ModernStore_All_480_Products_Stock.xlsx # Master product & stock catalog (480 products)
│   ├── Stock_Bulk_Update_Model.xlsx   # Bulk stock upload template
│   ├── all_480_products_stock.json    # Complete JSON stock data export
│   ├── moder-store.categories.json    # Category database dump
│   ├── moder-store.categories.updated.json
│   ├── moder-store.inventories.json   # Inventory collection snapshot
│   ├── moder-store.products.json      # Product collection dump
│   └── moder-store.products.updated.json
├── scripts/                           # Python automation & maintenance scripts
│   ├── update_ios_icons.py            # Regenerates all iOS AppIcon variants from New Icon.png
│   ├── create_stock_excel.py          # Builds formatted Excel stock reports
│   ├── create_html.py                 # Generates HTML preview reports
│   ├── sync_stock_to_server.py        # Pushes local stock updates to the remote API
│   ├── scratch_generate_real_excel.py # Generates live stock Excel directly from API
│   ├── scratch_generate_real_html.py  # Builds web dashboard from live API data
│   ├── scratch_check_real_stock.py    # Queries current stock status from API
│   ├── scratch_check_cors.py          # Tests backend CORS headers
│   ├── scratch_inspect_inv.py         # Inspects inventory records and field types
│   ├── scratch_test_add_stock.py      # Tests single-item stock insertion
│   └── scratch_test_api.py            # Connectivity test for backend endpoints
└── web/                               # Local HTML dashboards & visual inspectors
    ├── preview.html                   # Visual preview of products and categories
    └── stock_inventory_hub.html       # Interactive stock monitoring & management interface
```

---

## 🚀 Key Scripts & Usage

### 1. iOS App Icon Generation (`update_ios_icons.py`)
Generates all 25 scale and device resolution icons required for Apple devices from `assets/New Icon.png`:
- Updates `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Updates `ios/Runner/Assets.xcassets/AppIcon-user.appiconset/`
- Strips alpha transparency from the 1024x1024 marketing icon for App Store compliance.

**Run Command:**
```powershell
python tools/scripts/update_ios_icons.py
```

---

### 2. Live Inventory Excel Generator (`scratch_generate_real_excel.py`)
Fetches all products and their real-time stock levels directly from the backend API (`http://200.234.34.162:4055`) and writes them into `tools/data/ModernStore_All_480_Products_Stock.xlsx`.

**Run Command:**
```powershell
python tools/scripts/scratch_generate_real_excel.py
```

---

### 3. Stock Synchronization (`sync_stock_to_server.py`)
Reads stock adjustments from local data or Excel files and syncs them to the backend inventory API using administrative endpoints.

**Run Command:**
```powershell
python tools/scripts/sync_stock_to_server.py
```

---

### 4. Live Stock Inspection Dashboard (`scratch_generate_real_html.py` & `stock_inventory_hub.html`)
Generates an interactive HTML hub (`tools/web/stock_inventory_hub.html`) with search, category filtering, stock health badges, and direct image previews for fast manual auditing.

**Run Command:**
```powershell
python tools/scripts/scratch_generate_real_html.py
# Double-click tools/web/stock_inventory_hub.html to open in your browser
```

---

## 📊 Data Directory (`tools/data/`)
- **`ModernStore_All_480_Products_Stock.xlsx`**: Master reference file containing product titles, categories, pricing, unit descriptions, and stock counts.
- **`moder-store.*.json`**: MongoDB JSON collection exports for backup, restore, or local debugging.

---

## 💡 Notes & Best Practices
1. **Virtual Environment / Dependencies**:
   The scripts primarily rely on `Pillow`, `requests`, and `openpyxl`. Install them if needed:
   ```powershell
   pip install pillow requests openpyxl
   ```
2. **Flutter Build Cleanliness**:
   All files in `tools/` are excluded from the Flutter application bundle (`pubspec.yaml`), keeping the final APK/IPA size minimal.
