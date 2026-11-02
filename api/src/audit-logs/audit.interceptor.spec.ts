import type { CallHandler, ExecutionContext } from '@nestjs/common';
import type { Request, Response } from 'express';
import { lastValueFrom, of } from 'rxjs';
import { RoleCode, UserStatus } from '../generated/prisma/client';
import type { AuthenticatedUser } from '../auth/auth.types';
import { AuditInterceptor } from './audit.interceptor';
import type { AuditLogsService } from './audit-logs.service';

describe('AuditInterceptor', () => {
  const admin: AuthenticatedUser = {
    id: '56a15a1f-77df-46bd-aebb-2145146cf099',
    email: 'admin@homie.com',
    fullName: 'Quản trị viên',
    phone: null,
    dateOfBirth: null,
    contactAddress: null,
    apartmentCode: null,
    status: UserStatus.ACTIVE,
    mustChangePassword: false,
    roles: [RoleCode.ADMIN],
  };

  const context = (request: Partial<Request>): ExecutionContext =>
    ({
      switchToHttp: () => ({
        getRequest: () => request,
        getResponse: () => ({ statusCode: 201 }) as Response,
      }),
    }) as ExecutionContext;

  it('ghi thao tác quản trị và che mật khẩu', async () => {
    const write = jest.fn().mockResolvedValue({});
    const interceptor = new AuditInterceptor({
      write,
    } as unknown as AuditLogsService);
    const request = {
      method: 'POST',
      path: '/api/staff-building-assignments/staff',
      user: admin,
      params: {},
      body: { email: 'staff@homie.com', password: 'secret-value' },
      ip: '127.0.0.1',
    } as unknown as Request;
    const next = { handle: () => of({ id: 'staff-id' }) } as CallHandler;

    await lastValueFrom(interceptor.intercept(context(request), next));
    await Promise.resolve();

    expect(write).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: admin.id,
        action: 'POST',
        resource: 'staff-building-assignments',
        targetId: 'staff-id',
        metadata: {
          input: { email: 'staff@homie.com', password: '[REDACTED]' },
        },
      }),
    );
  });

  it('ghi thao tác nghiệp vụ nhạy cảm của cư dân', async () => {
    const write = jest.fn().mockResolvedValue({});
    const interceptor = new AuditInterceptor({
      write,
    } as unknown as AuditLogsService);
    const request = {
      method: 'POST',
      path: '/api/maintenance',
      user: { ...admin, roles: [RoleCode.RESIDENT] },
    } as unknown as Request;

    await lastValueFrom(
      interceptor.intercept(context(request), {
        handle: () => of({}),
      } as CallHandler),
    );
    await Promise.resolve();

    expect(write).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: admin.id,
        action: 'POST',
        resource: 'maintenance',
      }),
    );
  });
});
