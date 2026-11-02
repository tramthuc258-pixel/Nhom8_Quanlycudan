import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { RoleCode, UserStatus } from '../generated/prisma/client';
import { NotificationsService } from '../notifications/notifications.service';
import { ResidentsService } from './residents.service';

describe('ResidentsService privacy', () => {
  const resident: AuthenticatedUser = {
    id: '56a15a1f-77df-46bd-aebb-2145146cf099',
    email: 'anh.resident@homie.com',
    fullName: 'Cư dân Homie',
    phone: '0900000000',
    dateOfBirth: null,
    contactAddress: null,
    apartmentCode: null,
    status: UserStatus.ACTIVE,
    mustChangePassword: false,
    roles: [RoleCode.RESIDENT],
  };

  const createService = () => {
    const userFindMany = jest.fn().mockResolvedValue([]);
    const membershipFindMany = jest.fn().mockResolvedValue([]);
    const householdFindMany = jest.fn().mockResolvedValue([]);
    const prisma = {
      user: { findMany: userFindMany },
      apartmentMembership: { findMany: membershipFindMany },
      householdMember: { findMany: householdFindMany },
    } as unknown as PrismaService;
    const notifications = {} as NotificationsService;
    return {
      service: new ResidentsService(prisma, notifications),
      userFindMany,
      membershipFindMany,
      householdFindMany,
    };
  };

  it('trả hồ sơ chủ sở hữu và người thuê cùng căn hộ đang hiệu lực', async () => {
    const { service, userFindMany, membershipFindMany } = createService();
    membershipFindMany.mockResolvedValueOnce([{ apartmentId: 'apartment-1' }]);

    await service.findResidents(resident);

    expect(userFindMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: UserStatus.ACTIVE,
          OR: expect.arrayContaining([
            { id: resident.id },
            expect.objectContaining({
              apartmentMemberships: expect.anything(),
            }),
          ]),
        }),
      }),
    );
  });

  it('trả quan hệ đang hiệu lực của hai bên trong cùng căn hộ', async () => {
    const { service, membershipFindMany } = createService();
    membershipFindMany.mockResolvedValueOnce([{ apartmentId: 'apartment-1' }]);

    await service.findMemberships(resident);

    expect(membershipFindMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          OR: expect.arrayContaining([
            { userId: resident.id },
            expect.objectContaining({
              apartmentId: { in: ['apartment-1'] },
              status: 'ACTIVE',
            }),
          ]),
        }),
      }),
    );
  });

  it('chỉ trả thành viên do chính cư dân khai báo', async () => {
    const { service, membershipFindMany, householdFindMany } = createService();
    membershipFindMany.mockResolvedValueOnce([{ apartmentId: 'apartment-1' }]);

    await service.findHouseholdMembers(resident);

    expect(householdFindMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          apartmentId: { in: ['apartment-1'] },
          createdById: resident.id,
        },
      }),
    );
  });
});
