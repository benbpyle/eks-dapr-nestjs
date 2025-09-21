import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS for cross-origin requests
  app.enableCors();

  const port = process.env.PORT || 8080;

  console.log(`🚀 Starting NestJS greeter service on port ${port}`);
  await app.listen(port);

  console.log(`✅ NestJS greeter service is running on http://localhost:${port}`);
}

bootstrap().catch((error) => {
  console.error('❌ Error starting application:', error);
  process.exit(1);
});
