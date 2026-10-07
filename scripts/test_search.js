const fs = require('fs');

async function searchImage(query) {
  try {
    const vqdRes = await fetch('https://duckduckgo.com/?q=' + encodeURIComponent(query), {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    });
    const html = await vqdRes.text();
    const match = html.match(/vqd=([0-9-]+)/) || html.match(/vqd="([0-9-]+)"/) || html.match(/vqd='([0-9-]+)'/);
    const vqd = match ? match[1] : null;
    if (!vqd) {
      console.log('No VQD found for:', query);
      return null;
    }
    const res = await fetch(`https://duckduckgo.com/i.js?l=us-en&o=json&q=${encodeURIComponent(query)}&vqd=${vqd}&f=,,,`, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://duckduckgo.com/'
      }
    });
    const data = await res.json();
    if (data.results && data.results.length > 0) {
      return data.results[0].image;
    }
    return null;
  } catch (err) {
    console.error('Search error for:', query, err.message);
    return null;
  }
}

async function run() {
  const query = 'fresh red tomato vegetable white background';
  console.log('Searching for:', query);
  const imgUrl = await searchImage(query);
  console.log('Result URL:', imgUrl);
}

run();
