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
import { AssignMaintenanceRequestDto } from './dto/assign-maintenance-request.dto';
import { CreateMaintenanceRequestDto } from './dto/create-maintenance-request.dto';
import { UpdateMaintenanceStatusDto } from './dto/update-maintenance-status.dto';
import { RespondMaintenanceResultDto } from './dto/respond-maintenance-result.dto';
import { MaintenanceService } from './maintenance.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Yêu cầu sửa chữa')
@ApiBearerAuth('access-token')
@Controller('maintenance-requests')
@UseGuards(JwtAuthGuard, RolesGuard)
export class MaintenanceController {
  constructor(private readonly maintenanceService: MaintenanceService) {}

  @Get()
  findAll(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.maintenanceService.findAll(request.user);
  }

  @Post()
  create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateMaintenanceRequestDto,
  ): Promise<object> {
    return this.maintenanceService.create(request.user, dto);
  }

  @Patch(':id/assign')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  assign(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignMaintenanceRequestDto,
  ): Promise<object> {
    return this.maintenanceService.assign(id, request.user, dto);
  }

  @Get(':id/assignees')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  findAssignees(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.maintenanceService.findAssignees(id, request.user);
  }

  @Patch(':id/status')
  updateStatus(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateMaintenanceStatusDto,
  ): Promise<object> {
    return this.maintenanceService.updateStatus(id, request.user, dto);
  }

  @Patch(':id/resident-response')
  @Roles(RoleCode.RESIDENT)
  respondToResult(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RespondMaintenanceResultDto,
  ): Promise<object> {
    return this.maintenanceService.respondToResult(id, request.user, dto);
  }
}
