import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from './database/prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  getInfo(): object {
    return {
      name: 'Homie API',
      version: '1.0.0',
      documentation: '/docs',
      health: '/api/health',
    };
  }

  async getHealth(): Promise<object> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return {
        status: 'ok',
        service: 'homie-api',
        database: 'connected',
        uptimeSeconds: Math.floor(process.uptime()),
        timestamp: new Date().toISOString(),
      };
    } catch {
      throw new ServiceUnavailableException({
        status: 'error',
        service: 'homie-api',
        database: 'unavailable',
        timestamp: new Date().toISOString(),
      });
    }
  }
}
