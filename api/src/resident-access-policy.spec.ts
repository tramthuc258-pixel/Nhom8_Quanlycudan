import { ForbiddenException } from '@nestjs/common';
import type { AuthenticatedUser } from './auth/auth.types';
import { PrismaService } from './database/prisma.service';
import {
  MembershipType,
  RoleCode,
  UserStatus,
} from './generated/prisma/client';
import { NotificationsService } from './notifications/notifications.service';
import { ResidentServicesService } from './resident-services/resident-services.service';
import { AmenitiesService } from './amenities/amenities.service';
import { TemporaryStaysService } from './temporary-stays/temporary-stays.service';

describe('Resident owner/tenant access policy', () => {
  const owner: AuthenticatedUser = {
    id: '56a15a1f-77df-46bd-aebb-2145146cf099',
    email: 'an.owner@homie.com',
    fullName: 'Chủ sở hữu',
    phone: null,
    dateOfBirth: null,
    contactAddress: null,
    apartmentCode: null,
    status: UserStatus.ACTIVE,
    mustChangePassword: false,
    roles: [RoleCode.RESIDENT],
  };
  const apartmentId = '3aa16a77-7dad-4668-bd78-ea2237e1546f';
  const ownerThenTenant = jest.fn();

  beforeEach(() => {
    ownerThenTenant
      .mockReset()
      .mockResolvedValueOnce({
        id: 'owner-membership',
        type: MembershipType.OWNER,
      })
      .mockResolvedValueOnce({ id: 'tenant-membership' });
  });

  it('không cho chủ sở hữu đặt dịch vụ khi căn hộ đang có người thuê', async () => {
    const prisma = {
      apartmentMembership: { findFirst: ownerThenTenant },
    } as unknown as PrismaService;
    const service = new ResidentServicesService(
      prisma,
      {} as NotificationsService,
    );

    await expect(
      service.createRequest(owner, {
        apartmentId,
        serviceId: 'c2e44cc6-cff3-417c-ae16-61655f529834',
        scheduledAt: new Date(Date.now() + 86_400_000).toISOString(),
        quantity: 1,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('không cho chủ sở hữu đặt tiện ích khi căn hộ đang có người thuê', async () => {
    const prisma = {
      amenity: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'amenity-id',
          isActive: true,
          capacity: 10,
        }),
      },
      apartmentMembership: { findFirst: ownerThenTenant },
    } as unknown as PrismaService;
    const service = new AmenitiesService(prisma, {} as NotificationsService);

    await expect(
      service.create(owner, {
        apartmentId,
        amenityId: 'amenity-id',
        startAt: new Date(Date.now() + 86_400_000).toISOString(),
        attendeeCount: 2,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('không cho chủ sở hữu khai báo khách khi căn hộ đang có người thuê', async () => {
    const prisma = {
      apartmentMembership: { findFirst: ownerThenTenant },
    } as unknown as PrismaService;
    const service = new TemporaryStaysService(
      prisma,
      {} as NotificationsService,
    );

    await expect(
      service.create(owner, {
        apartmentId,
        guestFullName: 'Khách của chủ nhà',
        startDate: '2026-10-28',
        endDate: '2026-10-29',
        reason: 'Ở lại qua đêm',
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
