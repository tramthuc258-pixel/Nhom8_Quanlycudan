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
import { AssignServiceRequestDto } from './dto/assign-service-request.dto';
import { CreateServiceRequestDto } from './dto/create-service-request.dto';
import { UpdateServiceRequestStatusDto } from './dto/update-service-request-status.dto';
import { RespondServiceResultDto } from './dto/respond-service-result.dto';
import { ResidentServicesService } from './resident-services.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Dịch vụ cư dân')
@ApiBearerAuth('access-token')
@Controller('resident-services')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ResidentServicesController {
  constructor(private readonly residentServices: ResidentServicesService) {}

  @Get('catalog')
  findCatalog(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.residentServices.findCatalog(request.user);
  }

  @Get('requests')
  findRequests(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.residentServices.findRequests(request.user);
  }

  @Post('requests')
  @Roles(RoleCode.RESIDENT)
  createRequest(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateServiceRequestDto,
  ): Promise<object> {
    return this.residentServices.createRequest(request.user, dto);
  }

  @Patch('requests/:id/cancel')
  @Roles(RoleCode.RESIDENT)
  cancelRequest(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.residentServices.cancelRequest(id, request.user);
  }

  @Patch('requests/:id/assign')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  assignRequest(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignServiceRequestDto,
  ): Promise<object> {
    return this.residentServices.assignRequest(id, request.user, dto);
  }

  @Get('requests/:id/assignees')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  findAssignees(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.residentServices.findAssignees(id, request.user);
  }

  @Patch('requests/:id/status')
  @Roles(
    RoleCode.ADMIN,
    RoleCode.MANAGEMENT,
    RoleCode.RECEPTIONIST,
    RoleCode.TECHNICIAN,
  )
  updateStatus(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateServiceRequestStatusDto,
  ): Promise<object> {
    return this.residentServices.updateStatus(id, request.user, dto);
  }

  @Patch('requests/:id/resident-response')
  @Roles(RoleCode.RESIDENT)
  respondToResult(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: RespondServiceResultDto,
  ): Promise<object> {
    return this.residentServices.respondToResult(id, request.user, dto);
  }

  @Patch('catalog/:id/toggle-active')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  toggleActive(@Param('id', ParseUUIDPipe) id: string): Promise<object> {
    return this.residentServices.toggleActive(id);
  }
}
