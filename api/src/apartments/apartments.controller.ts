import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleCode } from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ApartmentsService } from './apartments.service';
import { SaveApartmentDto } from './dto/save-apartment.dto';
import { UpdateApartmentStatusDto } from './dto/update-apartment-status.dto';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Tòa nhà và căn hộ')
@ApiBearerAuth('access-token')
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class ApartmentsController {
  constructor(private readonly apartmentsService: ApartmentsService) {}

  @Get('buildings')
  findBuildings(): Promise<object> {
    return this.apartmentsService.findBuildings();
  }

  @Get('apartments')
  findAll(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.apartmentsService.findAll(request.user);
  }

  @Post('apartments')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: SaveApartmentDto,
  ): Promise<object> {
    return this.apartmentsService.create(dto, request.user);
  }

  @Patch('apartments/:id')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  update(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: SaveApartmentDto,
  ): Promise<object> {
    return this.apartmentsService.update(id, dto, request.user);
  }

  @Patch('apartments/:id/status')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  updateStatus(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateApartmentStatusDto,
  ): Promise<object> {
    return this.apartmentsService.updateStatus(id, dto.status, request.user);
  }

  @Delete('apartments/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  remove(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.apartmentsService.remove(id, request.user);
  }
}
