import { SetMetadata } from '@nestjs/common';
import type { RoleCode } from '../../generated/prisma/client';

export const ROLES_KEY = 'roles';
export const Roles = (...roles: RoleCode[]): MethodDecorator & ClassDecorator =>
  SetMetadata(ROLES_KEY, roles);
