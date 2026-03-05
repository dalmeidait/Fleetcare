import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma.service';

@Injectable()
export class ClientesService {
  constructor(private prisma: PrismaService) { }

  async create(data: any) {
    // 1. Imprime os dados exatos que o Flutter enviou
    console.log("📥 DADOS RECEBIDOS DO FLUTTER (CLIENTE):", data);

    const cpfCnpj = data.cpf || data.documento || data.cpf_cnpj;

    if (!cpfCnpj) {
      console.error("❌ Erro: O Flutter não enviou o CPF/CNPJ corretamente.");
      throw new HttpException('CPF/CNPJ obrigatório', HttpStatus.BAD_REQUEST);
    }

    const orConditions: any[] = [{ cpf_cnpj: cpfCnpj }];
    if (data.email && data.email.trim() !== '') {
      orConditions.push({ email: data.email });
    }

    // 2. Verifica se já existe no banco (e não joga Erro 500)
    const existente = await this.prisma.cliente.findFirst({ where: { OR: orConditions } });
    if (existente) {
      console.warn("⚠️ Recusado: Cliente com este CPF ou E-mail já existe no PostgreSQL.");
      throw new HttpException('Duplicidade', HttpStatus.CONFLICT);
    }

    // 3. Grava no banco de dados e captura o erro real, se houver
    try {
      const cliente = await this.prisma.cliente.create({
        data: {
          nome: data.nome,
          cpf_cnpj: cpfCnpj,
          telefone: data.telefone || null,
          email: data.email && data.email.trim() !== '' ? data.email : null,
          cep: data.cep || null,
          bairro: data.bairro || null,
          rua: data.rua || null,
          numero: data.numero || null,
          complemento: data.complemento || null,
          cidade: data.cidade || null,
          estado: data.estado || null,
        }
      });
      console.log("✅ CLIENTE GRAVADO COM SUCESSO! ID:", cliente.id);
      return this.mapToFlutter(cliente);
    } catch (error) {
      console.error("❌ ERRO GRAVE NO PRISMA AO INSERIR:", error);
      throw new HttpException('Erro interno do servidor', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  async findAll() {
    const clientes = await this.prisma.cliente.findMany();
    return clientes.map(c => this.mapToFlutter(c));
  }

  async findOne(id: string) {
    const cliente = await this.prisma.cliente.findUnique({ where: { id } });
    return cliente ? this.mapToFlutter(cliente) : null;
  }

  async update(id: string, data: any) {
    const cpfCnpj = data.cpf || data.documento || data.cpf_cnpj;
    const atualizado = await this.prisma.cliente.update({
      where: { id },
      data: {
        nome: data.nome,
        ...(cpfCnpj && { cpf_cnpj: cpfCnpj }),
        telefone: data.telefone || null,
        email: data.email && data.email.trim() !== '' ? data.email : null,
        cep: data.cep || null,
        bairro: data.bairro || null,
        rua: data.rua || null,
        numero: data.numero || null,
        complemento: data.complemento || null,
        cidade: data.cidade || null,
        estado: data.estado || null,
      }
    });
    return this.mapToFlutter(atualizado);
  }

  async remove(id: string) {
    return this.prisma.cliente.delete({ where: { id } });
  }

  private mapToFlutter(cliente: any) {
    return {
      ...cliente,
      cpf: cliente.cpf_cnpj,
      documento: cliente.cpf_cnpj,
    };
  }
}