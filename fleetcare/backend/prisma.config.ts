import { defineConfig } from '@prisma/config';

export default defineConfig({
  datasource: {
    // Forçando a conexão direta com as credenciais do seu docker-compose
    url: 'postgresql://admin:adminpassword@localhost:5432/fleetcare?schema=public',
  },
  migrations: {
    seed: 'npx ts-node prisma/seed.ts',
  },
});