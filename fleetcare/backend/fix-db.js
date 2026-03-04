const { Client } = require('pg');
const client = new Client({
    connectionString: 'postgresql://admin:adminpassword@localhost:5432/fleetcare?schema=public'
});

async function run() {
    await client.connect();
    console.log('Connected to DB directly.');

    try {
        await client.query('ALTER TABLE "OrdemServico" ADD COLUMN "relatoMecanico" TEXT');
        console.log('Added relatoMecanico');
    } catch (e) { console.log(e.message); }

    try {
        await client.query('ALTER TABLE "OrdemServico" ADD COLUMN "diagnostico" TEXT');
        console.log('Added diagnostico');
    } catch (e) { console.log(e.message); }

    await client.end();
    console.log('Disconnected.');
}
run();
