import type { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RoleCode, UserStatus } from '../../generated/prisma/client';
import { RolesGuard } from './roles.guard';

describe('RolesGuard actor matrix', () => {
  const contextFor = (roles: RoleCode[]): ExecutionContext =>
    ({
      getHandler: () => rolesGuardHandler,
      getClass: () => RolesGuard,
      switchToHttp: () => ({
        getRequest: () => ({
          user: {
            id: '2b46b739-9d80-40fc-9271-02c56122971a',
            email: 'actor@homie.com',
            fullName: 'Actor',
            phone: null,
            dateOfBirth: null,
            contactAddress: null,
            avatarUrl: null,
            apartmentCode: null,
            status: UserStatus.ACTIVE,
            mustChangePassword: false,
            roles,
          },
        }),
      }),
    }) as unknown as ExecutionContext;

  const rolesGuardHandler = () => undefined;

  it.each([
    RoleCode.ADMIN,
    RoleCode.MANAGEMENT,
  ])('cho %s vào chức năng điều phối', (role) => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue([
        RoleCode.ADMIN,
        RoleCode.MANAGEMENT,
      ]),
    } as unknown as Reflector;
    expect(new RolesGuard(reflector).canActivate(contextFor([role]))).toBe(true);
  });

  it.each([
    RoleCode.RESIDENT,
    RoleCode.ACCOUNTANT,
    RoleCode.RECEPTIONIST,
    RoleCode.SECURITY,
    RoleCode.TECHNICIAN,
  ])('từ chối %s khỏi chức năng điều phối', (role) => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue([
        RoleCode.ADMIN,
        RoleCode.MANAGEMENT,
      ]),
    } as unknown as Reflector;
    expect(new RolesGuard(reflector).canActivate(contextFor([role]))).toBe(false);
  });
});
