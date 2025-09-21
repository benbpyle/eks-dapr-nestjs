import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { DaprClient, HttpMethod } from '@dapr/dapr';

@Injectable()
export class GreeterService implements OnModuleDestroy {
  private readonly daprClient: DaprClient;

  constructor() {
    // Initialize Dapr Client - it will automatically use the correct Dapr sidecar
    this.daprClient = new DaprClient({
      daprHost: process.env.DAPR_HTTP_HOST || 'localhost',
      daprPort: process.env.DAPR_HTTP_PORT || '3500',
    });

    console.log('🔗 Dapr Client initialized');
  }

  async callGreeterService(name: string): Promise<any> {
    try {
      console.log(`📞 Calling greeter service via Dapr Client for: ${name}`);

      const requestBody = { name };

      // Use Dapr Client for service invocation
      // This automatically handles W3C trace context propagation
      const response = await this.daprClient.invoker.invoke(
        'greeter',        // App ID of the target service
        'greet',          // Method name
        HttpMethod.POST,  // HTTP method
        requestBody       // Request body
      );

      console.log(`✅ Received response from greeter service for: ${name}`);
      return response;

    } catch (error) {
      console.error(`❌ Error calling greeter service via Dapr:`, error.message);
      throw error;
    }
  }

  // Cleanup Dapr client on service destroy
  async onModuleDestroy() {
    if (this.daprClient) {
      await this.daprClient.stop();
      console.log('🛑 Dapr Client stopped');
    }
  }
}
