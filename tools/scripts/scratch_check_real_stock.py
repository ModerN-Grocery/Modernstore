import json

with open('moder-store.inventories.json', 'r', encoding='utf-8') as f:
    inventories = json.load(f)

print(f"Total inventories records: {len(inventories)}")

# Map productId to inventory details
inv_by_pid = {}
for inv in inventories:
    pid = inv.get('productId')
    if isinstance(pid, dict):
        pid = pid.get('$oid')
    if pid:
        inv_by_pid[str(pid)] = {
            'sku': inv.get('SKU', ''),
            'quantityInStock': inv.get('quantityInStock', 0),
            'soldQuantity': inv.get('soldQuantity', 0),
            'totalStock': inv.get('totalStock', 0),
            'unit': inv.get('unit', '')
        }

print("\nInventory entries:")
for pid, data in inv_by_pid.items():
    print(f"Product ID: {pid} | SKU: {data['sku']:<15} | In Stock: {data['quantityInStock']} | Sold: {data['soldQuantity']} | Total: {data['totalStock']}")

# Check products file
products_file = 'moder-store.products.updated.json'
try:
    with open(products_file, 'r', encoding='utf-8') as f:
        prods = json.load(f)
    print(f"\nTotal products in {products_file}: {len(prods)}")
except Exception as e:
    print("Error loading products updated:", e)
    with open('moder-store.products.json', 'r', encoding='utf-8') as f:
        prods = json.load(f)
    print(f"\nTotal products in moder-store.products.json: {len(prods)}")

# Check matching
matches = 0
for p in prods:
    pid = p.get('_id')
    if isinstance(pid, dict):
        pid = pid.get('$oid')
    if str(pid) in inv_by_pid:
        matches += 1
        name = p.get('name') or p.get('productName') or 'Unnamed'
        inv_info = inv_by_pid[str(pid)]
        print(f"MATCH: {name} (ID: {pid}) -> Current Stock: {inv_info['quantityInStock']}, Sold: {inv_info['soldQuantity']}")

print(f"\nTotal matches with stock: {matches} out of {len(prods)} products")
print(f"Products with NO stock added yet (stock = 0): {len(prods) - matches}")
