import urllib.request
import json

url = 'http://200.234.34.162:4055/api/inventory/addStocks'
# Send as number
payload = json.dumps({"productId": "6992a174f62501122c4c8c0c", "stockQnt": 1}).encode('utf-8')
headers = {'Content-Type': 'application/json'}

try:
    req = urllib.request.Request(url, data=payload, headers=headers)
    with urllib.request.urlopen(req, timeout=5) as res:
        print('Status:', res.status)
        print('Body:', res.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print('HTTPError:', e.code, e.read().decode('utf-8'))
except Exception as e:
    print('Error:', e)
