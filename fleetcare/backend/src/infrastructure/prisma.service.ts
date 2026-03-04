import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    // 1. Criamos a conexão bruta do PostgreSQL diretamente com a URL confirmada
    const pool = new Pool({
      connectionString: 'postgresql://admin:adminpassword@localhost:5432/fleetcare?schema=public',
    });

    // 2. Criamos o adaptador oficial do Prisma para o Postgres
    const adapter = new PrismaPg(pool);

    // 3. Injetamos o adaptador no Prisma (Esta é a exigência do Prisma 7!)
    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
  }
}