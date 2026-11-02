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
import { RoleCode } from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { CreateHouseholdMemberDto } from './dto/create-household-member.dto';
import { CreateMembershipDto } from './dto/create-membership.dto';
import { CreateResidenceVerificationDto } from './dto/create-residence-verification.dto';
import { ReviewResidenceVerificationDto } from './dto/review-residence-verification.dto';
import { ResidentsService } from './residents.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Cư dân và quan hệ căn hộ')
@ApiBearerAuth('access-token')
@Controller()
@UseGuards(JwtAuthGuard, RolesGuard)
export class ResidentsController {
  constructor(private readonly residentsService: ResidentsService) {}

  @Get('residents')
  findResidents(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.residentsService.findResidents(request.user);
  }

  @Get('apartment-memberships')
  findMemberships(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.residentsService.findMemberships(request.user);
  }

  @Post('apartment-memberships')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  createMembership(
    @Body() dto: CreateMembershipDto,
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.createMembership(dto, request.user);
  }

  @Patch('apartment-memberships/:id/end')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  endMembership(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.endMembership(id, request.user);
  }

  @Get('household-members')
  findHouseholdMembers(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.residentsService.findHouseholdMembers(request.user);
  }

  @Post('household-members')
  createHouseholdMember(
    @Body() dto: CreateHouseholdMemberDto,
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.createHouseholdMember(dto, request.user);
  }

  @Patch('household-members/:id/end')
  endHouseholdMember(
    @Param('id', ParseUUIDPipe) id: string,
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.endHouseholdMember(id, request.user);
  }

  @Get('residence-verification/me')
  getMyResidenceVerification(
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.getMyResidenceVerification(request.user);
  }

  @Get('residence-verification/apartments')
  findResidenceVerificationApartments(): Promise<object> {
    return this.residentsService.findResidenceVerificationApartments();
  }

  @Post('residence-verification/requests')
  createResidenceVerification(
    @Body() dto: CreateResidenceVerificationDto,
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.createResidenceVerification(dto, request.user);
  }

  @Get('residence-verification/requests')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  findResidenceVerifications(
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.findResidenceVerifications(request.user);
  }

  @Patch('residence-verification/requests/:id/approve')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  approveResidenceVerification(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewResidenceVerificationDto,
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.approveResidenceVerification(
      id,
      dto,
      request.user,
    );
  }

  @Patch('residence-verification/requests/:id/reject')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  rejectResidenceVerification(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewResidenceVerificationDto,
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.residentsService.rejectResidenceVerification(
      id,
      dto,
      request.user,
    );
  }
}
