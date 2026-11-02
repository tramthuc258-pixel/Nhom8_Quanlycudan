import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import type { AuthenticatedUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { DeviceInstallationsService } from './device-installations.service';
import { DeactivateDeviceInstallationDto } from './dto/deactivate-device-installation.dto';
import { SaveDeviceInstallationDto } from './dto/save-device-installation.dto';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Thiết bị nhận thông báo')
@ApiBearerAuth('access-token')
@Controller('device-installations')
@UseGuards(JwtAuthGuard)
export class DeviceInstallationsController {
  constructor(private readonly service: DeviceInstallationsService) {}

  @Post()
  @ApiOperation({ summary: 'Đăng ký thiết bị hiện tại để nhận thông báo đẩy' })
  save(
    @Req() request: AuthenticatedRequest,
    @Body() dto: SaveDeviceInstallationDto,
  ): Promise<object> {
    return this.service.save(request.user.id, dto);
  }

  @Get('me')
  @ApiOperation({ summary: 'Xem các thiết bị của tài khoản đang đăng nhập' })
  findMine(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.service.findMine(request.user.id);
  }

  @Patch('deactivate')
  @ApiOperation({ summary: 'Ngừng gửi thông báo tới thiết bị hiện tại' })
  deactivate(
    @Req() request: AuthenticatedRequest,
    @Body() dto: DeactivateDeviceInstallationDto,
  ): Promise<object> {
    return this.service.deactivate(request.user.id, dto.firebaseToken);
  }
}
