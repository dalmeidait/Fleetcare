import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { ClientesService } from './clientes.service';

@Controller('clientes')
export class ClientesController {
  constructor(private readonly clientesService: ClientesService) {}

  @Post()
  create(@Body() data: any) {
    return this.clientesService.create(data);
  }

  @Get()
  findAll() {
    return this.clientesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.clientesService.findOne(id);
  }

  @Put(':id') // <-- A MÁGICA AQUI! Usando Put para bater com o Flutter
  update(@Param('id') id: string, @Body() data: any) {
    return this.clientesService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.clientesService.remove(id);
  }
}