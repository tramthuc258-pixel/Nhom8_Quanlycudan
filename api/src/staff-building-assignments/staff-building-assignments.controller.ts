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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import type { AuthenticatedUser } from '../auth/auth.types';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { RoleCode } from '../generated/prisma/client';
import { CreateStaffAccountDto } from './dto/create-staff-account.dto';
import { SaveStaffBuildingAssignmentDto } from './dto/save-staff-building-assignment.dto';
import { UpdateStaffAccountDto } from './dto/update-staff-account.dto';
import { UpdateStaffStatusDto } from './dto/update-staff-status.dto';
import { StaffBuildingAssignmentsService } from './staff-building-assignments.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Phân công nhân viên theo tòa')
@ApiBearerAuth('access-token')
@Controller('staff-building-assignments')
@UseGuards(JwtAuthGuard, RolesGuard)
export class StaffBuildingAssignmentsController {
  constructor(private readonly service: StaffBuildingAssignmentsService) {}

  @Get('me')
  findMine(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.service.findMine(request.user);
  }

  @Get('staff')
  @Roles(RoleCode.ADMIN)
  findStaff(): Promise<object> {
    return this.service.findStaff();
  }

  @Post('staff')
  @Roles(RoleCode.ADMIN)
  createStaff(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateStaffAccountDto,
  ): Promise<object> {
    return this.service.createStaffAccount(dto, request.user);
  }

  @Patch('staff/:id')
  @Roles(RoleCode.ADMIN)
  updateStaff(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateStaffAccountDto,
  ): Promise<object> {
    return this.service.updateStaffAccount(id, dto);
  }

  @Patch('staff/:id/status')
  @Roles(RoleCode.ADMIN)
  updateStaffStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateStaffStatusDto,
  ): Promise<object> {
    return this.service.updateStaffStatus(id, dto.status);
  }

  @Post('staff/:id/reset-password')
  @Roles(RoleCode.ADMIN)
  resetStaffPassword(@Param('id', ParseUUIDPipe) id: string): Promise<object> {
    return this.service.resetStaffPassword(id);
  }

  @Get()
  @Roles(RoleCode.ADMIN)
  findAll(): Promise<object> {
    return this.service.findAll();
  }

  @Post()
  @Roles(RoleCode.ADMIN)
  save(
    @Req() request: AuthenticatedRequest,
    @Body() dto: SaveStaffBuildingAssignmentDto,
  ): Promise<object> {
    return this.service.save(dto, request.user);
  }

  @Patch(':id/end')
  @Roles(RoleCode.ADMIN)
  end(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.end(id, request.user);
  }
}
