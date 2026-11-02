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
import type { AuthenticatedUser } from '../auth/auth.types';
import { Roles } from '../auth/decorators/roles.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { RoleCode } from '../generated/prisma/client';
import { AnnouncementsService } from './announcements.service';
import { CreateAnnouncementDto } from './dto/create-announcement.dto';
import { MarkAnnouncementsReadDto } from './dto/mark-announcements-read.dto';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Thông báo cư dân')
@ApiBearerAuth('access-token')
@Controller('announcements')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AnnouncementsController {
  constructor(private readonly announcementsService: AnnouncementsService) {}

  @Get()
  findAll(@Req() request: AuthenticatedRequest): Promise<object> {
    return this.announcementsService.findAll(request.user);
  }

  @Post()
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  create(
    @Req() request: AuthenticatedRequest,
    @Body() dto: CreateAnnouncementDto,
  ): Promise<object> {
    return this.announcementsService.create(request.user, dto);
  }

  @Patch(':id/toggle-published')
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  togglePublished(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.announcementsService.togglePublished(id, request.user);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Roles(RoleCode.ADMIN, RoleCode.MANAGEMENT)
  remove(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<void> {
    return this.announcementsService.remove(id, request.user);
  }

  @Patch(':id/read')
  markAsRead(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<object> {
    return this.announcementsService.markAsRead(id, request.user);
  }

  @Patch('read-all')
  markAllAsRead(
    @Req() request: AuthenticatedRequest,
    @Body() dto: MarkAnnouncementsReadDto,
  ): Promise<object> {
    return this.announcementsService.markAllAsRead(
      dto.announcementIds,
      request.user,
    );
  }
}
