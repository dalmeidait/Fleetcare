const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  await prisma.usuario.create({
    data: {
      email: 'admin@fleetcare.com',
      nome: 'Dan',
      senha: '$2b$10$aN5T/JzjH3un51EXqyflle2wX/jJF957Ig6X3i.MZeTZw.lnyAZiO',
      perfil: 'ADMIN'
    }
  });
  console.log('✅ USUARIO CRIADO COM SUCESSO! PODE LOGAR!');
}

main().catch(console.error).finally(() => prisma.$disconnect());