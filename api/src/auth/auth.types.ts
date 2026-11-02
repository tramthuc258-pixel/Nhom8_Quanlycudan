import type { RoleCode, UserStatus } from '../generated/prisma/client';

export interface JwtPayload {
  sub: string;
  email: string;
  roles: RoleCode[];
}

export interface AuthenticatedUser {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  dateOfBirth: Date | null;
  contactAddress: string | null;
  avatarUrl: string | null;
  apartmentCode: string | null;
  status: UserStatus;
  mustChangePassword: boolean;
  roles: RoleCode[];
}

export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: 'Bearer';
  expiresIn: string;
  user: AuthenticatedUser;
}

export interface ForgotPasswordResponse {
  message: string;
  developmentCode?: string;
}

export interface RegistrationOtpResponse {
  message: string;
  expiresInSeconds: number;
  developmentCode?: string;
}
