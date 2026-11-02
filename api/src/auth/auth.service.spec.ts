import { JwtService } from '@nestjs/jwt';
import { hash } from 'bcryptjs';
import { PrismaService } from '../database/prisma.service';
import { RoleCode, UserStatus } from '../generated/prisma/client';
import { AuthMailService } from './auth-mail.service';
import { AuthService } from './auth.service';

describe('AuthService registration OTP', () => {
  it('chỉ lưu yêu cầu tạm và chưa tạo user trước khi xác minh OTP', async () => {
    const userCreate = jest.fn();
    const verificationUpsert = jest.fn().mockResolvedValue({});
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: userCreate,
      },
      registrationVerification: { upsert: verificationUpsert },
    } as unknown as PrismaService;
    const jwt = { signAsync: jest.fn() } as unknown as JwtService;
    const mail = {
      sendRegistrationVerificationCode: jest.fn().mockResolvedValue(false),
    } as unknown as AuthMailService;
    const service = new AuthService(prisma, jwt, mail);

    const result = await service.requestRegistrationOtp({
      fullName: 'Nguyễn Văn An',
      email: 'AN@example.com',
      password: 'Homie@123',
    });

    expect(userCreate).not.toHaveBeenCalled();
    expect(verificationUpsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { email: 'an@example.com' } }),
    );
    expect(result.developmentCode).toMatch(/^\d{6}$/);
    expect(result.expiresInSeconds).toBe(900);
  });

  it('OTP hợp lệ mới tạo cư dân, xóa yêu cầu tạm và trả JWT', async () => {
    const codeHash = await hash('123456', 4);
    const createdUser = {
      id: '0f0dc251-265f-44f0-a389-909e93d900bd',
      email: 'an@example.com',
      passwordHash: 'stored-password-hash',
      fullName: 'Nguyễn Văn An',
      phone: null,
      dateOfBirth: null,
      contactAddress: null,
      avatarUrl: null,
      googleSubject: null,
      passwordResetCodeHash: null,
      passwordResetExpiresAt: null,
      status: UserStatus.ACTIVE,
      createdAt: new Date(),
      updatedAt: new Date(),
      userRoles: [
        {
          role: {
            id: 'role-resident',
            code: RoleCode.RESIDENT,
            name: 'Cư dân',
            description: null,
            isActive: true,
            createdAt: new Date(),
            updatedAt: new Date(),
          },
        },
      ],
      apartmentMemberships: [],
    };
    const deleteVerification = jest.fn().mockResolvedValue({});
    const refreshSessionCreate = jest.fn().mockResolvedValue({});
    const transaction = {
      user: { create: jest.fn().mockResolvedValue(createdUser) },
      registrationVerification: { delete: deleteVerification },
    };
    const prisma = {
      registrationVerification: {
        findUnique: jest.fn().mockResolvedValue({
          email: 'an@example.com',
          fullName: 'Nguyễn Văn An',
          phone: null,
          passwordHash: 'stored-password-hash',
          codeHash,
          expiresAt: new Date(Date.now() + 60_000),
          attempts: 0,
        }),
      },
      role: {
        findUnique: jest
          .fn()
          .mockResolvedValue({ id: 'role-resident', isActive: true }),
      },
      $transaction: jest.fn(
        async (callback: (client: typeof transaction) => Promise<unknown>) =>
          callback(transaction),
      ),
      refreshSession: { create: refreshSessionCreate },
    } as unknown as PrismaService;
    const jwt = {
      signAsync: jest.fn().mockResolvedValue('jwt-registration-test'),
    } as unknown as JwtService;
    const mail = {} as AuthMailService;
    const service = new AuthService(prisma, jwt, mail);

    const result = await service.verifyRegistrationOtp({
      email: 'AN@example.com',
      code: '123456',
    });

    expect(transaction.user.create).toHaveBeenCalled();
    expect(deleteVerification).toHaveBeenCalledWith({
      where: { email: 'an@example.com' },
    });
    expect(result.accessToken).toBe('jwt-registration-test');
    expect(result.refreshToken).toMatch(
      /^[0-9a-f-]{36}\.[A-Za-z0-9_-]+$/i,
    );
    expect(refreshSessionCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: createdUser.id,
          tokenHash: expect.stringMatching(/^[0-9a-f]{64}$/),
        }),
      }),
    );
    expect(result.user.roles).toEqual([RoleCode.RESIDENT]);
    expect(result.user.apartmentCode).toBeNull();
  });
});
