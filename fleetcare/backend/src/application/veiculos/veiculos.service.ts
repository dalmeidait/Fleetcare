import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma.service';

@Injectable()
export class VeiculosService {
  constructor(private prisma: PrismaService) {}

  async create(data: any) {
    // 🕵️ O ESPIÃO: Vai nos dizer se os dados chegaram aqui ou se o Flutter travou antes
    console.log("🚗 DADOS DO VEÍCULO RECEBIDOS DO FLUTTER (CREATE):", data);

    try {
      const clienteId = data.clienteId || data.cliente_id;
      if (!clienteId) {
        throw new HttpException('ID do cliente obrigatório', HttpStatus.BAD_REQUEST);
      }

      const existente = await this.prisma.veiculo.findUnique({ where: { placa: data.placa } });
      if (existente) {
        throw new HttpException('Placa duplicada', HttpStatus.CONFLICT);
      }

      const veiculo = await this.prisma.veiculo.create({ 
        data: {
          placa: data.placa,
          marca: data.marca,
          modelo: data.modelo,
          ano: data.ano ? String(data.ano) : null, // Aceita "2010/2010" tranquilamente
          cliente_id: clienteId,
        } 
      });

      console.log("✅ VEÍCULO GRAVADO COM SUCESSO! ID:", veiculo.id);
      return this.mapToFlutter(veiculo);
    } catch (error) {
      console.error("❌ ERRO INTERNO AO CRIAR VEÍCULO:", error);
      throw new HttpException('Erro interno', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  async findAll() {
    const veiculos = await this.prisma.veiculo.findMany({ include: { cliente: true } });
    return veiculos.map(v => this.mapToFlutter(v));
  }

  async findOne(id: string) {
    const veiculo = await this.prisma.veiculo.findUnique({ where: { id }, include: { cliente: true } });
    return veiculo ? this.mapToFlutter(veiculo) : null;
  }

  async update(id: string, data: any) {
    console.log("🚗 DADOS DO VEÍCULO RECEBIDOS DO FLUTTER (UPDATE):", data);

    try {
      const clienteId = data.clienteId || data.cliente_id;
      const atualizado = await this.prisma.veiculo.update({
        where: { id },
        data: {
          placa: data.placa,
          marca: data.marca,
          modelo: data.modelo,
          ano: data.ano ? String(data.ano) : null, 
          ...(clienteId && { cliente_id: clienteId }),
        }
      });
      return this.mapToFlutter(atualizado);
    } catch (error) {
      console.error("❌ ERRO INTERNO AO ATUALIZAR VEÍCULO:", error);
      throw new HttpException('Erro interno', HttpStatus.INTERNAL_SERVER_ERROR);
    }
  }

  async remove(id: string) {
    return this.prisma.veiculo.delete({ where: { id } });
  }

  private mapToFlutter(veiculo: any) {
    return {
      ...veiculo,
      clienteId: veiculo.cliente_id,
      cliente_nome: veiculo.cliente?.nome || 'Desconhecido',
    };
  }
}