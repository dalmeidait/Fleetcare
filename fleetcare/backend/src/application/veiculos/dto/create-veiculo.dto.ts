import { IsString, IsNotEmpty } from 'class-validator';

export class CreateVeiculoDto {
  @IsString()
  @IsNotEmpty()
  placa: string;

  @IsString()
  @IsNotEmpty()
  marca: string;

  @IsString()
  @IsNotEmpty()
  modelo: string;

  // AQUI ESTÁ A MUDANÇA: Agora o ano é validado como String!
  @IsString()
  @IsNotEmpty()
  ano: string; 

  @IsString()
  @IsNotEmpty()
  clienteId: string;
}