async function testUpload() {
  const imageUrl = 'https://img.freepik.com/premium-photo/red-tomato-vegetables-isolated-white-background_935074-6438.jpg?w=2000';
  console.log('Downloading from:', imageUrl);
  const imgRes = await fetch(imageUrl, {
    headers: { 'User-Agent': 'Mozilla/5.0' }
  });
  if (!imgRes.ok) throw new Error('Failed to download image: ' + imgRes.status);
  const arrayBuffer = await imgRes.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);
  console.log('Downloaded size in bytes:', buffer.length);

  const form = new FormData();
  form.append('image', new Blob([buffer], { type: 'image/jpeg' }), 'tomato.jpg');

  console.log('Uploading to backend...');
  const uploadRes = await fetch('http://200.234.34.162:4055/api/media/upload', {
    method: 'POST',
    body: form
  });

  const resJson = await uploadRes.json();
  console.log('Upload response:', JSON.stringify(resJson, null, 2));
}

testUpload().catch(console.error);
