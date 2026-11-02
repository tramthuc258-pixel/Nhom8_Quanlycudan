import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { AuthenticatedUser } from '../auth/auth.types';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { RoleCode } from '../generated/prisma/client';
import { CreateTemporaryStayDto } from './dto/create-temporary-stay.dto';
import { ReviewTemporaryStayDto } from './dto/review-temporary-stay.dto';
import { TemporaryStaysService } from './temporary-stays.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Khách lưu trú qua đêm')
@ApiBearerAuth('access-token')
@Controller('temporary-stays')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TemporaryStaysController {
  constructor(private readonly service: TemporaryStaysService) {}

  @Get()
  findAll(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.service.findAll(request.user);
  }

  @Post()
  @Roles(RoleCode.RESIDENT)
  create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateTemporaryStayDto,
  ): Promise<object> {
    return this.service.create(request.user, dto);
  }

  @Patch(':id/cancel')
  @Roles(RoleCode.RESIDENT)
  cancel(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.cancel(id, request.user);
  }

  @Patch(':id/review')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST)
  review(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewTemporaryStayDto,
  ): Promise<object> {
    return this.service.review(id, request.user, dto);
  }

  @Patch(':id/check-in')
  @Roles(RoleCode.ADMIN, RoleCode.SECURITY)
  checkIn(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.checkIn(id, request.user);
  }

  @Patch(':id/check-out')
  @Roles(RoleCode.ADMIN, RoleCode.SECURITY)
  checkOut(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.checkOut(id, request.user);
  }
}
