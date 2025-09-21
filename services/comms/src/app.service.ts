import { Injectable } from '@nestjs/common';

@Injectable()
export class AppService {
  getHealth() {
    return {
      status: 'healthy',
      service: 'nestjs-comms',
      version: '1.0.0',
    };
  }
}
