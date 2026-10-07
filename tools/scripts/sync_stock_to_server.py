import os
import sys
import json
import time
import urllib.request
import urllib.error
import openpyxl

API_URL = "http://200.234.34.162:4055/api/inventory/addStocks"

try:
    if sys.stdout.encoding.lower() != 'utf-8':
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
except Exception:
    pass

def sync_excel_stock_to_server(excel_path="ModernStore_All_480_Products_Stock.xlsx"):
    print("=" * 65)
    print(" MODERN STORE - BULK EXCEL STOCK SYNC TOOL")
    print("=" * 65)

    if not os.path.exists(excel_path):
        print(f"❌ Error: Excel file '{excel_path}' not found!")
        print("Please place the Excel file in this folder and try again.")
        return

    print(f"📖 Reading Excel file: {excel_path} ...")
    try:
        wb = openpyxl.load_workbook(excel_path, data_only=True)
    except Exception as e:
        print(f"❌ Error loading Excel: {e}")
        return

    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    if len(rows) < 2:
        print("❌ Error: Excel sheet is empty or has no data rows.")
        return

    header = [str(cell).strip() if cell is not None else "" for cell in rows[0]]
    
    # Identify column indexes
    id_col = -1
    name_col = -1
    add_col = -1

    for idx, col in enumerate(header):
        col_lower = col.lower()
        if "product id" in col_lower:
            id_col = idx
        elif "product name" in col_lower:
            name_col = idx
        elif "stock to add" in col_lower:
            add_col = idx

    # Fallback to default indexes if header naming was changed
    if id_col == -1: id_col = 1
    if name_col == -1: name_col = 2
    if add_col == -1: add_col = 11

    items_to_sync = []
    for r_idx, row in enumerate(rows[1:], start=2):
        if len(row) <= max(id_col, add_col):
            continue
        
        pid = row[id_col]
        name = row[name_col] if name_col < len(row) else "Unknown"
        qty_to_add = row[add_col]

        if not pid:
            continue

        try:
            qty = int(float(qty_to_add)) if qty_to_add is not None else 0
        except (ValueError, TypeError):
            qty = 0

        if qty > 0:
            items_to_sync.append({
                'row': r_idx,
                'productId': str(pid).strip(),
                'name': str(name).strip(),
                'quantity': qty
            })

    if not items_to_sync:
        print("\n⚠️ No products found with 'Stock To Add' > 0.")
        print("Tip: Open the Excel, enter quantities in the 'Stock To Add' column, save, and run this again.")
        return

    print(f"\n📦 Found {len(items_to_sync)} products with new stock to add:")
    for item in items_to_sync[:10]:
        print(f"   • {item['name']:<30} -> Adding +{item['quantity']} units")
    if len(items_to_sync) > 10:
        print(f"   ... and {len(items_to_sync) - 10} more items.")

    print("\n" + "-" * 65)
    print(f"🚀 Ready to sync {len(items_to_sync)} products to server: {API_URL}")
    confirm = input("Do you want to proceed and update database now? (y/n): ").strip().lower()
    if confirm not in ['y', 'yes']:
        print("❌ Operation cancelled by user.")
        return

    print("\n⏳ Uploading stock to server database...")
    success_count = 0
    fail_count = 0

    headers = {'Content-Type': 'application/json'}

    for idx, item in enumerate(items_to_sync, start=1):
        payload = json.dumps({
            "productId": item['productId'],
            "stockQnt": item['quantity']
        }).encode('utf-8')

        req = urllib.request.Request(API_URL, data=payload, headers=headers)
        
        try:
            with urllib.request.urlopen(req, timeout=10) as res:
                if res.status in (200, 201):
                    print(f"[{idx}/{len(items_to_sync)}] ✅ {item['name']} -> Added +{item['quantity']} units")
                    success_count += 1
                else:
                    print(f"[{idx}/{len(items_to_sync)}] ⚠️ {item['name']} -> Server status: {res.status}")
                    fail_count += 1
        except urllib.error.HTTPError as e:
            err_body = e.read().decode('utf-8', errors='ignore')
            print(f"[{idx}/{len(items_to_sync)}] ❌ {item['name']} -> Error {e.code}: {err_body}")
            fail_count += 1
        except Exception as e:
            print(f"[{idx}/{len(items_to_sync)}] ❌ {item['name']} -> Connection error: {e}")
            fail_count += 1

        time.sleep(0.05) # Gentle rate-limit delay

    print("\n" + "=" * 65)
    print(f"🎉 Stock Sync Finished!")
    print(f"   • Successfully Updated : {success_count} products")
    print(f"   • Failed / Errors     : {fail_count} products")
    print("=" * 65)

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "ModernStore_All_480_Products_Stock.xlsx"
    sync_excel_stock_to_server(path)
