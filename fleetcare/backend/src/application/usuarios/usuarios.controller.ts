import { Controller, Get, Post, Put, Delete, Body, Param } from '@nestjs/common';
import { UsuariosService } from './usuarios.service';

@Controller('usuarios')
export class UsuariosController {
    constructor(private readonly usuariosService: UsuariosService) { }

    @Post()
    create(@Body() data: any) {
        return this.usuariosService.create(data);
    }

    @Get()
    findAll() {
        return this.usuariosService.findAll();
    }

    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.usuariosService.findOne(id);
    }

    @Put(':id')
    update(@Param('id') id: string, @Body() data: any) {
        return this.usuariosService.update(id, data);
    }

    @Delete(':id')
    remove(@Param('id') id: string) {
        return this.usuariosService.remove(id);
    }
}
