import { Controller, Get, Post, Put, Delete, Body, Param, UseInterceptors, UploadedFiles, Res } from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import * as fs from 'fs';
import { Response } from 'express';
import { OsService } from './os.service';

@Controller('os') // A rota base agora é localhost:3000/os
export class OsController {
  constructor(private readonly osService: OsService) { }

  // A Rota mágica para colocar dados no banco
  @Get('popular-banco')
  popularBanco() {
    return this.osService.popularBanco();
  }

  // A Rota que o Flutter vai usar para montar os menus
  @Get('catalogo')
  getCatalogo() {
    return this.osService.getCatalogo();
  }

  @Post()
  create(@Body() data: any) {
    return this.osService.create(data);
  }

  @Get()
  findAll() {
    return this.osService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.osService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.osService.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.osService.remove(id);
  }

  // --- Rota de Upload de Anexos ---
  @Post(':id/anexos')
  @UseInterceptors(FilesInterceptor('arquivos', 10, {
    storage: diskStorage({
      destination: './uploads/os/',
      filename: (req, file, cb) => {
        const id = req.params.id; // Pegando o ID da URL para atrelar a OS ao arquivo
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = extname(file.originalname);
        // Formato: {IdOS}-{nomeOriginal}-{timestamp}.extensao
        cb(null, `${id}-${file.originalname.replace(/[^a-zA-Z0-9.-]/g, "_")}-${uniqueSuffix}${ext}`);
      }
    }),
  }))
  async uploadArquivos(@Param('id') id: string, @UploadedFiles() files: Express.Multer.File[]) {
    // Nós podemos salvar o caminho desses arquivos no banco de dados posteriormente se houver tabela para isso,
    // mas por enquanto estamos garantindo que o backend os receba e guarde fisicamente.
    const filePaths = files.map(f => f.filename);
    return { mensagem: 'Arquivos anexados com sucesso', arquivos: filePaths };
  }

  // --- Rota para listar anexos salvos ---
  @Get(':id/anexos')
  listarAnexos(@Param('id') id: string) {
    const dir = './uploads/os/';
    if (!fs.existsSync(dir)) return [];

    // Lista apenas os arquivos que pertencem à OS específica (começam com ID da OS)
    const files = fs.readdirSync(dir);
    return files.filter(f => f.startsWith(`${id}-`));
  }

  // --- Rota para baixar/ver o anexo ---
  @Get(':id/anexos/:nomeArquivo')
  baixarAnexo(@Param('nomeArquivo') nomeArquivo: string, @Res() res: Response) {
    const filePath = join(process.cwd(), 'uploads', 'os', nomeArquivo);
    if (!fs.existsSync(filePath)) {
      return res.status(404).send({ mensagem: 'Arquivo não encontrado' });
    }
    return res.sendFile(filePath);
  }
}
