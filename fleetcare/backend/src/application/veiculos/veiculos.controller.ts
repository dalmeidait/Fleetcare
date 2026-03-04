import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { VeiculosService } from './veiculos.service';

@Controller('veiculos')
export class VeiculosController {
  constructor(private readonly veiculosService: VeiculosService) { }

  @Post()
  create(@Body() data: any) {
    return this.veiculosService.create(data);
  }

  @Get()
  findAll() {
    return this.veiculosService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.veiculosService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.veiculosService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.veiculosService.remove(id);
  }
}
