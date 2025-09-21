import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth() {
    return {
      status: 'healthy',
      service: 'nestjs-greeter',
      version: '1.0.0',
    };
  }

  greet(name: string): { message: string; service: string; timestamp: string } {
    return {
      message: `Hello, ${name} from NestJS greeter!`,
      service: 'nestjs-greeter',
      timestamp: new Date().toISOString(),
    };
  }
}
