import { Controller, Get, Post, Body } from '@nestjs/common';
import { AppService } from './app.service';

interface GreetRequest {
  name: string;
}

interface HealthResponse {
  status: string;
  service: string;
  version: string;
}

interface GreetResponse {
  message: string;
  service?: string;
  timestamp?: string;
}

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('health')
  getHealth(): HealthResponse {
    return this.appService.getHealth();
  }

  @Post('greet')
  async greet(@Body() greetRequest: GreetRequest): Promise<GreetResponse> {
    try {
      console.log(`👋 Processing greet request for: ${greetRequest.name}`);

      const response = this.appService.greet(greetRequest.name);

      console.log(`✅ Generated greeting for: ${greetRequest.name}`);

      return response;
    } catch (error) {
      console.error(`❌ Error processing greet request:`, error.message);
      throw error;
    }
  }
}
