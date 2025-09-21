import { Controller, Get, Post, Body } from '@nestjs/common';
import { AppService } from './app.service';
import { GreeterService } from './greeter.service';

interface GreetRequest {
  name: string;
}

interface HealthResponse {
  status: string;
  service: string;
  version: string;
}

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly greeterService: GreeterService,
  ) {}

  @Get('health')
  getHealth(): HealthResponse {
    return this.appService.getHealth();
  }

  @Post('greet')
  async greet(@Body() greetRequest: GreetRequest) {
    console.log(`📝 Processing greet request for: ${greetRequest.name}`);

    try {
      // Dapr Client handles W3C trace context propagation automatically
      const response = await this.greeterService.callGreeterService(greetRequest.name);
      console.log(`✅ Successfully processed greeting for: ${greetRequest.name}`);
      return response;
    } catch (error) {
      console.error(`❌ Failed to process greeting for ${greetRequest.name}:`, error.message);

      // Return fallback response
      return {
        message: `Hello, ${greetRequest.name} (from fallback)!`,
        service: 'nestjs-comms',
        error: 'greeter_service_unavailable'
      };
    }
  }
}
