import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { Request } from 'express';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { RoleCode } from '../generated/prisma/client';
import { minutes, Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import type {
  AuthenticatedUser,
  AuthResponse,
  ForgotPasswordResponse,
  RegistrationOtpResponse,
} from './auth.types';
import { Roles } from './decorators/roles.decorator';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { VerifyRegistrationDto } from './dto/verify-registration.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RolesGuard } from './guards/roles.guard';

type AuthenticatedRequest = Request & { user: AuthenticatedUser };

@ApiTags('Xác thực và tài khoản')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Throttle({ default: { limit: 3, ttl: minutes(15) } })
  @ApiOperation({
    summary: 'Gửi OTP email để bắt đầu đăng ký tài khoản cư dân',
  })
  @ApiCreatedResponse({
    description: 'OTP đã được gửi hoặc trả về ở chế độ phát triển.',
    schema: {
      example: {
        message: 'Homie đã gửi mã OTP xác minh đến email của bạn.',
        expiresInSeconds: 900,
      },
    },
  })
  register(@Body() dto: RegisterDto): Promise<RegistrationOtpResponse> {
    return this.authService.requestRegistrationOtp(dto);
  }

  @Post('register/verify')
  @Throttle({ default: { limit: 10, ttl: minutes(15) } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Xác minh OTP và tạo tài khoản cư dân',
  })
  @ApiOkResponse({
    description: 'Tài khoản được tạo và API trả JWT đăng nhập.',
    schema: {
      example: {
        accessToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        refreshToken: '550e8400-e29b-41d4-a716-446655440000.secret-token',
        tokenType: 'Bearer',
        expiresIn: '15m',
        user: {
          id: '0f0dc251-265f-44f0-a389-909e93d900bd',
          email: 'cudan@example.com',
          fullName: 'Nguyễn Văn An',
          phone: null,
          apartmentCode: null,
          status: 'ACTIVE',
          roles: ['RESIDENT'],
        },
      },
    },
  })
  verifyRegistration(
    @Body() dto: VerifyRegistrationDto,
  ): Promise<AuthResponse> {
    return this.authService.verifyRegistrationOtp(dto);
  }

  @Post('login')
  @Throttle({ default: { limit: 8, ttl: minutes(15) } })
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto): Promise<AuthResponse> {
    return this.authService.login(dto);
  }

  @Post('refresh')
  @Throttle({ default: { limit: 20, ttl: minutes(15) } })
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Đổi refresh token để nhận phiên đăng nhập mới' })
  refresh(@Body() dto: RefreshTokenDto): Promise<AuthResponse> {
    return this.authService.refresh(dto.refreshToken);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Thu hồi refresh token của thiết bị hiện tại' })
  logout(@Body() dto: RefreshTokenDto): Promise<void> {
    return this.authService.logout(dto.refreshToken);
  }

  @Post('forgot-password')
  @Throttle({ default: { limit: 3, ttl: minutes(15) } })
  @HttpCode(HttpStatus.OK)
  forgotPassword(
    @Body() dto: ForgotPasswordDto,
  ): Promise<ForgotPasswordResponse> {
    return this.authService.requestPasswordReset(dto);
  }

  @Post('reset-password')
  @Throttle({ default: { limit: 6, ttl: minutes(15) } })
  @HttpCode(HttpStatus.NO_CONTENT)
  resetPassword(@Body() dto: ResetPasswordDto): Promise<void> {
    return this.authService.resetPassword(dto);
  }

  @Get('profile')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  profile(@Req() request: AuthenticatedRequest): AuthenticatedUser {
    return request.user;
  }

  @Patch('profile')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard)
  updateProfile(
    @Req() request: AuthenticatedRequest,
    @Body() dto: UpdateProfileDto,
  ): Promise<AuthenticatedUser> {
    return this.authService.updateProfile(request.user.id, dto);
  }

  @Post('change-password')
  @ApiBearerAuth('access-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  changePassword(
    @Req() request: AuthenticatedRequest,
    @Body() dto: ChangePasswordDto,
  ): Promise<AuthResponse> {
    return this.authService.changePassword(request.user.id, dto);
  }

  @Get('admin-check')
  @ApiBearerAuth('access-token')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(RoleCode.ADMIN)
  adminCheck(@Req() request: AuthenticatedRequest): object {
    return {
      message: 'Bạn có quyền quản trị viên.',
      user: request.user,
    };
  }
}
