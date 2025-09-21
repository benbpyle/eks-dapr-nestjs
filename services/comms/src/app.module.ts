import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { GreeterService } from './greeter.service';

@Module({
  imports: [],
  controllers: [AppController],
  providers: [AppService, GreeterService],
})
export class AppModule {}
