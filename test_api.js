const http = require('http');
console.log('Fetching...');
http.get('http://127.0.0.1:3001/api/usuarios', (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => console.log('Status:', res.statusCode, 'Response:', data.substring(0, 100)));
}).on('error', (err) => console.log('Error:', err.message));
