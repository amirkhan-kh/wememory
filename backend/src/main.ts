import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bodyParser: false });
  // Video/audio send-media payloads need a large body limit.
  app.use(json({ limit: '40mb' }));
  app.use(urlencoded({ extended: true, limit: '40mb' }));
  app.setGlobalPrefix('api');
  app.enableCors({ origin: true, credentials: true });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      // Evolution webhooks send arbitrary keys; forbid would break Path B.
      forbidNonWhitelisted: false,
    }),
  );
  const port = Number(process.env.PORT ?? 3000);
  // 0.0.0.0 so real phones on LAN can reach Nest (Path B / 5.4).
  await app.listen(port, '0.0.0.0');
  // eslint-disable-next-line no-console
  console.log(`WAMemory API listening on http://0.0.0.0:${port}/api`);
}

bootstrap();
