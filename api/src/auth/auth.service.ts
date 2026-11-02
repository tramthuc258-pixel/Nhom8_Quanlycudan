import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { compare, hash } from 'bcryptjs';
import { createHash, randomBytes, randomInt, randomUUID } from 'node:crypto';
import {
  MembershipStatus,
  Prisma,
  RoleCode,
  UserStatus,
} from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import {
  JWT_EXPIRES_IN,
  REFRESH_TOKEN_EXPIRES_DAYS,
} from './auth.constants';
import type {
  AuthenticatedUser,
  AuthResponse,
  ForgotPasswordResponse,
  JwtPayload,
  RegistrationOtpResponse,
} from './auth.types';
import { AuthMailService } from './auth-mail.service';
import type { ForgotPasswordDto } from './dto/forgot-password.dto';
import type { ResetPasswordDto } from './dto/reset-password.dto';
import type { LoginDto } from './dto/login.dto';
import type { RegisterDto } from './dto/register.dto';
import type { ChangePasswordDto } from './dto/change-password.dto';
import type { UpdateProfileDto } from './dto/update-profile.dto';
import type { VerifyRegistrationDto } from './dto/verify-registration.dto';

const userWithRoles = {
  userRoles: {
    include: {
      role: true,
    },
  },
  apartmentMemberships: {
    where: { status: MembershipStatus.ACTIVE },
    include: { apartment: true },
    orderBy: { isPrimary: 'desc' },
    take: 1,
  },
} satisfies Prisma.UserInclude;

type UserWithRoles = Prisma.UserGetPayload<{ include: typeof userWithRoles }>;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly authMailService: AuthMailService,
  ) {}

  async requestRegistrationOtp(
    dto: RegisterDto,
  ): Promise<RegistrationOtpResponse> {
    const email = dto.email.trim().toLowerCase();
    const existingUser = await this.prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw new ConflictException('Email đã được sử dụng.');
    }

    const code = randomInt(100000, 1000000).toString();
    const [passwordHash, codeHash] = await Promise.all([
      hash(dto.password, 12),
      hash(code, 12),
    ]);
    const expiresInSeconds = 15 * 60;

    await this.prisma.registrationVerification.upsert({
      where: { email },
      update: {
        fullName: dto.fullName.trim(),
        phone: dto.phone?.trim() || null,
        passwordHash,
        codeHash,
        expiresAt: new Date(Date.now() + expiresInSeconds * 1000),
        attempts: 0,
      },
      create: {
        email,
        fullName: dto.fullName.trim(),
        phone: dto.phone?.trim() || null,
        passwordHash,
        codeHash,
        expiresAt: new Date(Date.now() + expiresInSeconds * 1000),
      },
    });

    const delivered =
      await this.authMailService.sendRegistrationVerificationCode(email, code);
    const message = delivered
      ? 'Homie đã gửi mã OTP xác minh đến email của bạn.'
      : 'Đang chạy ở chế độ phát triển. Hãy dùng mã OTP thử nghiệm hiển thị trên ứng dụng.';
    return delivered
      ? { message, expiresInSeconds }
      : { message, expiresInSeconds, developmentCode: code };
  }

  async verifyRegistrationOtp(
    dto: VerifyRegistrationDto,
  ): Promise<AuthResponse> {
    const email = dto.email.trim().toLowerCase();
    const verification = await this.prisma.registrationVerification.findUnique({
      where: { email },
    });
    const validCode =
      verification &&
      verification.expiresAt.getTime() > Date.now() &&
      verification.attempts < 5 &&
      (await compare(dto.code, verification.codeHash));

    if (!verification || !validCode) {
      if (verification && verification.attempts < 5) {
        await this.prisma.registrationVerification.update({
          where: { email },
          data: { attempts: { increment: 1 } },
        });
      }
      throw new BadRequestException(
        'Mã OTP không hợp lệ, đã hết hạn hoặc đã nhập sai quá số lần cho phép.',
      );
    }

    const residentRole = await this.prisma.role.findUnique({
      where: { code: RoleCode.RESIDENT },
    });
    if (!residentRole?.isActive) {
      throw new ConflictException('Vai trò cư dân chưa được khởi tạo.');
    }

    try {
      const user = await this.prisma.$transaction(async (transaction) => {
        const created = await transaction.user.create({
          data: {
            email,
            passwordHash: verification.passwordHash,
            fullName: verification.fullName,
            phone: verification.phone,
            userRoles: { create: { roleId: residentRole.id } },
          },
          include: userWithRoles,
        });
        await transaction.registrationVerification.delete({ where: { email } });
        return created;
      });
      return this.createAuthResponse(user);
    } catch (error: unknown) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Email đã được sử dụng.');
      }
      throw error;
    }
  }

  async login(dto: LoginDto): Promise<AuthResponse> {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({
      where: { email },
      include: userWithRoles,
    });

    if (
      !user ||
      user.status !== UserStatus.ACTIVE ||
      !(await compare(dto.password, user.passwordHash))
    ) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng.');
    }

    return this.createAuthResponse(user);
  }

  async requestPasswordReset(
    dto: ForgotPasswordDto,
  ): Promise<ForgotPasswordResponse> {
    const message =
      'Nếu email tồn tại, Homie đã gửi mã đặt lại mật khẩu có hiệu lực 15 phút.';
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (!user || user.status !== UserStatus.ACTIVE) return { message };

    const code = randomInt(100000, 1000000).toString();
    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordResetCodeHash: await hash(code, 12),
        passwordResetExpiresAt: new Date(Date.now() + 15 * 60 * 1000),
      },
    });

    const delivered = await this.authMailService.sendPasswordResetCode(
      user.email,
      code,
    );
    return delivered ? { message } : { message, developmentCode: code };
  }

  async resetPassword(dto: ResetPasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    const validCode =
      user?.passwordResetCodeHash &&
      user.passwordResetExpiresAt &&
      user.passwordResetExpiresAt.getTime() > Date.now() &&
      (await compare(dto.code, user.passwordResetCodeHash));
    if (!user || !validCode) {
      throw new BadRequestException(
        'Mã xác nhận không hợp lệ hoặc đã hết hạn.',
      );
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: {
          passwordHash: await hash(dto.newPassword, 12),
          passwordResetCodeHash: null,
          passwordResetExpiresAt: null,
        },
      }),
      this.prisma.refreshSession.updateMany({
        where: { userId: user.id, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);
  }

  async validateAccessToken(payload: JwtPayload): Promise<AuthenticatedUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: userWithRoles,
    });

    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('Tài khoản không còn hoạt động.');
    }

    return this.toAuthenticatedUser(user);
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<AuthenticatedUser> {
    if (dto.avatarUrl) {
      const storageBaseUrl = process.env.SUPABASE_URL?.replace(/\/$/, '');
      if (
        !storageBaseUrl ||
        !dto.avatarUrl.startsWith(`${storageBaseUrl}/storage/v1/`)
      ) {
        throw new BadRequestException(
          'Ảnh đại diện phải được tải lên Supabase Storage của Homie.',
        );
      }
    }

    const user = await this.prisma.user.update({
      where: { id: userId },
      data: {
        fullName: dto.fullName.trim(),
        phone: dto.phoneNumber?.trim() || null,
        dateOfBirth: dto.dateOfBirth ? new Date(dto.dateOfBirth) : null,
        contactAddress: dto.contactAddress?.trim() || null,
        ...(dto.avatarUrl ? { avatarUrl: dto.avatarUrl } : {}),
      },
      include: userWithRoles,
    });

    return this.toAuthenticatedUser(user);
  }

  async changePassword(
    userId: string,
    dto: ChangePasswordDto,
  ): Promise<AuthResponse> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });

    if (!user || !(await compare(dto.currentPassword, user.passwordHash))) {
      throw new BadRequestException('Mật khẩu hiện tại không chính xác.');
    }

    const [updatedUser] = await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: {
          passwordHash: await hash(dto.newPassword, 12),
          mustChangePassword: false,
        },
        include: userWithRoles,
      }),
      this.prisma.refreshSession.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      }),
    ]);
    return this.createAuthResponse(updatedUser);
  }

  async refresh(rawToken: string): Promise<AuthResponse> {
    const { id, secret } = this.parseRefreshToken(rawToken);
    const session = await this.prisma.refreshSession.findUnique({
      where: { id },
      include: { user: { include: userWithRoles } },
    });
    if (
      !session ||
      session.revokedAt ||
      session.expiresAt.getTime() <= Date.now() ||
      session.user.status !== UserStatus.ACTIVE ||
      session.tokenHash !== this.hashRefreshSecret(secret)
    ) {
      throw new UnauthorizedException('Phiên đăng nhập đã hết hạn hoặc bị thu hồi.');
    }

    await this.prisma.refreshSession.update({
      where: { id },
      data: { revokedAt: new Date() },
    });
    return this.createAuthResponse(session.user);
  }

  async logout(rawToken: string): Promise<void> {
    const parsed = this.tryParseRefreshToken(rawToken);
    if (!parsed) return;
    await this.prisma.refreshSession.updateMany({
      where: {
        id: parsed.id,
        tokenHash: this.hashRefreshSecret(parsed.secret),
        revokedAt: null,
      },
      data: { revokedAt: new Date() },
    });
  }

  private async createAuthResponse(user: UserWithRoles): Promise<AuthResponse> {
    const authenticatedUser = this.toAuthenticatedUser(user);
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      roles: authenticatedUser.roles,
    };

    const refreshToken = await this.createRefreshSession(user.id);
    return {
      accessToken: await this.jwtService.signAsync(payload),
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: JWT_EXPIRES_IN,
      user: authenticatedUser,
    };
  }

  private async createRefreshSession(userId: string): Promise<string> {
    const id = randomUUID();
    const secret = randomBytes(32).toString('base64url');
    await this.prisma.refreshSession.create({
      data: {
        id,
        userId,
        tokenHash: this.hashRefreshSecret(secret),
        expiresAt: new Date(
          Date.now() + REFRESH_TOKEN_EXPIRES_DAYS * 24 * 60 * 60 * 1000,
        ),
      },
    });
    return `${id}.${secret}`;
  }

  private parseRefreshToken(rawToken: string): { id: string; secret: string } {
    const parsed = this.tryParseRefreshToken(rawToken);
    if (!parsed) throw new UnauthorizedException('Refresh token không hợp lệ.');
    return parsed;
  }

  private tryParseRefreshToken(
    rawToken: string,
  ): { id: string; secret: string } | null {
    const separator = rawToken.indexOf('.');
    if (separator <= 0 || separator === rawToken.length - 1) return null;
    return {
      id: rawToken.substring(0, separator),
      secret: rawToken.substring(separator + 1),
    };
  }

  private hashRefreshSecret(secret: string): string {
    return createHash('sha256').update(secret).digest('hex');
  }

  private toAuthenticatedUser(user: UserWithRoles): AuthenticatedUser {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      dateOfBirth: user.dateOfBirth,
      contactAddress: user.contactAddress,
      avatarUrl: user.avatarUrl,
      apartmentCode: user.apartmentMemberships[0]?.apartment.code ?? null,
      status: user.status,
      mustChangePassword: user.mustChangePassword,
      roles: user.userRoles
        .filter(({ role }) => role.isActive)
        .map(({ role }) => role.code),
    };
  }
}
