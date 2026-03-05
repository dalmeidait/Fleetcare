const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const clientes = await prisma.cliente.count();
    const veiculos = await prisma.veiculo.count();
    const os = await prisma.ordemServico.count();
    console.log({ clientes, veiculos, os });
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
