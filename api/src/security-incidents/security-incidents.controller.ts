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
import { CreateSecurityIncidentDto } from './dto/create-security-incident.dto';
import { UpdateSecurityIncidentDto } from './dto/update-security-incident.dto';
import { AssignSecurityIncidentDto } from './dto/assign-security-incident.dto';
import { SecurityIncidentsService } from './security-incidents.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Sự cố an ninh')
@ApiBearerAuth('access-token')
@Controller('security-incidents')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SecurityIncidentsController {
  constructor(private readonly service: SecurityIncidentsService) {}
  @Get() findAll(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.service.findAll(request.user);
  }
  @Post() create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateSecurityIncidentDto,
  ): Promise<object> {
    return this.service.create(request.user, dto);
  }
  @Patch(':id/status')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.SECURITY)
  update(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSecurityIncidentDto,
  ): Promise<object> {
    return this.service.update(id, request.user, dto);
  }

  @Get(':id/assignees')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  assignees(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.findAssignees(id, request.user);
  }

  @Patch(':id/assign')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  assign(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignSecurityIncidentDto,
  ): Promise<object> {
    return this.service.assign(id, request.user, dto.assigneeId);
  }
}
