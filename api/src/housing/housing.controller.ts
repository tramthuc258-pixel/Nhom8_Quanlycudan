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
import { CompleteApplicationDto } from './dto/complete-application.dto';
import { CreateApplicationDto } from './dto/create-application.dto';
import { CreateListingDto } from './dto/create-listing.dto';
import { ReviewDto } from './dto/review.dto';
import { UpdateHousingInquiryDto } from './dto/update-housing-inquiry.dto';
import { HousingService } from './housing.service';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Thuê và mua căn hộ')
@ApiBearerAuth('access-token')
@Controller('housing')
@UseGuards(JwtAuthGuard, RolesGuard)
export class HousingController {
  constructor(private readonly housingService: HousingService) {}

  @Get('listings')
  findListings(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.housingService.findListings(request.user);
  }

  @Post('listings')
  createListing(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateListingDto,
  ): Promise<object> {
    return this.housingService.createListing(request.user, dto);
  }

  @Patch('listings/:id/approve')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  approveListing(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.housingService.approveListing(id, request.user);
  }

  @Patch('listings/:id/reject')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  rejectListing(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewDto,
  ): Promise<object> {
    return this.housingService.rejectListing(id, request.user, dto.reason);
  }

  @Get('applications')
  findApplications(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.housingService.findApplications(request.user);
  }

  @Get('inquiries')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  findInquiries(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.housingService.findInquiries(request.user);
  }

  @Patch('inquiries/:id')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  updateInquiry(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateHousingInquiryDto,
  ): Promise<object> {
    return this.housingService.updateInquiry(id, request.user, dto);
  }

  @Post('applications')
  createApplication(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateApplicationDto,
  ): Promise<object> {
    return this.housingService.createApplication(request.user, dto);
  }

  @Patch('applications/:id/reject')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  rejectApplication(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewDto,
  ): Promise<object> {
    return this.housingService.rejectApplication(id, request.user, dto.reason);
  }

  @Patch('applications/:id/complete')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  completeApplication(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CompleteApplicationDto,
  ): Promise<object> {
    return this.housingService.completeApplication(id, request.user, dto);
  }
}
