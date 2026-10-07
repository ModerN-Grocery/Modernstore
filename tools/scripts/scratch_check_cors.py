import urllib.request

url = 'http://200.234.34.162:4055/api/inventory/addStocks'
req = urllib.request.Request(url, method='OPTIONS')
try:
    with urllib.request.urlopen(req, timeout=5) as res:
        print('Status:', res.status)
        print('Headers:', dict(res.headers))
except urllib.error.HTTPError as e:
    print('HTTPError:', e.code)
    print('Headers:', dict(e.headers))
except Exception as e:
    print('Error:', e)
