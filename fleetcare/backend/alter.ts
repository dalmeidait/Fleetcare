import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() { console.log('Starting...'); try { await prisma.$executeRawUnsafe('ALTER TABLE "OrdemServico" ADD COLUMN "relatoMecanico" TEXT;'); console.log('Added 1'); } catch(e){} try{ await prisma.$executeRawUnsafe('ALTER TABLE "OrdemServico" ADD COLUMN "diagnostico" TEXT;'); console.log('Added 2'); } catch(e){}}
main().then(() => prisma.$disconnect());
