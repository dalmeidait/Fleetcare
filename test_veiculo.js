const axios = require('axios');
async function run() {
  try {
    const res = await axios.post('http://localhost:3000/api/veiculos', {
      placa: 'ABC1234',
      marca: 'Toyota',
      modelo: 'Corolla',
      ano: '2020',
      clienteId: 'dummy-id' // We expect a foreign key error or 400 Bad Request
    });
    console.log(res.data);
  } catch(e) {
    console.log(e.response ? e.response.data : e.message);
  }
}
run();
