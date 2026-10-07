import json

with open('moder-store.inventories.json', 'r', encoding='utf-8') as f:
    inv = json.load(f)

print('Total inventory records in JSON:', len(inv))
for i, item in enumerate(inv):
    pid = item.get('productId', {})
    pid_val = pid.get('$oid') if isinstance(pid, dict) else str(pid)
    sku = item.get('SKU', '')
    in_stock = item.get('quantityInStock', 0)
    sold = item.get('soldQuantity', 0)
    total = item.get('totalStock', 0)
    unit = item.get('unit', '')
    print(f"{i+1:2d}. ProductID: {pid_val} | SKU: {sku:<15} | Unit: {unit:<4} | InStock: {in_stock:3d} | Sold: {sold:2d} | Total: {total:3d}")
