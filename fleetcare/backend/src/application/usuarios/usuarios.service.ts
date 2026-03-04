import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma.service';

@Injectable()
export class UsuariosService {
    constructor(private prisma: PrismaService) { }

    async create(data: any) {
        try {
            if (!data.email || data.email.trim() === '') {
                throw new HttpException('E-mail é obrigatório', HttpStatus.BAD_REQUEST);
            }
            const existente = await this.prisma.usuario.findUnique({ where: { email: data.email } });
            if (existente) {
                throw new HttpException('Email já cadastrado', HttpStatus.CONFLICT);
            }
            return await this.prisma.usuario.create({
                data: {
                    nome: data.nome,
                    email: data.email,
                    senha: data.senha || '123456',
                    perfil: data.perfil || 'ATENDENTE',
                    status: data.status || 'ATIVO',
                }
            });
        } catch (error) {
            if (error instanceof HttpException) throw error;
            throw new HttpException('Erro interno', HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    async findAll() {
        return this.prisma.usuario.findMany();
    }

    async findOne(id: string) {
        return this.prisma.usuario.findUnique({ where: { id } });
    }

    async update(id: string, data: any) {
        try {
            return await this.prisma.usuario.update({
                where: { id },
                data: {
                    nome: data.nome,
                    email: data.email,
                    senha: data.senha,
                    perfil: data.perfil,
                    status: data.status,
                }
            });
        } catch (error) {
            throw new HttpException('Erro interno', HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    async remove(id: string) {
        return this.prisma.usuario.delete({ where: { id } });
    }
}
