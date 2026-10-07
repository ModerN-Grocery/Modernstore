import urllib.request
import json

url = 'http://200.234.34.162:4055/api/inventory/getAll'
try:
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=5) as res:
        data = json.loads(res.read().decode('utf-8'))
        items = data.get('data', [])
        print(f"Total inventory items returned from live API: {len(items)}")
        for it in items[:5]:
            p = it.get('productId', {})
            pid = p.get('_id') if isinstance(p, dict) else str(p)
            pname = p.get('name') if isinstance(p, dict) else 'N/A'
            print(f"- {pname} (ID: {pid}) | QtyInStock: {it.get('quantityInStock')}")
except Exception as e:
    print('Error:', e)
