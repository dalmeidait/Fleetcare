import { PrismaClient, Perfil } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import pg from 'pg';
const bcrypt = require('bcrypt');

const { Pool } = require('pg');

const connectionString = process.env.DATABASE_URL || "postgresql://admin:adminpassword@localhost:5432/fleetcare?schema=public";
const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);

// Agora o PrismaClient recebe o adapter configurado corretamente
const prisma = new PrismaClient({ adapter });

async function main() {
  const senhaHasheada = await bcrypt.hash('admin123', 10);

  const admin = await prisma.usuario.upsert({
    where: { email: 'admin@fleetcare.com' },
    update: {
      senha: senhaHasheada
    }, 
    create: {
      nome: 'Administrador do Sistema',
      email: 'admin@fleetcare.com',
      senha: senhaHasheada,
      perfil: Perfil.ADMIN,
    },
  });

  console.log('Usuário ADMIN garantido no banco:', admin.email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });