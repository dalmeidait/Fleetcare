import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // A SOLUÇÃO DEFINITIVA: Força todas as rotas a começarem com /api
  // Isso faz o NestJS combinar perfeitamente com o Flutter
  app.setGlobalPrefix('api');

  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  await app.listen(3001);
  // Restart triggered to refresh db connection with 127.0.0.1
}
bootstrap();