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
import { AmenitiesService } from './amenities.service';
import { BlockAmenitySlotDto } from './dto/block-amenity-slot.dto';
import { CreateAmenityBookingDto } from './dto/create-amenity-booking.dto';
import { ReviewAmenityBookingDto } from './dto/review-amenity-booking.dto';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Tiện ích chung')
@ApiBearerAuth('access-token')
@Controller('amenities')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AmenitiesController {
  constructor(private readonly service: AmenitiesService) {}

  @Get() catalog(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.service.catalog(request.user);
  }
  @Get('bookings') bookings(
    @Req() request: AuthenticatedRequest,
  ): Promise<object> {
    return this.service.bookings(request.user);
  }
  @Post('bookings')
  @Roles(RoleCode.RESIDENT)
  create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateAmenityBookingDto,
  ): Promise<object> {
    return this.service.create(request.user, dto);
  }
  @Patch('bookings/:id/cancel')
  @Roles(RoleCode.RESIDENT)
  cancel(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.cancel(id, request.user);
  }
  @Patch('bookings/:id/review')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT, RoleCode.RECEPTIONIST)
  review(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ReviewAmenityBookingDto,
  ): Promise<object> {
    return this.service.review(id, request.user, dto);
  }
  @Patch('bookings/:id/check-in')
  @Roles(RoleCode.ADMIN, RoleCode.RECEPTIONIST)
  checkIn(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.checkIn(id, request.user);
  }
  @Patch('bookings/:id/complete')
  @Roles(RoleCode.ADMIN, RoleCode.RECEPTIONIST)
  complete(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.complete(id, request.user);
  }
  @Patch('bookings/:id/no-show')
  @Roles(RoleCode.ADMIN, RoleCode.RECEPTIONIST)
  markNoShow(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.markNoShow(id, request.user);
  }
  @Post('blocked-slots')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  block(
    @Req() request: AuthenticatedRequest,
    @Body() dto: BlockAmenitySlotDto,
  ): Promise<object> {
    return this.service.block(request.user, dto);
  }
  @Patch(':id/toggle-active')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  toggle(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.service.toggle(id, request.user);
  }
}
