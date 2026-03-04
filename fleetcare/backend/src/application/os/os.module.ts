import { Module } from '@nestjs/common';
import { OsService } from './os.service';
import { OsController } from './os.controller';
import { PrismaService } from '../../infrastructure/prisma.service'; // <-- Importamos o Prisma aqui

@Module({
  controllers: [OsController],
  providers: [OsService, PrismaService], // <-- Adicionamos ele aqui para o NestJS reconhecer!
})
export class OsModule {}