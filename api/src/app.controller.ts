import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('Hệ thống')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiOperation({ summary: 'Thông tin nhận diện API Homie' })
  getInfo(): object {
    return this.appService.getInfo();
  }

  @Get('health')
  @ApiOperation({ summary: 'Kiểm tra API và kết nối cơ sở dữ liệu' })
  @ApiOkResponse({
    schema: {
      example: {
        status: 'ok',
        service: 'homie-api',
        database: 'connected',
        uptimeSeconds: 125,
        timestamp: '2026-10-30T04:20:00.000Z',
      },
    },
  })
  getHealth(): Promise<object> {
    return this.appService.getHealth();
  }
}
