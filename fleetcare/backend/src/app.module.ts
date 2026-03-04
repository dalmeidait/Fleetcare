import { Module } from '@nestjs/common';
import { AuthModule } from './application/auth/auth.module';
import { ClientesModule } from './application/clientes/clientes.module';
import { VeiculosModule } from './application/veiculos/veiculos.module';
// Caminho correto com base na sua foto!
import { OsModule } from './application/os/os.module';
import { UsuariosModule } from './application/usuarios/usuarios.module';

@Module({
  imports: [
    AuthModule,
    ClientesModule,
    VeiculosModule,
    OsModule,
    UsuariosModule
  ],
})
export class AppModule { }