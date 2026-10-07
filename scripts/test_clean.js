async function testCleanQuery(productName) {
  const query = `${productName} isolated white background product photography -text -watermark`;
  const url = `https://www.bing.com/images/search?q=${encodeURIComponent(query)}&qft=+filterui:photo-photo+filterui:aspect-square&form=IRFLTR&first=1`;
  
  const res = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9'
    }
  });
  const html = await res.text();
  const matches = [...html.matchAll(/&quot;murl&quot;:&quot;(https?:[^&]+)&quot;/g)];
  console.log(`Query: "${query}" -> Found ${matches.length} clean photo candidates.`);
  if (matches.length > 0) {
    console.log('Top 3:');
    matches.slice(0, 3).forEach((m, i) => console.log(` [${i+1}] ${m[1]}`));
  }
}

async function run() {
  await testCleanQuery('fresh red tomato');
  await testCleanQuery('fresh potato vegetable');
  await testCleanQuery('onion vegetable');
}

run();
