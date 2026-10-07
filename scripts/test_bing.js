async function searchBingImages(query) {
  try {
    const url = `https://www.bing.com/images/search?q=${encodeURIComponent(query)}&form=HDRSC2&first=1`;
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      }
    });
    const html = await res.text();
    // Bing embeds full image URLs in m="{...&quot;murl&quot;:&quot;URL&quot;...}"
    const matches = [...html.matchAll(/&quot;murl&quot;:&quot;(https?:[^&]+)&quot;/g)];
    const urls = matches.map(m => m[1]);
    return urls;
  } catch (err) {
    console.error('Bing error:', err.message);
    return [];
  }
}

async function test() {
  const query = 'fresh red tomato isolated white background';
  console.log('Searching Bing for:', query);
  const urls = await searchBingImages(query);
  console.log(`Found ${urls.length} images!`);
  if (urls.length > 0) {
    console.log('First 3 URLs:');
    urls.slice(0, 3).forEach((u, i) => console.log(`  [${i+1}] ${u}`));
  }
}

test();
