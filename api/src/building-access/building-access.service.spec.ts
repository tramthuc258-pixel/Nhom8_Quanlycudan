import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { RoleCode, UserStatus } from '../generated/prisma/client';
import { BuildingAccessService } from './building-access.service';

describe('BuildingAccessService', () => {
  const user = (roles: RoleCode[]): AuthenticatedUser => ({
    id: '2b46b739-9d80-40fc-9271-02c56122971a',
    email: 'staff.member@homie.com',
    fullName: 'Nhân viên Homie',
    phone: null,
    dateOfBirth: null,
    contactAddress: null,
    apartmentCode: null,
    status: UserStatus.ACTIVE,
    mustChangePassword: false,
    roles,
  });

  const createService = () => {
    const findMany = jest
      .fn()
      .mockResolvedValue([
        { buildingId: 'a26cd819-31a9-4a9f-abd0-04555b858c99' },
      ]);
    const prisma = {
      staffBuildingAssignment: { findMany },
    } as unknown as PrismaService;
    return { service: new BuildingAccessService(prisma), findMany };
  };

  it('cho quản trị viên truy cập toàn hệ thống', async () => {
    const { service, findMany } = createService();

    await expect(
      service.accessibleStaffBuildingIds(user([RoleCode.ADMIN])),
    ).resolves.toBeNull();
    expect(findMany).not.toHaveBeenCalled();
  });

  it('chỉ trả về các tòa đang được phân công cho nhân viên', async () => {
    const { service } = createService();

    await expect(
      service.accessibleStaffBuildingIds(user([RoleCode.MANAGEMENT])),
    ).resolves.toEqual(['a26cd819-31a9-4a9f-abd0-04555b858c99']);
  });

  it.each([
    RoleCode.MANAGEMENT,
    RoleCode.ACCOUNTANT,
    RoleCode.RECEPTIONIST,
    RoleCode.SECURITY,
    RoleCode.TECHNICIAN,
  ])('giới hạn %s trong đúng danh sách tòa được giao', async (role) => {
    const { service } = createService();
    await expect(
      service.accessibleStaffBuildingIds(user([role])),
    ).resolves.toEqual(['a26cd819-31a9-4a9f-abd0-04555b858c99']);
    await expect(
      service.assertBuildingAccess(
        user([role]),
        '561b45d6-6d12-4140-a5ac-b4ee379c71c5',
      ),
    ).rejects.toThrow('không được phân công phụ trách tòa nhà');
  });

  it('từ chối tòa không thuộc phạm vi được phân công', async () => {
    const { service } = createService();

    await expect(
      service.assertBuildingAccess(
        user([RoleCode.MANAGEMENT]),
        '561b45d6-6d12-4140-a5ac-b4ee379c71c5',
      ),
    ).rejects.toThrow('không được phân công phụ trách tòa nhà');
  });
});
