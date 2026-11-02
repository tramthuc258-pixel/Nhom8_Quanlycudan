import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { RoleCode, UserStatus } from '../generated/prisma/client';
import { ApartmentsService } from './apartments.service';
import { BuildingAccessService } from '../building-access/building-access.service';

describe('ApartmentsService', () => {
  const createUser = (roles: RoleCode[]): AuthenticatedUser => ({
    id: '2b46b739-9d80-40fc-9271-02c56122971a',
    email: 'anh.resident@homie.com',
    fullName: 'Cư dân Homie',
    phone: null,
    dateOfBirth: null,
    contactAddress: null,
    apartmentCode: null,
    status: UserStatus.ACTIVE,
    mustChangePassword: false,
    roles,
  });

  const createService = () => {
    const findMany = jest.fn().mockResolvedValue([]);
    const accessibleStaffBuildingIds = jest
      .fn()
      .mockResolvedValue(['d3ef8a1b-b524-40db-bf5d-55c25a71dba8']);
    const prisma = {
      apartment: { findMany },
    } as unknown as PrismaService;
    const buildingAccess = {
      accessibleStaffBuildingIds,
    } as unknown as BuildingAccessService;
    return {
      service: new ApartmentsService(prisma, buildingAccess),
      findMany,
      accessibleStaffBuildingIds,
    };
  };

  it('chỉ lấy căn hộ đang liên kết với tài khoản cư dân', async () => {
    const { service, findMany } = createService();
    const user = createUser([RoleCode.RESIDENT]);

    await service.findAll(user);

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          memberships: {
            some: {
              userId: user.id,
              status: 'ACTIVE',
            },
          },
        },
      }),
    );
  });

  it('chỉ lấy căn hộ thuộc tòa được phân công cho nhân viên', async () => {
    const { service, findMany } = createService();

    await service.findAll(createUser([RoleCode.MANAGEMENT]));

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          buildingId: {
            in: ['d3ef8a1b-b524-40db-bf5d-55c25a71dba8'],
          },
        },
      }),
    );
  });
});
