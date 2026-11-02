import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import { hash } from 'bcryptjs';
import {
  AmenityCategory,
  AmenityBookingStatus,
  AnnouncementAudience,
  AnnouncementCategory,
  AnnouncementPriority,
  ApartmentStatus,
  FeeCalculationType,
  HousingApplicationStatus,
  HousingContractStatus,
  HousingListingStatus,
  HousingTransactionType,
  InvoiceStatus,
  MaintenanceCategory,
  MaintenancePriority,
  MaintenanceStatus,
  MembershipStatus,
  MembershipType,
  NotificationType,
  PaymentMethod,
  PaymentStatus,
  PrismaClient,
  RoleCode,
  ServiceCategory,
  ServiceRequestStatus,
  SecurityIncidentStatus,
  SecurityIncidentType,
  TemporaryStayStatus,
  UserStatus,
} from '../src/generated/prisma/client';

const connectionString = process.env.DIRECT_URL ?? process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('Thiếu DIRECT_URL hoặc DATABASE_URL trong api/.env.');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

const roles = [
  {
    code: RoleCode.RESIDENT,
    name: 'Cư dân',
    description:
      'Chủ hộ, người thuê hoặc thành viên đang sinh sống tại căn hộ.',
  },
  {
    code: RoleCode.MANAGEMENT,
    name: 'Ban quản lý',
    description: 'Điều hành hoạt động chung của khu căn hộ.',
  },
  {
    code: RoleCode.ADMIN,
    name: 'Quản trị viên',
    description: 'Quản lý tài khoản, vai trò và cấu hình hệ thống.',
  },
  {
    code: RoleCode.ACCOUNTANT,
    name: 'Kế toán',
    description: 'Quản lý loại phí, hóa đơn và xác nhận thanh toán.',
  },
  {
    code: RoleCode.RECEPTIONIST,
    name: 'Lễ tân',
    description: 'Tra cứu thông tin và tiếp nhận yêu cầu thay cư dân.',
  },
  {
    code: RoleCode.SECURITY,
    name: 'Bảo vệ',
    description: 'Theo dõi khách lưu trú đã duyệt và ghi nhận sự cố an ninh.',
  },
  {
    code: RoleCode.TECHNICIAN,
    name: 'Kỹ thuật viên',
    description: 'Tiếp nhận và cập nhật tiến độ yêu cầu bảo trì.',
  },
] as const;

const apartments = [
  { code: 'A-0101', floor: 1, area: 68.5, bedrooms: 2 },
  { code: 'A-0102', floor: 1, area: 82, bedrooms: 3 },
  { code: 'A-0201', floor: 2, area: 68.5, bedrooms: 2 },
  { code: 'A-0202', floor: 2, area: 95, bedrooms: 3 },
  { code: 'A-0301', floor: 3, area: 72, bedrooms: 2 },
  { code: 'A-0302', floor: 3, area: 88, bedrooms: 3 },
  { code: 'A-0401', floor: 4, area: 55, bedrooms: 1 },
  { code: 'A-0402', floor: 4, area: 105, bedrooms: 3 },
] as const;

const feeTypes = [
  {
    code: 'MANAGEMENT_FEE',
    name: 'Phí quản lý',
    description:
      'Bao gồm vận hành tòa nhà, bảo vệ, vệ sinh và chăm sóc khu vực sử dụng chung. Điện, nước sử dụng riêng, Internet, gửi xe và kinh phí bảo trì được tính riêng nếu phát sinh.',
    calculationType: FeeCalculationType.BY_AREA,
    defaultUnitPrice: 12000,
  },
  {
    code: 'ELECTRICITY_FEE',
    name: 'Tiền điện',
    description: 'Chi phí điện theo số lượng điện năng tiêu thụ.',
    calculationType: FeeCalculationType.BY_QUANTITY,
    defaultUnitPrice: 3500,
  },
  {
    code: 'WATER_FEE',
    name: 'Tiền nước',
    description: 'Chi phí nước theo số khối đã sử dụng.',
    calculationType: FeeCalculationType.BY_QUANTITY,
    defaultUnitPrice: 18000,
  },
  {
    code: 'INTERNET_FEE',
    name: 'Phí Internet',
    description: 'Phí Internet cố định hàng tháng.',
    calculationType: FeeCalculationType.FIXED,
    defaultUnitPrice: 220000,
  },
  {
    code: 'PARKING_FEE',
    name: 'Phí gửi xe',
    description: 'Phí giữ xe máy hoặc ô tô theo tháng.',
    calculationType: FeeCalculationType.BY_QUANTITY,
    defaultUnitPrice: 150000,
  },
] as const;

const services = [
  {
    name: 'Vệ sinh căn hộ',
    description: 'Dịch vụ vệ sinh cơ bản theo giờ.',
    category: ServiceCategory.CLEANING,
    unitLabel: 'giờ',
    unitPrice: 120000,
    estimatedDurationMinutes: 120,
    providerName: 'Đội dịch vụ Homie',
  },
  {
    name: 'Giặt ủi',
    description: 'Nhận và giao đồ giặt ủi tại căn hộ.',
    category: ServiceCategory.LAUNDRY,
    unitLabel: 'kg',
    unitPrice: 30000,
    estimatedDurationMinutes: 1440,
    providerName: 'Đội dịch vụ Homie',
  },
  {
    name: 'Hỗ trợ kỹ thuật tại căn hộ',
    description: 'Kiểm tra và xử lý sự cố kỹ thuật đơn giản.',
    category: ServiceCategory.TECHNICAL,
    unitLabel: 'lần',
    unitPrice: 150000,
    estimatedDurationMinutes: 60,
    providerName: 'Bộ phận kỹ thuật Homie',
  },
  {
    name: 'Đưa đón sân bay',
    description: 'Dịch vụ đặt xe đưa đón cư dân đến sân bay.',
    category: ServiceCategory.TRANSPORTATION,
    unitLabel: 'chuyến',
    unitPrice: 350000,
    estimatedDurationMinutes: 60,
    providerName: 'Đối tác vận chuyển Homie',
    isActive: false,
  },
  {
    name: 'Giao nước uống',
    description: 'Giao bình nước uống đến tận căn hộ.',
    category: ServiceCategory.CONVENIENCE,
    unitLabel: 'bình',
    unitPrice: 65000,
    estimatedDurationMinutes: 30,
    providerName: 'Cửa hàng tiện lợi Homie',
  },
] as const;

const amenities = [
  {
    name: 'Hồ bơi',
    description: 'Hồ bơi dành cho cư dân.',
    category: AmenityCategory.POOL,
    capacity: 40,
    slotDurationMinutes: 60,
    openingHour: 6,
    closingHour: 21,
    fee: 0,
  },
  {
    name: 'Phòng gym',
    description: 'Phòng tập thể thao dành cho cư dân.',
    category: AmenityCategory.GYM,
    capacity: 25,
    slotDurationMinutes: 60,
    openingHour: 5,
    closingHour: 22,
    fee: 0,
  },
  {
    name: 'Phòng sinh hoạt cộng đồng',
    description: 'Không gian tổ chức họp và sinh hoạt cộng đồng.',
    category: AmenityCategory.COMMUNITY_ROOM,
    capacity: 60,
    slotDurationMinutes: 120,
    openingHour: 7,
    closingHour: 22,
    fee: 200000,
  },
  {
    name: 'Sân cầu lông',
    description: 'Sân thể thao trong nhà dành cho cư dân.',
    category: AmenityCategory.SPORT,
    capacity: 8,
    slotDurationMinutes: 60,
    openingHour: 6,
    closingHour: 22,
    fee: 80000,
  },
  {
    name: 'Khu nướng BBQ',
    description: 'Không gian ngoài trời dành cho tiệc gia đình.',
    category: AmenityCategory.BARBECUE,
    capacity: 20,
    slotDurationMinutes: 180,
    openingHour: 9,
    closingHour: 21,
    fee: 300000,
  },
] as const;

const initialUsers = [
  {
    key: 'management',
    email: 'nam.management@homie.com',
    fullName: 'Trần Hoàng Nam',
    phone: '0901000001',
    role: RoleCode.MANAGEMENT,
  },
  {
    key: 'managementB',
    email: 'quan.management@homie.com',
    fullName: 'Nguyễn Minh Quân',
    phone: '0901000013',
    role: RoleCode.MANAGEMENT,
  },
  {
    key: 'owner',
    email: 'an.owner@homie.com',
    fullName: 'Nguyễn Văn An',
    phone: '0901000002',
    role: RoleCode.RESIDENT,
  },
  {
    key: 'tenant',
    email: 'binh.tenant@homie.com',
    fullName: 'Trần Thị Bình',
    phone: '0901000003',
    role: RoleCode.RESIDENT,
  },
  {
    key: 'newcomer',
    email: 'khoa.resident@homie.com',
    fullName: 'Lê Minh Khoa',
    phone: '0901000004',
    role: RoleCode.RESIDENT,
  },
  {
    key: 'buyer',
    email: 'yen.buyer@homie.com',
    fullName: 'Ngô Hải Yến',
    phone: '0901000009',
    role: RoleCode.RESIDENT,
  },
  {
    key: 'formerOwner',
    email: 'cong.resident@homie.com',
    fullName: 'Bùi Thành Công',
    phone: '0901000010',
    role: RoleCode.RESIDENT,
  },
  {
    key: 'renter',
    email: 'han.renter@homie.com',
    fullName: 'Phan Gia Hân',
    phone: '0901000012',
    role: RoleCode.RESIDENT,
  },
  {
    key: 'accountant',
    email: 'huong.accountant@homie.com',
    fullName: 'Phạm Thu Hương',
    phone: '0901000005',
    role: RoleCode.ACCOUNTANT,
  },
  {
    key: 'receptionist',
    email: 'mai.receptionist@homie.com',
    fullName: 'Đỗ Ngọc Mai',
    phone: '0901000006',
    role: RoleCode.RECEPTIONIST,
  },
  {
    key: 'security',
    email: 'bao.security@homie.com',
    fullName: 'Vũ Quốc Bảo',
    phone: '0901000007',
    role: RoleCode.SECURITY,
  },
  {
    key: 'technician',
    email: 'long.technician@homie.com',
    fullName: 'Hoàng Đức Long',
    phone: '0901000008',
    role: RoleCode.TECHNICIAN,
  },
] as const;

type InitialUserKey = (typeof initialUsers)[number]['key'];
type InitialUserRecord = { id: string; fullName: string; email: string };

async function seedAdmin(adminRoleId: string): Promise<boolean> {
  const email = process.env.SEED_ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.SEED_ADMIN_PASSWORD;

  if (!email || !password) {
    console.log(
      'Bỏ qua tài khoản quản trị: chưa cấu hình SEED_ADMIN_EMAIL và SEED_ADMIN_PASSWORD.',
    );
    return false;
  }

  if (password.length < 8) {
    throw new Error('SEED_ADMIN_PASSWORD phải có ít nhất 8 ký tự.');
  }

  const passwordHash = await hash(password, 12);
  const existingAdmin = await prisma.user.findFirst({
    where: {
      OR: [{ email }, { email: 'admin@homie.vn' }],
    },
  });
  const admin = existingAdmin
    ? await prisma.user.update({
        where: { id: existingAdmin.id },
        data: {
          email,
          fullName: process.env.SEED_ADMIN_FULL_NAME ?? 'Quản trị viên Homie',
          passwordHash,
          status: UserStatus.ACTIVE,
        },
      })
    : await prisma.user.create({
        data: {
          email,
          fullName: process.env.SEED_ADMIN_FULL_NAME ?? 'Quản trị viên Homie',
          passwordHash,
          status: UserStatus.ACTIVE,
        },
      });

  await prisma.userRole.upsert({
    where: { userId: admin.id },
    update: { roleId: adminRoleId },
    create: {
      userId: admin.id,
      roleId: adminRoleId,
    },
  });

  return true;
}

async function seedInitialUsers(
  roleIds: Map<RoleCode, string>,
  password: string,
): Promise<Map<InitialUserKey, InitialUserRecord>> {
  if (password.length < 8) {
    throw new Error('SEED_INITIAL_ACCOUNT_PASSWORD phải có ít nhất 8 ký tự.');
  }

  const passwordHash = await hash(password, 12);
  const result = new Map<InitialUserKey, InitialUserRecord>();
  for (const initialUser of initialUsers) {
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [{ email: initialUser.email }, { phone: initialUser.phone }],
      },
    });
    const user = existingUser
      ? await prisma.user.update({
          where: { id: existingUser.id },
          data: {
            email: initialUser.email,
            fullName: initialUser.fullName,
            phone: initialUser.phone,
            passwordHash,
            status: UserStatus.ACTIVE,
          },
          select: { id: true, fullName: true, email: true },
        })
      : await prisma.user.create({
          data: {
            email: initialUser.email,
            fullName: initialUser.fullName,
            phone: initialUser.phone,
            passwordHash,
            status: UserStatus.ACTIVE,
          },
          select: { id: true, fullName: true, email: true },
        });
    const roleId = roleIds.get(initialUser.role);
    if (!roleId) throw new Error(`Không tìm thấy vai trò ${initialUser.role}.`);
    await prisma.userRole.upsert({
      where: { userId: user.id },
      update: { roleId },
      create: { userId: user.id, roleId },
    });
    result.set(initialUser.key, user);
  }
  return result;
}

async function seedStaffBuildingAssignments(
  users: Map<InitialUserKey, InitialUserRecord>,
  buildingAId: string,
  buildingBId: string,
): Promise<void> {
  const assignments: Array<{ user: InitialUserKey; buildingId: string }> = [
    { user: 'management', buildingId: buildingAId },
    { user: 'managementB', buildingId: buildingBId },
    { user: 'accountant', buildingId: buildingAId },
    { user: 'accountant', buildingId: buildingBId },
    { user: 'receptionist', buildingId: buildingAId },
    { user: 'security', buildingId: buildingAId },
    { user: 'technician', buildingId: buildingAId },
    { user: 'technician', buildingId: buildingBId },
  ];

  for (const assignment of assignments) {
    const staff = requireDemoUser(users, assignment.user);
    await prisma.staffBuildingAssignment.upsert({
      where: {
        userId_buildingId: {
          userId: staff.id,
          buildingId: assignment.buildingId,
        },
      },
      update: { isActive: true, endDate: null },
      create: {
        userId: staff.id,
        buildingId: assignment.buildingId,
      },
    });
  }
}

async function seedInitialMemberships(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const owner = users.get('owner');
  const tenant = users.get('tenant');
  const buyer = users.get('buyer');
  const formerOwner = users.get('formerOwner');
  const renter = users.get('renter');
  const apartmentA0101 = apartmentIds.get('A-0101');
  const apartmentA0102 = apartmentIds.get('A-0102');
  const apartmentA0301 = apartmentIds.get('A-0301');
  const apartmentB0101 = apartmentIds.get('B-0101');
  const apartmentB0102 = apartmentIds.get('B-0102');
  if (
    !owner ||
    !tenant ||
    !buyer ||
    !formerOwner ||
    !renter ||
    !apartmentA0101 ||
    !apartmentA0102 ||
    !apartmentA0301 ||
    !apartmentB0101 ||
    !apartmentB0102
  ) {
    throw new Error('Thiếu người dùng hoặc căn hộ để tạo quan hệ khởi tạo.');
  }

  const memberships = [
    {
      id: '10000000-0000-4000-8000-000000000001',
      apartmentId: apartmentA0101,
      userId: owner.id,
      type: MembershipType.OWNER,
      isPrimary: true,
      status: MembershipStatus.ACTIVE,
      startDate: new Date('2025-01-01T00:00:00.000Z'),
      endDate: null,
    },
    {
      id: '10000000-0000-4000-8000-000000000002',
      apartmentId: apartmentA0102,
      userId: owner.id,
      type: MembershipType.OWNER,
      isPrimary: false,
      status: MembershipStatus.ACTIVE,
      startDate: new Date('2025-03-01T00:00:00.000Z'),
      endDate: null,
    },
    {
      id: '10000000-0000-4000-8000-000000000003',
      apartmentId: apartmentA0102,
      userId: tenant.id,
      type: MembershipType.TENANT,
      isPrimary: true,
      status: MembershipStatus.ACTIVE,
      startDate: new Date('2026-01-01T00:00:00.000Z'),
      endDate: null,
    },
    {
      id: '10000000-0000-4000-8000-000000000005',
      apartmentId: apartmentA0301,
      userId: formerOwner.id,
      type: MembershipType.OWNER,
      isPrimary: true,
      status: MembershipStatus.ENDED,
      startDate: new Date('2023-01-01T00:00:00.000Z'),
      endDate: new Date('2026-05-01T00:00:00.000Z'),
    },
    {
      id: '10000000-0000-4000-8000-000000000006',
      apartmentId: apartmentA0301,
      userId: buyer.id,
      type: MembershipType.OWNER,
      isPrimary: true,
      status: MembershipStatus.ACTIVE,
      startDate: new Date('2026-05-01T00:00:00.000Z'),
      endDate: null,
    },
    {
      id: '10000000-0000-4000-8000-000000000007',
      apartmentId: apartmentB0101,
      userId: formerOwner.id,
      type: MembershipType.OWNER,
      isPrimary: true,
      status: MembershipStatus.ACTIVE,
      startDate: new Date('2024-06-01T00:00:00.000Z'),
      endDate: null,
    },
    {
      id: '10000000-0000-4000-8000-000000000008',
      apartmentId: apartmentB0101,
      userId: renter.id,
      type: MembershipType.TENANT,
      isPrimary: true,
      status: MembershipStatus.ACTIVE,
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2027-05-31T00:00:00.000Z'),
    },
    {
      id: '10000000-0000-4000-8000-000000000009',
      apartmentId: apartmentB0102,
      userId: tenant.id,
      type: MembershipType.TENANT,
      isPrimary: true,
      status: MembershipStatus.ENDED,
      startDate: new Date('2024-01-01T00:00:00.000Z'),
      endDate: new Date('2024-12-31T00:00:00.000Z'),
    },
  ] as const;

  for (const membership of memberships) {
    await prisma.apartmentMembership.upsert({
      where: { id: membership.id },
      update: {
        apartmentId: membership.apartmentId,
        userId: membership.userId,
        type: membership.type,
        status: membership.status,
        isPrimary: membership.isPrimary,
        startDate: membership.startDate,
        endDate: membership.endDate,
      },
      create: {
        ...membership,
      },
    });
  }

  await prisma.householdMember.upsert({
    where: { id: '10000000-0000-4000-8000-000000000004' },
    update: {
      apartmentId: apartmentA0101,
      createdById: owner.id,
      fullName: 'Nguyễn Minh Anh',
      phone: '0912345678',
      relationship: 'Em gái',
      startDate: new Date('2025-01-01T00:00:00.000Z'),
      endDate: null,
      status: 'ACTIVE',
    },
    create: {
      id: '10000000-0000-4000-8000-000000000004',
      apartmentId: apartmentA0101,
      createdById: owner.id,
      fullName: 'Nguyễn Minh Anh',
      phone: '0912345678',
      relationship: 'Em gái',
      startDate: new Date('2025-01-01T00:00:00.000Z'),
      status: 'ACTIVE',
    },
  });

  await prisma.apartment.updateMany({
    where: {
      id: {
        in: [apartmentA0101, apartmentA0102, apartmentA0301, apartmentB0101],
      },
    },
    data: { status: ApartmentStatus.OCCUPIED },
  });
  const apartmentA0202 = apartmentIds.get('A-0202');
  if (apartmentA0202) {
    await prisma.apartment.update({
      where: { id: apartmentA0202 },
      data: { status: ApartmentStatus.UNDER_MAINTENANCE },
    });
  }
}

async function seedInitialTransactions(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const management = users.get('management');
  const owner = users.get('owner');
  const vacantApartmentId = apartmentIds.get('A-0201');
  const ownerApartmentId = apartmentIds.get('A-0101');
  if (!management || !owner || !vacantApartmentId || !ownerApartmentId) {
    throw new Error('Thiếu dữ liệu nền để tạo nghiệp vụ khởi tạo.');
  }

  const now = new Date();
  const ownerApartmentScope = await prisma.apartment.findUniqueOrThrow({
    where: { id: ownerApartmentId },
    select: { buildingId: true },
  });
  await prisma.announcement.upsert({
    where: { id: '20000000-0000-4000-8000-000000000001' },
    update: {
      title: 'Lịch bảo trì hệ thống nước tòa Homie A',
      content:
        'Hệ thống nước sẽ được bảo trì từ 09:00 đến 11:00. Cư dân vui lòng chủ động dự trữ nước.',
      category: AnnouncementCategory.MAINTENANCE,
      priority: AnnouncementPriority.IMPORTANT,
      audience: AnnouncementAudience.RESIDENTS,
      publishedAt: now,
      expiresAt: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
      isPinned: true,
      isPublished: true,
      authorId: management.id,
      buildingId: ownerApartmentScope.buildingId,
    },
    create: {
      id: '20000000-0000-4000-8000-000000000001',
      authorId: management.id,
      buildingId: ownerApartmentScope.buildingId,
      title: 'Lịch bảo trì hệ thống nước tòa Homie A',
      content:
        'Hệ thống nước sẽ được bảo trì từ 09:00 đến 11:00. Cư dân vui lòng chủ động dự trữ nước.',
      category: AnnouncementCategory.MAINTENANCE,
      priority: AnnouncementPriority.IMPORTANT,
      audience: AnnouncementAudience.RESIDENTS,
      publishedAt: now,
      expiresAt: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
      isPinned: true,
      isPublished: true,
    },
  });
  await prisma.announcement.upsert({
    where: { id: '20000000-0000-4000-8000-000000000002' },
    update: {
      title: 'Ngày hội cư dân Homie',
      content:
        'Mời cư dân tham gia ngày hội cộng đồng tại sân trung tâm vào cuối tuần này.',
      category: AnnouncementCategory.EVENT,
      priority: AnnouncementPriority.NORMAL,
      audience: AnnouncementAudience.ALL,
      publishedAt: now,
      expiresAt: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000),
      isPinned: false,
      isPublished: true,
      authorId: management.id,
      buildingId: ownerApartmentScope.buildingId,
    },
    create: {
      id: '20000000-0000-4000-8000-000000000002',
      authorId: management.id,
      buildingId: ownerApartmentScope.buildingId,
      title: 'Ngày hội cư dân Homie',
      content:
        'Mời cư dân tham gia ngày hội cộng đồng tại sân trung tâm vào cuối tuần này.',
      category: AnnouncementCategory.EVENT,
      priority: AnnouncementPriority.NORMAL,
      audience: AnnouncementAudience.ALL,
      publishedAt: now,
      expiresAt: new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000),
      isPinned: false,
      isPublished: true,
    },
  });

  await prisma.housingListing.upsert({
    where: { id: '30000000-0000-4000-8000-000000000001' },
    update: {
      apartmentId: vacantApartmentId,
      submittedById: management.id,
      title: 'Căn hộ 2 phòng ngủ đang trống',
      description:
        'Căn hộ thoáng, sạch sẽ và phù hợp với gia đình nhỏ muốn chuyển vào ở ngay.',
      transactionType: HousingTransactionType.RENT,
      price: 12000000,
      deposit: 24000000,
      availableFrom: now,
      ownerSubmitted: false,
      reviewedById: management.id,
      status: HousingListingStatus.AVAILABLE,
      reviewNote: 'Bài đăng căn hộ trống của ban quản lý.',
      reviewedAt: now,
      closedAt: null,
    },
    create: {
      id: '30000000-0000-4000-8000-000000000001',
      apartmentId: vacantApartmentId,
      submittedById: management.id,
      title: 'Căn hộ 2 phòng ngủ đang trống',
      description:
        'Căn hộ thoáng, sạch sẽ và phù hợp với gia đình nhỏ muốn chuyển vào ở ngay.',
      transactionType: HousingTransactionType.RENT,
      price: 12000000,
      deposit: 24000000,
      availableFrom: now,
      ownerSubmitted: false,
      status: HousingListingStatus.AVAILABLE,
    },
  });

  await prisma.maintenanceRequest.upsert({
    where: { id: '40000000-0000-4000-8000-000000000001' },
    update: {
      apartmentId: ownerApartmentId,
      requestedById: owner.id,
      createdById: owner.id,
      title: 'Vòi nước bếp bị rò rỉ',
      description:
        'Vòi nước dưới bồn rửa bị rò liên tục và làm ướt khu vực tủ bếp.',
      location: 'Bếp căn hộ A-0101',
      category: MaintenanceCategory.PLUMBING,
      priority: MaintenancePriority.HIGH,
      status: MaintenanceStatus.SUBMITTED,
      assignedTechnicianId: null,
      assignedTeamName: null,
      assignedById: null,
      assignedAt: null,
      completedAt: null,
    },
    create: {
      id: '40000000-0000-4000-8000-000000000001',
      code: 'YC-2026-INIT01',
      apartmentId: ownerApartmentId,
      requestedById: owner.id,
      createdById: owner.id,
      title: 'Vòi nước bếp bị rò rỉ',
      description:
        'Vòi nước dưới bồn rửa bị rò liên tục và làm ướt khu vực tủ bếp.',
      location: 'Bếp căn hộ A-0101',
      category: MaintenanceCategory.PLUMBING,
      priority: MaintenancePriority.HIGH,
      status: MaintenanceStatus.SUBMITTED,
    },
  });
  await prisma.maintenanceUpdate.upsert({
    where: { id: '50000000-0000-4000-8000-000000000001' },
    update: {
      maintenanceRequestId: '40000000-0000-4000-8000-000000000001',
      actorId: owner.id,
      status: MaintenanceStatus.SUBMITTED,
      note: 'Yêu cầu khởi tạo đã được gửi đến ban quản lý.',
    },
    create: {
      id: '50000000-0000-4000-8000-000000000001',
      maintenanceRequestId: '40000000-0000-4000-8000-000000000001',
      actorId: owner.id,
      status: MaintenanceStatus.SUBMITTED,
      note: 'Yêu cầu khởi tạo đã được gửi đến ban quản lý.',
    },
  });

  const cleaningService = await prisma.service.findFirst({
    where: { name: 'Vệ sinh căn hộ' },
    select: { id: true, unitPrice: true },
  });
  if (!cleaningService) {
    throw new Error('Thiếu dịch vụ vệ sinh để tạo đăng ký khởi tạo.');
  }
  await prisma.serviceRequest.upsert({
    where: { id: '60000000-0000-4000-8000-000000000001' },
    update: {
      serviceId: cleaningService.id,
      apartmentId: ownerApartmentId,
      requestedById: owner.id,
      createdById: owner.id,
      quantity: 1,
      unitPrice: cleaningService.unitPrice,
      scheduledAt: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
      note: 'Ưu tiên vệ sinh khu vực bếp và ban công.',
      status: ServiceRequestStatus.PENDING,
    },
    create: {
      id: '60000000-0000-4000-8000-000000000001',
      code: 'DV-2026-INIT01',
      serviceId: cleaningService.id,
      apartmentId: ownerApartmentId,
      requestedById: owner.id,
      createdById: owner.id,
      quantity: 1,
      unitPrice: cleaningService.unitPrice,
      scheduledAt: new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000),
      note: 'Ưu tiên vệ sinh khu vực bếp và ban công.',
      status: ServiceRequestStatus.PENDING,
    },
  });

  await prisma.invoice.upsert({
    where: { id: '70000000-0000-4000-8000-000000000001' },
    update: {
      apartmentId: ownerApartmentId,
      payerId: owner.id,
      billingMonth: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
      ),
      issuedAt: now,
      dueDate: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
      status: InvoiceStatus.UNPAID,
      totalAmount: 1551000,
      createdById: management.id,
    },
    create: {
      id: '70000000-0000-4000-8000-000000000001',
      code: 'HD-202610-INIT01',
      apartmentId: ownerApartmentId,
      payerId: owner.id,
      billingMonth: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
      ),
      issuedAt: now,
      dueDate: new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000),
      status: InvoiceStatus.UNPAID,
      totalAmount: 1551000,
      createdById: management.id,
    },
  });
  await prisma.invoiceItem.upsert({
    where: { id: '71000000-0000-4000-8000-000000000001' },
    update: {
      name: 'Phí quản lý',
      quantity: 1,
      unitPrice: 900000,
      amount: 900000,
    },
    create: {
      id: '71000000-0000-4000-8000-000000000001',
      invoiceId: '70000000-0000-4000-8000-000000000001',
      name: 'Phí quản lý',
      quantity: 1,
      unitPrice: 900000,
      amount: 900000,
    },
  });
  await prisma.invoiceItem.upsert({
    where: { id: '71000000-0000-4000-8000-000000000002' },
    update: {
      name: 'Tiền điện',
      quantity: 186,
      unitPrice: 3500,
      amount: 651000,
    },
    create: {
      id: '71000000-0000-4000-8000-000000000002',
      invoiceId: '70000000-0000-4000-8000-000000000001',
      name: 'Tiền điện',
      quantity: 186,
      unitPrice: 3500,
      amount: 651000,
    },
  });

  const poolAmenity = await prisma.amenity.findFirst({
    where: { name: 'Hồ bơi' },
    select: { id: true },
  });
  if (!poolAmenity) {
    throw new Error('Thiếu tiện ích hồ bơi để tạo lượt đặt khởi tạo.');
  }
  const bookingStart = new Date(
    Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 2, 3),
  );
  await prisma.amenityBooking.upsert({
    where: { id: '80000000-0000-4000-8000-000000000001' },
    update: {
      amenityId: poolAmenity.id,
      apartmentId: ownerApartmentId,
      residentId: owner.id,
      startAt: bookingStart,
      endAt: new Date(bookingStart.getTime() + 60 * 60 * 1000),
      attendeeCount: 2,
      note: 'Lượt đặt hồ bơi khởi tạo cho hai người.',
      status: AmenityBookingStatus.PENDING,
    },
    create: {
      id: '80000000-0000-4000-8000-000000000001',
      code: 'TI-2026-INIT01',
      amenityId: poolAmenity.id,
      apartmentId: ownerApartmentId,
      residentId: owner.id,
      startAt: bookingStart,
      endAt: new Date(bookingStart.getTime() + 60 * 60 * 1000),
      attendeeCount: 2,
      note: 'Lượt đặt hồ bơi khởi tạo cho hai người.',
      status: AmenityBookingStatus.PENDING,
    },
  });

  await prisma.temporaryStay.upsert({
    where: { id: '90000000-0000-4000-8000-000000000001' },
    update: {
      apartmentId: ownerApartmentId,
      declaredById: owner.id,
      guestFullName: 'Nguyễn Minh Khách',
      guestPhone: '0909000111',
      relationshipToResident: 'Anh trai',
      startDate: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1),
      ),
      endDate: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 7),
      ),
      purpose: 'Thăm gia đình trong một tuần.',
      status: TemporaryStayStatus.PENDING,
    },
    create: {
      id: '90000000-0000-4000-8000-000000000001',
      apartmentId: ownerApartmentId,
      declaredById: owner.id,
      guestFullName: 'Nguyễn Minh Khách',
      guestPhone: '0909000111',
      relationshipToResident: 'Anh trai',
      startDate: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1),
      ),
      endDate: new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 7),
      ),
      purpose: 'Thăm gia đình trong một tuần.',
      status: TemporaryStayStatus.PENDING,
    },
  });

  const ownerApartment = await prisma.apartment.findUnique({
    where: { id: ownerApartmentId },
    select: { buildingId: true },
  });
  if (!ownerApartment)
    throw new Error('Thiếu căn hộ để tạo sự cố an ninh khởi tạo.');
  await prisma.securityIncident.upsert({
    where: { id: 'a0000000-0000-4000-8000-000000000001' },
    update: {
      buildingId: ownerApartment.buildingId,
      apartmentId: ownerApartmentId,
      reportedById: owner.id,
      type: SecurityIncidentType.NOISE,
      title: 'Tiếng ồn lớn ngoài hành lang',
      description:
        'Có tiếng nhạc lớn kéo dài tại hành lang tầng 1, ảnh hưởng đến các căn hộ xung quanh.',
      location: 'Hành lang gần căn A-0101',
      occurredAt: now,
      status: SecurityIncidentStatus.REPORTED,
    },
    create: {
      id: 'a0000000-0000-4000-8000-000000000001',
      code: 'AN-2026-INIT01',
      buildingId: ownerApartment.buildingId,
      apartmentId: ownerApartmentId,
      reportedById: owner.id,
      type: SecurityIncidentType.NOISE,
      title: 'Tiếng ồn lớn ngoài hành lang',
      description:
        'Có tiếng nhạc lớn kéo dài tại hành lang tầng 1, ảnh hưởng đến các căn hộ xung quanh.',
      location: 'Hành lang gần căn A-0101',
      occurredAt: now,
      status: SecurityIncidentStatus.REPORTED,
    },
  });

  await prisma.notification.upsert({
    where: { id: 'b0000000-0000-4000-8000-000000000001' },
    update: {
      userId: owner.id,
      title: 'Hóa đơn tháng này đã được phát hành',
      message: 'Hóa đơn căn A-0101 đang chờ thanh toán trước ngày đến hạn.',
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
      readAt: null,
    },
    create: {
      id: 'b0000000-0000-4000-8000-000000000001',
      userId: owner.id,
      title: 'Hóa đơn tháng này đã được phát hành',
      message: 'Hóa đơn căn A-0101 đang chờ thanh toán trước ngày đến hạn.',
      type: NotificationType.INVOICE,
      referenceType: 'invoice',
    },
  });
  await prisma.notification.upsert({
    where: { id: 'b0000000-0000-4000-8000-000000000002' },
    update: {
      userId: owner.id,
      title: 'Yêu cầu dịch vụ đang chờ xác nhận',
      message: 'Yêu cầu vệ sinh căn hộ của bạn đã được hệ thống tiếp nhận.',
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      readAt: null,
    },
    create: {
      id: 'b0000000-0000-4000-8000-000000000002',
      userId: owner.id,
      title: 'Yêu cầu dịch vụ đang chờ xác nhận',
      message: 'Yêu cầu vệ sinh căn hộ của bạn đã được hệ thống tiếp nhận.',
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
    },
  });
  await prisma.notification.upsert({
    where: { id: 'b0000000-0000-4000-8000-000000000003' },
    update: {
      userId: management.id,
      title: 'Có sự cố an ninh mới',
      message: 'Cư dân vừa báo sự cố tiếng ồn tại hành lang căn A-0101.',
      type: NotificationType.SYSTEM,
      referenceType: 'security_incident',
      readAt: null,
    },
    create: {
      id: 'b0000000-0000-4000-8000-000000000003',
      userId: management.id,
      title: 'Có sự cố an ninh mới',
      message: 'Cư dân vừa báo sự cố tiếng ồn tại hành lang căn A-0101.',
      type: NotificationType.SYSTEM,
      referenceType: 'security_incident',
    },
  });
}

function requireDemoUser(
  users: Map<InitialUserKey, InitialUserRecord>,
  key: InitialUserKey,
): InitialUserRecord {
  const user = users.get(key);
  if (!user) throw new Error(`Thiếu tài khoản khởi tạo ${key}.`);
  return user;
}

function requireApartment(
  apartmentIds: Map<string, string>,
  code: string,
): string {
  const id = apartmentIds.get(code);
  if (!id) throw new Error(`Thiếu căn hộ khởi tạo ${code}.`);
  return id;
}

async function seedHousingReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const management = requireDemoUser(users, 'management');
  const owner = requireDemoUser(users, 'owner');
  const tenant = requireDemoUser(users, 'tenant');
  const newcomer = requireDemoUser(users, 'newcomer');
  const buyer = requireDemoUser(users, 'buyer');
  const formerOwner = requireDemoUser(users, 'formerOwner');
  const renter = requireDemoUser(users, 'renter');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;

  const listings = [
    {
      id: '30000000-0000-4000-8000-000000000002',
      apartmentId: requireApartment(apartmentIds, 'A-0101'),
      submittedById: owner.id,
      reviewedById: null,
      title: 'Chủ hộ đề nghị cho thuê căn A-0101',
      description:
        'Căn hộ đầy đủ nội thất, chủ hộ gửi bài chờ ban quản lý duyệt.',
      transactionType: HousingTransactionType.RENT,
      price: 13500000,
      deposit: 27000000,
      availableFrom: new Date(now.getTime() + 30 * day),
      ownerSubmitted: true,
      status: HousingListingStatus.PENDING_APPROVAL,
      reviewNote: null,
      reviewedAt: null,
      closedAt: null,
    },
    {
      id: '30000000-0000-4000-8000-000000000003',
      apartmentId: requireApartment(apartmentIds, 'A-0101'),
      submittedById: owner.id,
      reviewedById: management.id,
      title: 'Bài đăng bán căn A-0101 chưa đạt yêu cầu',
      description:
        'Bài đăng minh họa trường hợp bị từ chối do thiếu hồ sơ sở hữu.',
      transactionType: HousingTransactionType.PURCHASE,
      price: 2800000000,
      deposit: 0,
      availableFrom: new Date(now.getTime() + 45 * day),
      ownerSubmitted: true,
      status: HousingListingStatus.REJECTED,
      reviewNote: 'Vui lòng bổ sung giấy tờ chứng minh quyền sở hữu.',
      reviewedAt: new Date(now.getTime() - 8 * day),
      closedAt: null,
    },
    {
      id: '30000000-0000-4000-8000-000000000004',
      apartmentId: requireApartment(apartmentIds, 'A-0301'),
      submittedById: formerOwner.id,
      reviewedById: management.id,
      title: 'Căn A-0301 đã hoàn tất chuyển nhượng',
      description:
        'Bài đăng mua bán đã hoàn tất và được lưu để đối chiếu lịch sử.',
      transactionType: HousingTransactionType.PURCHASE,
      price: 3150000000,
      deposit: 200000000,
      availableFrom: new Date(now.getTime() - 210 * day),
      ownerSubmitted: true,
      status: HousingListingStatus.CLOSED,
      reviewNote: 'Hồ sơ hợp lệ.',
      reviewedAt: new Date(now.getTime() - 205 * day),
      closedAt: new Date(now.getTime() - 175 * day),
    },
    {
      id: '30000000-0000-4000-8000-000000000005',
      apartmentId: requireApartment(apartmentIds, 'B-0101'),
      submittedById: formerOwner.id,
      reviewedById: management.id,
      title: 'Căn B-0101 đã cho thuê',
      description: 'Hợp đồng thuê một năm đã được ban quản lý ghi nhận.',
      transactionType: HousingTransactionType.RENT,
      price: 14500000,
      deposit: 29000000,
      availableFrom: new Date(now.getTime() - 160 * day),
      ownerSubmitted: true,
      status: HousingListingStatus.CLOSED,
      reviewNote: 'Hồ sơ cho thuê hợp lệ.',
      reviewedAt: new Date(now.getTime() - 155 * day),
      closedAt: new Date(now.getTime() - 145 * day),
    },
    {
      id: '30000000-0000-4000-8000-000000000006',
      apartmentId: requireApartment(apartmentIds, 'A-0401'),
      submittedById: management.id,
      reviewedById: management.id,
      title: 'Căn hộ một phòng ngủ đang mở bán',
      description: 'Căn hộ nhỏ gọn, phù hợp người độc thân hoặc gia đình trẻ.',
      transactionType: HousingTransactionType.PURCHASE,
      price: 1950000000,
      deposit: 100000000,
      availableFrom: now,
      ownerSubmitted: false,
      status: HousingListingStatus.AVAILABLE,
      reviewNote: 'Bài đăng của ban quản lý.',
      reviewedAt: now,
      closedAt: null,
    },
    {
      id: '30000000-0000-4000-8000-000000000007',
      apartmentId: requireApartment(apartmentIds, 'B-0201'),
      submittedById: management.id,
      reviewedById: management.id,
      title: 'Căn B-0201 đang cho thuê',
      description: 'Căn hai phòng ngủ, có thể nhận nhà từ đầu tháng tới.',
      transactionType: HousingTransactionType.RENT,
      price: 11000000,
      deposit: 22000000,
      availableFrom: new Date(now.getTime() + 10 * day),
      ownerSubmitted: false,
      status: HousingListingStatus.AVAILABLE,
      reviewNote: 'Bài đăng của ban quản lý.',
      reviewedAt: now,
      closedAt: null,
    },
    {
      id: '30000000-0000-4000-8000-000000000008',
      apartmentId: requireApartment(apartmentIds, 'A-0302'),
      submittedById: formerOwner.id,
      reviewedById: management.id,
      title: 'Căn A-0302 đã ký hợp đồng chờ bàn giao',
      description: 'Bài đăng đã chốt khách và đang chờ ngày hiệu lực hợp đồng.',
      transactionType: HousingTransactionType.PURCHASE,
      price: 3500000000,
      deposit: 250000000,
      availableFrom: new Date(now.getTime() + 15 * day),
      ownerSubmitted: true,
      status: HousingListingStatus.CLOSED,
      reviewNote: 'Hồ sơ hợp lệ.',
      reviewedAt: new Date(now.getTime() - 10 * day),
      closedAt: new Date(now.getTime() - 2 * day),
    },
    {
      id: '30000000-0000-4000-8000-000000000009',
      apartmentId: requireApartment(apartmentIds, 'B-0102'),
      submittedById: formerOwner.id,
      reviewedById: management.id,
      title: 'Hợp đồng thuê cũ của căn B-0102',
      description: 'Dữ liệu lịch sử của hợp đồng thuê đã kết thúc.',
      transactionType: HousingTransactionType.RENT,
      price: 12500000,
      deposit: 25000000,
      availableFrom: new Date(now.getTime() - 700 * day),
      ownerSubmitted: true,
      status: HousingListingStatus.CLOSED,
      reviewNote: 'Bài đăng lịch sử.',
      reviewedAt: new Date(now.getTime() - 710 * day),
      closedAt: new Date(now.getTime() - 700 * day),
    },
    {
      id: '30000000-0000-4000-8000-000000000010',
      apartmentId: requireApartment(apartmentIds, 'A-0402'),
      submittedById: formerOwner.id,
      reviewedById: management.id,
      title: 'Giao dịch căn A-0402 đã hủy',
      description:
        'Bài đăng lưu lịch sử một hợp đồng bị hủy trước ngày hiệu lực.',
      transactionType: HousingTransactionType.PURCHASE,
      price: 4200000000,
      deposit: 300000000,
      availableFrom: new Date(now.getTime() - 60 * day),
      ownerSubmitted: true,
      status: HousingListingStatus.CLOSED,
      reviewNote: 'Hai bên đã thống nhất hủy giao dịch.',
      reviewedAt: new Date(now.getTime() - 70 * day),
      closedAt: new Date(now.getTime() - 55 * day),
    },
  ] as const;

  for (const listing of listings) {
    await prisma.housingListing.upsert({
      where: { id: listing.id },
      update: listing,
      create: listing,
    });
  }

  const applications = [
    {
      id: '31000000-0000-4000-8000-000000000001',
      code: 'HS-THUE-CHO-DUYET',
      listingId: '30000000-0000-4000-8000-000000000001',
      applicantId: newcomer.id,
      preferredStartDate: new Date(now.getTime() + 20 * day),
      preferredEndDate: new Date(now.getTime() + 385 * day),
      note: 'Muốn xem căn hộ vào cuối tuần.',
      status: HousingApplicationStatus.PENDING,
      reviewedById: null,
      reviewedAt: null,
      reviewNote: null,
    },
    {
      id: '31000000-0000-4000-8000-000000000002',
      code: 'HS-THUE-TU-CHOI',
      listingId: '30000000-0000-4000-8000-000000000001',
      applicantId: tenant.id,
      preferredStartDate: new Date(now.getTime() + 25 * day),
      preferredEndDate: new Date(now.getTime() + 390 * day),
      note: 'Đăng ký thuê thêm căn hộ.',
      status: HousingApplicationStatus.REJECTED,
      reviewedById: management.id,
      reviewedAt: new Date(now.getTime() - day),
      reviewNote: 'Người đăng ký đang có hợp đồng thuê còn hiệu lực.',
    },
    {
      id: '31000000-0000-4000-8000-000000000003',
      code: 'HS-THUE-DA-HUY',
      listingId: '30000000-0000-4000-8000-000000000001',
      applicantId: buyer.id,
      preferredStartDate: new Date(now.getTime() + 35 * day),
      preferredEndDate: new Date(now.getTime() + 400 * day),
      note: 'Người dùng đã chủ động hủy nhu cầu.',
      status: HousingApplicationStatus.CANCELLED,
      reviewedById: null,
      reviewedAt: null,
      reviewNote: 'Đã hủy bởi người đăng ký.',
    },
    {
      id: '31000000-0000-4000-8000-000000000004',
      code: 'HS-MUA-HOAN-TAT',
      listingId: '30000000-0000-4000-8000-000000000004',
      applicantId: buyer.id,
      preferredStartDate: new Date(now.getTime() - 175 * day),
      preferredEndDate: null,
      note: 'Hồ sơ mua căn hộ đã hoàn tất.',
      status: HousingApplicationStatus.COMPLETED,
      reviewedById: management.id,
      reviewedAt: new Date(now.getTime() - 180 * day),
      reviewNote: 'Đã đối chiếu giao dịch bên ngoài hệ thống.',
    },
    {
      id: '31000000-0000-4000-8000-000000000005',
      code: 'HS-THUE-HOAN-TAT',
      listingId: '30000000-0000-4000-8000-000000000005',
      applicantId: renter.id,
      preferredStartDate: new Date(now.getTime() - 145 * day),
      preferredEndDate: new Date(now.getTime() + 220 * day),
      note: 'Hồ sơ thuê căn hộ đã hoàn tất.',
      status: HousingApplicationStatus.COMPLETED,
      reviewedById: management.id,
      reviewedAt: new Date(now.getTime() - 148 * day),
      reviewNote: 'Đã xác nhận hợp đồng thuê.',
    },
    {
      id: '31000000-0000-4000-8000-000000000006',
      code: 'HS-MUA-CHO-DUYET',
      listingId: '30000000-0000-4000-8000-000000000006',
      applicantId: newcomer.id,
      preferredStartDate: new Date(now.getTime() + 60 * day),
      preferredEndDate: null,
      note: 'Cần tư vấn lịch xem căn hộ.',
      status: HousingApplicationStatus.PENDING,
      reviewedById: null,
      reviewedAt: null,
      reviewNote: null,
    },
    {
      id: '31000000-0000-4000-8000-000000000007',
      code: 'HS-MUA-DA-KY',
      listingId: '30000000-0000-4000-8000-000000000008',
      applicantId: newcomer.id,
      preferredStartDate: new Date(now.getTime() + 15 * day),
      preferredEndDate: null,
      note: 'Đã ký hợp đồng, chờ bàn giao căn hộ.',
      status: HousingApplicationStatus.COMPLETED,
      reviewedById: management.id,
      reviewedAt: new Date(now.getTime() - 3 * day),
      reviewNote: 'Đã ghi nhận hợp đồng.',
    },
    {
      id: '31000000-0000-4000-8000-000000000008',
      code: 'HS-THUE-DA-KET-THUC',
      listingId: '30000000-0000-4000-8000-000000000009',
      applicantId: tenant.id,
      preferredStartDate: new Date(now.getTime() - 700 * day),
      preferredEndDate: new Date(now.getTime() - 335 * day),
      note: 'Hồ sơ thuê lịch sử.',
      status: HousingApplicationStatus.COMPLETED,
      reviewedById: management.id,
      reviewedAt: new Date(now.getTime() - 702 * day),
      reviewNote: 'Hợp đồng đã kết thúc đúng hạn.',
    },
    {
      id: '31000000-0000-4000-8000-000000000009',
      code: 'HS-MUA-HD-DA-HUY',
      listingId: '30000000-0000-4000-8000-000000000010',
      applicantId: buyer.id,
      preferredStartDate: new Date(now.getTime() - 55 * day),
      preferredEndDate: null,
      note: 'Hồ sơ từng được duyệt nhưng hợp đồng sau đó bị hủy.',
      status: HousingApplicationStatus.COMPLETED,
      reviewedById: management.id,
      reviewedAt: new Date(now.getTime() - 65 * day),
      reviewNote: 'Lưu lịch sử xử lý giao dịch.',
    },
  ] as const;

  for (const application of applications) {
    await prisma.housingApplication.upsert({
      where: { id: application.id },
      update: application,
      create: application,
    });
  }

  const contracts = [
    {
      id: '32000000-0000-4000-8000-000000000001',
      contractNumber: 'HDMB-HOMIE-A0301',
      applicationId: '31000000-0000-4000-8000-000000000004',
      apartmentId: requireApartment(apartmentIds, 'A-0301'),
      ownerId: formerOwner.id,
      customerId: buyer.id,
      recordedById: management.id,
      transactionType: HousingTransactionType.PURCHASE,
      agreedPrice: 3100000000,
      deposit: 200000000,
      signedAt: new Date(now.getTime() - 180 * day),
      effectiveStartDate: new Date(now.getTime() - 175 * day),
      effectiveEndDate: null,
      status: HousingContractStatus.ACTIVE,
      note: 'Hợp đồng mua bán đã hoàn thành thủ tục bàn giao.',
    },
    {
      id: '32000000-0000-4000-8000-000000000002',
      contractNumber: 'HDTHUE-HOMIE-B0101',
      applicationId: '31000000-0000-4000-8000-000000000005',
      apartmentId: requireApartment(apartmentIds, 'B-0101'),
      ownerId: formerOwner.id,
      customerId: renter.id,
      recordedById: management.id,
      transactionType: HousingTransactionType.RENT,
      agreedPrice: 14000000,
      deposit: 28000000,
      signedAt: new Date(now.getTime() - 150 * day),
      effectiveStartDate: new Date(now.getTime() - 145 * day),
      effectiveEndDate: new Date(now.getTime() + 220 * day),
      status: HousingContractStatus.ACTIVE,
      note: 'Hợp đồng thuê còn hiệu lực.',
    },
    {
      id: '32000000-0000-4000-8000-000000000003',
      contractNumber: 'HDMB-HOMIE-A0302',
      applicationId: '31000000-0000-4000-8000-000000000007',
      apartmentId: requireApartment(apartmentIds, 'A-0302'),
      ownerId: formerOwner.id,
      customerId: newcomer.id,
      recordedById: management.id,
      transactionType: HousingTransactionType.PURCHASE,
      agreedPrice: 3450000000,
      deposit: 250000000,
      signedAt: new Date(now.getTime() - 2 * day),
      effectiveStartDate: new Date(now.getTime() + 15 * day),
      effectiveEndDate: null,
      status: HousingContractStatus.SIGNED,
      note: 'Đã ký, chưa tới ngày bàn giao.',
    },
    {
      id: '32000000-0000-4000-8000-000000000004',
      contractNumber: 'HDTHUE-HOMIE-B0102-CU',
      applicationId: '31000000-0000-4000-8000-000000000008',
      apartmentId: requireApartment(apartmentIds, 'B-0102'),
      ownerId: formerOwner.id,
      customerId: tenant.id,
      recordedById: management.id,
      transactionType: HousingTransactionType.RENT,
      agreedPrice: 12000000,
      deposit: 24000000,
      signedAt: new Date(now.getTime() - 710 * day),
      effectiveStartDate: new Date(now.getTime() - 700 * day),
      effectiveEndDate: new Date(now.getTime() - 335 * day),
      status: HousingContractStatus.ENDED,
      note: 'Hợp đồng thuê đã thanh lý đúng hạn.',
    },
    {
      id: '32000000-0000-4000-8000-000000000005',
      contractNumber: 'HDMB-HOMIE-A0402-HUY',
      applicationId: '31000000-0000-4000-8000-000000000009',
      apartmentId: requireApartment(apartmentIds, 'A-0402'),
      ownerId: formerOwner.id,
      customerId: buyer.id,
      recordedById: management.id,
      transactionType: HousingTransactionType.PURCHASE,
      agreedPrice: 4150000000,
      deposit: 300000000,
      signedAt: new Date(now.getTime() - 60 * day),
      effectiveStartDate: new Date(now.getTime() - 55 * day),
      effectiveEndDate: null,
      status: HousingContractStatus.CANCELLED,
      note: 'Hợp đồng bị hủy trước khi bàn giao.',
    },
  ] as const;

  for (const contract of contracts) {
    await prisma.housingContract.upsert({
      where: { id: contract.id },
      update: contract,
      create: contract,
    });
  }
}

async function seedAnnouncementReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  buildingId: string,
): Promise<void> {
  const management = requireDemoUser(users, 'management');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;
  const announcements = [
    {
      id: '20000000-0000-4000-8000-000000000003',
      authorId: management.id,
      buildingId,
      title: 'Nhắc hạn thanh toán phí dịch vụ',
      content:
        'Cư dân vui lòng thanh toán hóa đơn trước ngày đến hạn hiển thị trên ứng dụng.',
      category: AnnouncementCategory.BILLING,
      priority: AnnouncementPriority.IMPORTANT,
      audience: AnnouncementAudience.RESIDENTS,
      publishedAt: new Date(now.getTime() - 2 * day),
      expiresAt: new Date(now.getTime() + 10 * day),
      isPinned: true,
      isPublished: true,
    },
    {
      id: '20000000-0000-4000-8000-000000000004',
      authorId: management.id,
      buildingId,
      title: 'Diễn tập phòng cháy chữa cháy',
      content:
        'Toàn khu căn hộ tổ chức diễn tập an toàn và sơ tán vào sáng Chủ nhật.',
      category: AnnouncementCategory.EMERGENCY,
      priority: AnnouncementPriority.URGENT,
      audience: AnnouncementAudience.ALL,
      publishedAt: new Date(now.getTime() - day),
      expiresAt: new Date(now.getTime() + 5 * day),
      isPinned: true,
      isPublished: true,
    },
    {
      id: '20000000-0000-4000-8000-000000000005',
      authorId: management.id,
      buildingId,
      title: 'Họp giao ban bộ phận vận hành',
      content: 'Các bộ phận tập trung tại phòng sinh hoạt cộng đồng lúc 14:00.',
      category: AnnouncementCategory.GENERAL,
      priority: AnnouncementPriority.NORMAL,
      audience: AnnouncementAudience.MANAGERS,
      publishedAt: now,
      expiresAt: new Date(now.getTime() + 3 * day),
      isPinned: false,
      isPublished: true,
    },
    {
      id: '20000000-0000-4000-8000-000000000006',
      authorId: management.id,
      buildingId,
      title: 'Dự thảo hướng dẫn sử dụng tiện ích',
      content: 'Nội dung đang được ban quản lý biên tập và chưa công bố.',
      category: AnnouncementCategory.GENERAL,
      priority: AnnouncementPriority.NORMAL,
      audience: AnnouncementAudience.RESIDENTS,
      publishedAt: null,
      expiresAt: null,
      isPinned: false,
      isPublished: false,
    },
    {
      id: '20000000-0000-4000-8000-000000000007',
      authorId: management.id,
      buildingId,
      title: 'Thông báo đã hết hiệu lực',
      content: 'Dữ liệu mẫu minh họa thông báo đã qua thời gian hiển thị.',
      category: AnnouncementCategory.GENERAL,
      priority: AnnouncementPriority.NORMAL,
      audience: AnnouncementAudience.ALL,
      publishedAt: new Date(now.getTime() - 40 * day),
      expiresAt: new Date(now.getTime() - 30 * day),
      isPinned: false,
      isPublished: true,
    },
  ] as const;

  for (const announcement of announcements) {
    await prisma.announcement.upsert({
      where: { id: announcement.id },
      update: announcement,
      create: announcement,
    });
  }
}

async function seedBillingReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const owner = requireDemoUser(users, 'owner');
  const tenant = requireDemoUser(users, 'tenant');
  const buyer = requireDemoUser(users, 'buyer');
  const renter = requireDemoUser(users, 'renter');
  const accountant = requireDemoUser(users, 'accountant');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;
  const billingMonth = (offset: number) =>
    new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + offset, 1));

  const feeTypeRecords = await prisma.feeType.findMany({
    select: { id: true, code: true },
  });
  const feeTypeIds = new Map(
    feeTypeRecords.map((feeType) => [feeType.code, feeType.id]),
  );
  const managementFeeId = feeTypeIds.get('MANAGEMENT_FEE');
  const electricityFeeId = feeTypeIds.get('ELECTRICITY_FEE');
  const waterFeeId = feeTypeIds.get('WATER_FEE');
  const internetFeeId = feeTypeIds.get('INTERNET_FEE');
  const parkingFeeId = feeTypeIds.get('PARKING_FEE');
  if (
    !managementFeeId ||
    !electricityFeeId ||
    !waterFeeId ||
    !internetFeeId ||
    !parkingFeeId
  ) {
    throw new Error('Thiếu loại phí để tạo hóa đơn báo cáo.');
  }

  await prisma.invoiceItem.update({
    where: { id: '71000000-0000-4000-8000-000000000001' },
    data: { feeTypeId: managementFeeId },
  });
  await prisma.invoiceItem.update({
    where: { id: '71000000-0000-4000-8000-000000000002' },
    data: { feeTypeId: electricityFeeId },
  });

  const invoices = [
    {
      id: '72000000-0000-4000-8000-000000000001',
      code: 'HD-INIT-DRAFT',
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      payerId: tenant.id,
      billingMonth: billingMonth(0),
      issuedAt: now,
      dueDate: new Date(now.getTime() + 12 * day),
      status: InvoiceStatus.DRAFT,
      totalAmount: 1384000,
      note: 'Hóa đơn nháp đang được kế toán kiểm tra.',
      paidAt: null,
      createdById: accountant.id,
    },
    {
      id: '72000000-0000-4000-8000-000000000002',
      code: 'HD-INIT-PAID-01',
      apartmentId: requireApartment(apartmentIds, 'A-0101'),
      payerId: owner.id,
      billingMonth: billingMonth(-1),
      issuedAt: new Date(now.getTime() - 40 * day),
      dueDate: new Date(now.getTime() - 20 * day),
      status: InvoiceStatus.PAID,
      totalAmount: 1718000,
      note: 'Đã thanh toán bằng chuyển khoản.',
      paidAt: new Date(now.getTime() - 25 * day),
      createdById: accountant.id,
    },
    {
      id: '72000000-0000-4000-8000-000000000003',
      code: 'HD-INIT-OVERDUE',
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      payerId: tenant.id,
      billingMonth: billingMonth(-1),
      issuedAt: new Date(now.getTime() - 42 * day),
      dueDate: new Date(now.getTime() - 18 * day),
      status: InvoiceStatus.OVERDUE,
      totalAmount: 1495000,
      note: 'Hóa đơn đã quá hạn và chưa được xác nhận thanh toán.',
      paidAt: null,
      createdById: accountant.id,
    },
    {
      id: '72000000-0000-4000-8000-000000000004',
      code: 'HD-INIT-CANCELLED',
      apartmentId: requireApartment(apartmentIds, 'B-0101'),
      payerId: renter.id,
      billingMonth: billingMonth(-2),
      issuedAt: new Date(now.getTime() - 72 * day),
      dueDate: new Date(now.getTime() - 50 * day),
      status: InvoiceStatus.CANCELLED,
      totalAmount: 1050000,
      note: 'Hóa đơn bị hủy do lập nhầm người thanh toán.',
      paidAt: null,
      createdById: accountant.id,
    },
    {
      id: '72000000-0000-4000-8000-000000000005',
      code: 'HD-INIT-PAID-02',
      apartmentId: requireApartment(apartmentIds, 'A-0301'),
      payerId: buyer.id,
      billingMonth: billingMonth(-2),
      issuedAt: new Date(now.getTime() - 75 * day),
      dueDate: new Date(now.getTime() - 52 * day),
      status: InvoiceStatus.PAID,
      totalAmount: 1314000,
      note: 'Đã thu tiền mặt tại quầy lễ tân.',
      paidAt: new Date(now.getTime() - 60 * day),
      createdById: accountant.id,
    },
  ] as const;

  for (const invoice of invoices) {
    await prisma.invoice.upsert({
      where: { id: invoice.id },
      update: invoice,
      create: invoice,
    });
  }

  const items = [
    [
      '73000000-0000-4000-8000-000000000001',
      invoices[0].id,
      managementFeeId,
      'Phí quản lý',
      1,
      984000,
    ],
    [
      '73000000-0000-4000-8000-000000000002',
      invoices[0].id,
      parkingFeeId,
      'Phí gửi xe',
      2,
      200000,
    ],
    [
      '73000000-0000-4000-8000-000000000003',
      invoices[1].id,
      managementFeeId,
      'Phí quản lý',
      1,
      822000,
    ],
    [
      '73000000-0000-4000-8000-000000000004',
      invoices[1].id,
      electricityFeeId,
      'Tiền điện',
      184,
      3500,
    ],
    [
      '73000000-0000-4000-8000-000000000005',
      invoices[1].id,
      waterFeeId,
      'Tiền nước',
      14,
      18000,
    ],
    [
      '73000000-0000-4000-8000-000000000006',
      invoices[2].id,
      managementFeeId,
      'Phí quản lý',
      1,
      984000,
    ],
    [
      '73000000-0000-4000-8000-000000000007',
      invoices[2].id,
      electricityFeeId,
      'Tiền điện',
      146,
      3500,
    ],
    [
      '73000000-0000-4000-8000-000000000008',
      invoices[3].id,
      managementFeeId,
      'Phí quản lý',
      1,
      780000,
    ],
    [
      '73000000-0000-4000-8000-000000000009',
      invoices[3].id,
      internetFeeId,
      'Phí Internet',
      1,
      270000,
    ],
    [
      '73000000-0000-4000-8000-000000000010',
      invoices[4].id,
      managementFeeId,
      'Phí quản lý',
      1,
      864000,
    ],
    [
      '73000000-0000-4000-8000-000000000011',
      invoices[4].id,
      parkingFeeId,
      'Phí gửi xe',
      3,
      150000,
    ],
  ] as const;

  for (const [id, invoiceId, feeTypeId, name, quantity, unitPrice] of items) {
    const amount = Number(quantity) * Number(unitPrice);
    await prisma.invoiceItem.upsert({
      where: { id },
      update: { invoiceId, feeTypeId, name, quantity, unitPrice, amount },
      create: { id, invoiceId, feeTypeId, name, quantity, unitPrice, amount },
    });
  }

  const payments = [
    {
      id: '74000000-0000-4000-8000-000000000001',
      invoiceId: invoices[1].id,
      recordedById: accountant.id,
      confirmedById: accountant.id,
      amount: 1718000,
      method: PaymentMethod.BANK_TRANSFER,
      status: PaymentStatus.CONFIRMED,
      transactionCode: 'CK-INIT-0001',
      proofUrl: null,
      note: 'Kế toán đã đối chiếu giao dịch ngân hàng.',
      paidAt: new Date(now.getTime() - 25 * day),
      confirmedAt: new Date(now.getTime() - 24 * day),
    },
    {
      id: '74000000-0000-4000-8000-000000000002',
      invoiceId: invoices[4].id,
      recordedById: accountant.id,
      confirmedById: accountant.id,
      amount: 1314000,
      method: PaymentMethod.CASH,
      status: PaymentStatus.CONFIRMED,
      transactionCode: 'TM-INIT-0002',
      proofUrl: null,
      note: 'Đã thu đủ tiền mặt.',
      paidAt: new Date(now.getTime() - 60 * day),
      confirmedAt: new Date(now.getTime() - 60 * day),
    },
    {
      id: '74000000-0000-4000-8000-000000000003',
      invoiceId: '70000000-0000-4000-8000-000000000001',
      recordedById: owner.id,
      confirmedById: null,
      amount: 1551000,
      method: PaymentMethod.BANK_TRANSFER,
      status: PaymentStatus.PENDING,
      transactionCode: 'CK-INIT-CHO-XAC-NHAN',
      proofUrl: null,
      note: 'Giao dịch được nhập từ sao kê và đang chờ kế toán đối chiếu.',
      paidAt: now,
      confirmedAt: null,
    },
    {
      id: '74000000-0000-4000-8000-000000000004',
      invoiceId: invoices[2].id,
      recordedById: tenant.id,
      confirmedById: accountant.id,
      amount: 1495000,
      method: PaymentMethod.OTHER,
      status: PaymentStatus.CANCELLED,
      transactionCode: 'GD-INIT-DA-HUY',
      proofUrl: null,
      note: 'Giao dịch không hợp lệ nên đã hủy.',
      paidAt: new Date(now.getTime() - 10 * day),
      confirmedAt: null,
    },
  ] as const;

  for (const payment of payments) {
    await prisma.payment.upsert({
      where: { id: payment.id },
      update: payment,
      create: payment,
    });
  }
}

async function seedMaintenanceReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const management = requireDemoUser(users, 'management');
  const owner = requireDemoUser(users, 'owner');
  const tenant = requireDemoUser(users, 'tenant');
  const buyer = requireDemoUser(users, 'buyer');
  const renter = requireDemoUser(users, 'renter');
  const technician = requireDemoUser(users, 'technician');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;

  const requests = [
    {
      id: '41000000-0000-4000-8000-000000000001',
      code: 'YC-INIT-RECEIVED',
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      requestedById: tenant.id,
      createdById: tenant.id,
      assignedTechnicianId: null,
      assignedTeamName: 'Tổ kỹ thuật điện',
      assignedById: management.id,
      title: 'Ổ cắm phòng khách mất điện',
      description: 'Hai ổ cắm gần cửa ban công không có điện.',
      location: 'Phòng khách căn A-0102',
      category: MaintenanceCategory.ELECTRICAL,
      priority: MaintenancePriority.NORMAL,
      status: MaintenanceStatus.RECEIVED,
      assignedAt: now,
      completedAt: null,
    },
    {
      id: '41000000-0000-4000-8000-000000000002',
      code: 'YC-INIT-IN-PROGRESS',
      apartmentId: requireApartment(apartmentIds, 'B-0101'),
      requestedById: renter.id,
      createdById: renter.id,
      assignedTechnicianId: technician.id,
      assignedTeamName: 'Kỹ thuật tòa B',
      assignedById: management.id,
      title: 'Điều hòa phòng ngủ không lạnh',
      description: 'Máy vẫn chạy nhưng nhiệt độ phòng không giảm.',
      location: 'Phòng ngủ chính căn B-0101',
      category: MaintenanceCategory.OTHER,
      priority: MaintenancePriority.HIGH,
      status: MaintenanceStatus.IN_PROGRESS,
      assignedAt: new Date(now.getTime() - day),
      completedAt: null,
    },
    {
      id: '41000000-0000-4000-8000-000000000003',
      code: 'YC-INIT-WAITING',
      apartmentId: requireApartment(apartmentIds, 'A-0101'),
      requestedById: owner.id,
      createdById: owner.id,
      assignedTechnicianId: technician.id,
      assignedTeamName: 'Kỹ thuật tòa A',
      assignedById: management.id,
      title: 'Xác nhận kết quả thay khóa cửa',
      description: 'Kỹ thuật viên đã thay khóa và chờ cư dân kiểm tra thực tế.',
      location: 'Cửa chính căn A-0101',
      category: MaintenanceCategory.SECURITY,
      priority: MaintenancePriority.NORMAL,
      status: MaintenanceStatus.WAITING_RESIDENT,
      assignedAt: new Date(now.getTime() - 2 * day),
      completedAt: null,
    },
    {
      id: '41000000-0000-4000-8000-000000000004',
      code: 'YC-INIT-COMPLETED',
      apartmentId: requireApartment(apartmentIds, 'A-0301'),
      requestedById: buyer.id,
      createdById: buyer.id,
      assignedTechnicianId: technician.id,
      assignedTeamName: 'Tổ cấp thoát nước',
      assignedById: management.id,
      title: 'Thoát nước ban công bị nghẹt',
      description: 'Nước mưa thoát chậm tại ban công.',
      location: 'Ban công căn A-0301',
      category: MaintenanceCategory.PLUMBING,
      priority: MaintenancePriority.HIGH,
      status: MaintenanceStatus.COMPLETED,
      assignedAt: new Date(now.getTime() - 12 * day),
      completedAt: new Date(now.getTime() - 10 * day),
    },
    {
      id: '41000000-0000-4000-8000-000000000005',
      code: 'YC-INIT-CANCELLED',
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      requestedById: tenant.id,
      createdById: tenant.id,
      assignedTechnicianId: null,
      assignedTeamName: null,
      assignedById: null,
      title: 'Kiểm tra bóng đèn hành lang',
      description: 'Yêu cầu được hủy vì bóng đèn đã hoạt động bình thường.',
      location: 'Hành lang tầng 1 tòa A',
      category: MaintenanceCategory.COMMON_AREA,
      priority: MaintenancePriority.LOW,
      status: MaintenanceStatus.CANCELLED,
      assignedAt: null,
      completedAt: null,
    },
  ] as const;

  for (const request of requests) {
    await prisma.maintenanceRequest.upsert({
      where: { id: request.id },
      update: request,
      create: request,
    });
  }

  const updates = [
    {
      id: '51000000-0000-4000-8000-000000000001',
      maintenanceRequestId: requests[0].id,
      actorId: management.id,
      status: MaintenanceStatus.RECEIVED,
      note: 'Ban quản lý đã tiếp nhận và chuyển cho tổ kỹ thuật điện.',
    },
    {
      id: '51000000-0000-4000-8000-000000000002',
      maintenanceRequestId: requests[1].id,
      actorId: technician.id,
      status: MaintenanceStatus.IN_PROGRESS,
      note: 'Đang kiểm tra dàn nóng và lượng gas của điều hòa.',
    },
    {
      id: '51000000-0000-4000-8000-000000000003',
      maintenanceRequestId: requests[2].id,
      actorId: technician.id,
      status: MaintenanceStatus.WAITING_RESIDENT,
      note: 'Đã thay khóa mới và kiểm tra đóng mở bình thường.',
    },
    {
      id: '51000000-0000-4000-8000-000000000004',
      maintenanceRequestId: requests[3].id,
      actorId: technician.id,
      status: MaintenanceStatus.WAITING_RESIDENT,
      note: 'Đã vệ sinh đường thoát nước và kiểm tra dòng chảy.',
    },
    {
      id: '51000000-0000-4000-8000-000000000005',
      maintenanceRequestId: requests[4].id,
      actorId: tenant.id,
      status: MaintenanceStatus.CANCELLED,
      note: 'Cư dân chủ động hủy yêu cầu.',
    },
    {
      id: '51000000-0000-4000-8000-000000000006',
      maintenanceRequestId: requests[3].id,
      actorId: buyer.id,
      status: MaintenanceStatus.COMPLETED,
      note: 'Cư dân xác nhận sự cố đã được khắc phục.',
    },
  ] as const;

  for (const update of updates) {
    await prisma.maintenanceUpdate.upsert({
      where: { id: update.id },
      update,
      create: update,
    });
  }
}

async function seedServiceReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const management = requireDemoUser(users, 'management');
  const tenant = requireDemoUser(users, 'tenant');
  const buyer = requireDemoUser(users, 'buyer');
  const renter = requireDemoUser(users, 'renter');
  const receptionist = requireDemoUser(users, 'receptionist');
  const technician = requireDemoUser(users, 'technician');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;
  const serviceRecords = await prisma.service.findMany({
    select: { id: true, name: true, unitPrice: true },
  });
  const byName = new Map(
    serviceRecords.map((service) => [service.name, service]),
  );
  const required = (name: string) => {
    const service = byName.get(name);
    if (!service) throw new Error(`Thiếu dịch vụ ${name}.`);
    return service;
  };
  const laundry = required('Giặt ủi');
  const technical = required('Hỗ trợ kỹ thuật tại căn hộ');
  const transport = required('Đưa đón sân bay');
  const water = required('Giao nước uống');

  const requests = [
    {
      id: '61000000-0000-4000-8000-000000000001',
      code: 'DV-INIT-CONFIRMED',
      serviceId: laundry.id,
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      requestedById: tenant.id,
      createdById: receptionist.id,
      assignedToId: receptionist.id,
      assignedToName: receptionist.fullName,
      quantity: 4,
      unitPrice: laundry.unitPrice,
      scheduledAt: new Date(now.getTime() + day),
      note: 'Nhận đồ tại quầy lễ tân.',
      status: ServiceRequestStatus.CONFIRMED,
      managementNote: 'Đã xác nhận khối lượng dự kiến.',
      completedAt: null,
    },
    {
      id: '61000000-0000-4000-8000-000000000002',
      code: 'DV-INIT-IN-PROGRESS',
      serviceId: technical.id,
      apartmentId: requireApartment(apartmentIds, 'B-0101'),
      requestedById: renter.id,
      createdById: renter.id,
      assignedToId: technician.id,
      assignedToName: technician.fullName,
      quantity: 1,
      unitPrice: technical.unitPrice,
      scheduledAt: now,
      note: 'Kiểm tra kết nối chuông cửa.',
      status: ServiceRequestStatus.IN_PROGRESS,
      managementNote: 'Kỹ thuật viên đã đến căn hộ.',
      completedAt: null,
    },
    {
      id: '61000000-0000-4000-8000-000000000003',
      code: 'DV-INIT-COMPLETED',
      serviceId: transport.id,
      apartmentId: requireApartment(apartmentIds, 'A-0301'),
      requestedById: buyer.id,
      createdById: buyer.id,
      assignedToId: receptionist.id,
      assignedToName: 'Đối tác vận chuyển Homie',
      quantity: 1,
      unitPrice: transport.unitPrice,
      scheduledAt: new Date(now.getTime() - 7 * day),
      note: 'Đón tại sảnh A lúc 05:30.',
      status: ServiceRequestStatus.COMPLETED,
      managementNote: 'Chuyến đi đã hoàn thành.',
      completedAt: new Date(now.getTime() - 7 * day),
    },
    {
      id: '61000000-0000-4000-8000-000000000004',
      code: 'DV-INIT-CANCELLED',
      serviceId: water.id,
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      requestedById: tenant.id,
      createdById: tenant.id,
      assignedToId: null,
      assignedToName: null,
      quantity: 2,
      unitPrice: water.unitPrice,
      scheduledAt: new Date(now.getTime() + 3 * day),
      note: 'Yêu cầu đã được cư dân hủy.',
      status: ServiceRequestStatus.CANCELLED,
      managementNote: 'Không phát sinh chi phí.',
      completedAt: null,
    },
  ] as const;

  for (const request of requests) {
    await prisma.serviceRequest.upsert({
      where: { id: request.id },
      update: request,
      create: request,
    });
  }

  await prisma.notification.upsert({
    where: { id: 'b1000000-0000-4000-8000-000000000001' },
    update: {
      userId: management.id,
      title: 'Dịch vụ đang được thực hiện',
      message: 'Yêu cầu hỗ trợ kỹ thuật tại B-0101 đang được xử lý.',
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      referenceId: requests[1].id,
      readAt: null,
    },
    create: {
      id: 'b1000000-0000-4000-8000-000000000001',
      userId: management.id,
      title: 'Dịch vụ đang được thực hiện',
      message: 'Yêu cầu hỗ trợ kỹ thuật tại B-0101 đang được xử lý.',
      type: NotificationType.SERVICE,
      referenceType: 'service_request',
      referenceId: requests[1].id,
    },
  });
}

async function seedAmenityReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const management = requireDemoUser(users, 'management');
  const owner = requireDemoUser(users, 'owner');
  const tenant = requireDemoUser(users, 'tenant');
  const buyer = requireDemoUser(users, 'buyer');
  const renter = requireDemoUser(users, 'renter');
  const receptionist = requireDemoUser(users, 'receptionist');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;
  const amenityRecords = await prisma.amenity.findMany({
    select: { id: true, name: true, slotDurationMinutes: true },
  });
  const byName = new Map(
    amenityRecords.map((amenity) => [amenity.name, amenity]),
  );
  const required = (name: string) => {
    const amenity = byName.get(name);
    if (!amenity) throw new Error(`Thiếu tiện ích ${name}.`);
    return amenity;
  };
  const gym = required('Phòng gym');
  const communityRoom = required('Phòng sinh hoạt cộng đồng');
  const badminton = required('Sân cầu lông');
  const barbecue = required('Khu nướng BBQ');
  const atHour = (offsetDays: number, hour: number) => {
    const date = new Date(now.getTime() + offsetDays * day);
    return new Date(
      Date.UTC(
        date.getUTCFullYear(),
        date.getUTCMonth(),
        date.getUTCDate(),
        hour,
      ),
    );
  };

  const bookings = [
    {
      id: '81000000-0000-4000-8000-000000000001',
      code: 'TI-INIT-APPROVED',
      amenityId: gym.id,
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      residentId: tenant.id,
      reviewedById: receptionist.id,
      startAt: atHour(1, 11),
      endAt: atHour(1, 12),
      attendeeCount: 1,
      note: 'Lịch tập cá nhân đã được duyệt.',
      status: AmenityBookingStatus.APPROVED,
      managementNote: 'Đã kiểm tra khung giờ còn trống.',
      reviewedAt: now,
    },
    {
      id: '81000000-0000-4000-8000-000000000002',
      code: 'TI-INIT-REJECTED',
      amenityId: communityRoom.id,
      apartmentId: requireApartment(apartmentIds, 'A-0301'),
      residentId: buyer.id,
      reviewedById: management.id,
      startAt: atHour(2, 8),
      endAt: atHour(2, 10),
      attendeeCount: 80,
      note: 'Đăng ký tổ chức sinh hoạt gia đình.',
      status: AmenityBookingStatus.REJECTED,
      managementNote: 'Số người vượt quá sức chứa của phòng.',
      reviewedAt: now,
    },
    {
      id: '81000000-0000-4000-8000-000000000003',
      code: 'TI-INIT-CANCELLED',
      amenityId: badminton.id,
      apartmentId: requireApartment(apartmentIds, 'B-0101'),
      residentId: renter.id,
      reviewedById: null,
      startAt: atHour(3, 12),
      endAt: atHour(3, 13),
      attendeeCount: 4,
      note: 'Cư dân đã hủy lịch do thay đổi kế hoạch.',
      status: AmenityBookingStatus.CANCELLED,
      managementNote: null,
      reviewedAt: null,
    },
    {
      id: '81000000-0000-4000-8000-000000000004',
      code: 'TI-INIT-BLOCKED',
      amenityId: barbecue.id,
      apartmentId: null,
      residentId: management.id,
      reviewedById: management.id,
      startAt: atHour(4, 10),
      endAt: atHour(4, 13),
      attendeeCount: 1,
      note: 'Khóa lịch để bảo trì khu nướng.',
      status: AmenityBookingStatus.BLOCKED,
      managementNote: 'Không tiếp nhận đặt chỗ trong thời gian bảo trì.',
      reviewedAt: now,
    },
  ] as const;

  for (const booking of bookings) {
    await prisma.amenityBooking.upsert({
      where: { id: booking.id },
      update: booking,
      create: booking,
    });
  }

  await prisma.notification.upsert({
    where: { id: 'b2000000-0000-4000-8000-000000000001' },
    update: {
      userId: tenant.id,
      title: 'Lịch đặt phòng gym đã được duyệt',
      message: 'Bạn có thể sử dụng phòng gym đúng khung giờ đã đăng ký.',
      type: NotificationType.AMENITY,
      referenceType: 'amenity_booking',
      referenceId: bookings[0].id,
      readAt: null,
    },
    create: {
      id: 'b2000000-0000-4000-8000-000000000001',
      userId: tenant.id,
      title: 'Lịch đặt phòng gym đã được duyệt',
      message: 'Bạn có thể sử dụng phòng gym đúng khung giờ đã đăng ký.',
      type: NotificationType.AMENITY,
      referenceType: 'amenity_booking',
      referenceId: bookings[0].id,
    },
  });
}

async function seedTemporaryStayReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const owner = requireDemoUser(users, 'owner');
  const tenant = requireDemoUser(users, 'tenant');
  const buyer = requireDemoUser(users, 'buyer');
  const renter = requireDemoUser(users, 'renter');
  const receptionist = requireDemoUser(users, 'receptionist');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;
  const stays = [
    {
      id: '91000000-0000-4000-8000-000000000001',
      apartmentId: requireApartment(apartmentIds, 'A-0102'),
      declaredById: tenant.id,
      reviewedById: receptionist.id,
      guestFullName: 'Trần Minh Anh',
      guestDateOfBirth: new Date('1998-04-12T00:00:00.000Z'),
      guestPhone: '0908111222',
      relationshipToResident: 'Em gái',
      startDate: new Date(now.getTime() + day),
      endDate: new Date(now.getTime() + 5 * day),
      purpose: 'Thăm người thân.',
      status: TemporaryStayStatus.APPROVED,
      reviewNote: 'Thông tin liên hệ hợp lệ.',
      reviewedAt: now,
    },
    {
      id: '91000000-0000-4000-8000-000000000002',
      apartmentId: requireApartment(apartmentIds, 'A-0301'),
      declaredById: buyer.id,
      reviewedById: receptionist.id,
      guestFullName: 'Lê Hoàng Phúc',
      guestDateOfBirth: new Date('2000-09-20T00:00:00.000Z'),
      guestPhone: null,
      relationshipToResident: 'Bạn',
      startDate: new Date(now.getTime() + 2 * day),
      endDate: new Date(now.getTime() + 20 * day),
      purpose: 'Ở nhờ trong thời gian dài.',
      status: TemporaryStayStatus.REJECTED,
      reviewNote:
        'Thiếu số điện thoại liên hệ và thời gian lưu trú chưa rõ ràng.',
      reviewedAt: now,
    },
    {
      id: '91000000-0000-4000-8000-000000000003',
      apartmentId: requireApartment(apartmentIds, 'B-0101'),
      declaredById: renter.id,
      reviewedById: null,
      guestFullName: 'Phan Văn Hải',
      guestDateOfBirth: null,
      guestPhone: '0908333444',
      relationshipToResident: 'Anh họ',
      startDate: new Date(now.getTime() + 3 * day),
      endDate: new Date(now.getTime() + 4 * day),
      purpose: 'Ghé thăm cuối tuần.',
      status: TemporaryStayStatus.CANCELLED,
      reviewNote: 'Cư dân đã hủy đăng ký.',
      reviewedAt: null,
    },
    {
      id: '91000000-0000-4000-8000-000000000004',
      apartmentId: requireApartment(apartmentIds, 'A-0101'),
      declaredById: owner.id,
      reviewedById: receptionist.id,
      guestFullName: 'Nguyễn Thị Lan',
      guestDateOfBirth: new Date('1970-02-18T00:00:00.000Z'),
      guestPhone: '0908555666',
      relationshipToResident: 'Mẹ',
      startDate: new Date(now.getTime() - 20 * day),
      endDate: new Date(now.getTime() - 10 * day),
      purpose: 'Thăm gia đình.',
      status: TemporaryStayStatus.EXPIRED,
      reviewNote: 'Đăng ký đã hết thời gian lưu trú.',
      reviewedAt: new Date(now.getTime() - 22 * day),
    },
  ] as const;

  for (const stay of stays) {
    await prisma.temporaryStay.upsert({
      where: { id: stay.id },
      update: stay,
      create: stay,
    });
  }
}

async function seedSecurityReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
  apartmentIds: Map<string, string>,
): Promise<void> {
  const management = requireDemoUser(users, 'management');
  const tenant = requireDemoUser(users, 'tenant');
  const buyer = requireDemoUser(users, 'buyer');
  const renter = requireDemoUser(users, 'renter');
  const security = requireDemoUser(users, 'security');
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;
  const apartmentCodes = ['A-0102', 'A-0301', 'B-0101'];
  const apartmentRecords = await prisma.apartment.findMany({
    where: {
      id: {
        in: apartmentCodes.map((code) => requireApartment(apartmentIds, code)),
      },
    },
    select: { id: true, buildingId: true },
  });
  const buildingByApartment = new Map(
    apartmentRecords.map((apartment) => [apartment.id, apartment.buildingId]),
  );
  const a0102 = requireApartment(apartmentIds, 'A-0102');
  const a0301 = requireApartment(apartmentIds, 'A-0301');
  const b0101 = requireApartment(apartmentIds, 'B-0101');
  const buildingId = (apartmentId: string) => {
    const id = buildingByApartment.get(apartmentId);
    if (!id) throw new Error('Thiếu tòa nhà của căn hộ để tạo sự cố.');
    return id;
  };
  const incidents = [
    {
      id: 'a1000000-0000-4000-8000-000000000001',
      code: 'AN-INIT-REVIEWING',
      buildingId: buildingId(a0102),
      apartmentId: a0102,
      reportedById: tenant.id,
      resolvedById: security.id,
      type: SecurityIncidentType.SUSPICIOUS_PERSON,
      title: 'Người lạ đi lại tại hành lang',
      description: 'Cư dân báo người lạ xuất hiện nhiều lần tại tầng 1.',
      location: 'Hành lang tầng 1 tòa A',
      occurredAt: new Date(now.getTime() - 2 * day),
      status: SecurityIncidentStatus.REVIEWING,
      resolutionNote: 'Bảo vệ đang kiểm tra camera và sổ khách.',
      resolvedAt: null,
    },
    {
      id: 'a1000000-0000-4000-8000-000000000002',
      code: 'AN-INIT-RESOLVED',
      buildingId: buildingId(a0301),
      apartmentId: a0301,
      reportedById: buyer.id,
      resolvedById: security.id,
      type: SecurityIncidentType.LOST_AND_FOUND,
      title: 'Tìm thấy ví tại sảnh thang máy',
      description: 'Một chiếc ví được giao cho bộ phận bảo vệ.',
      location: 'Sảnh thang máy tầng 3 tòa A',
      occurredAt: new Date(now.getTime() - 8 * day),
      status: SecurityIncidentStatus.RESOLVED,
      resolutionNote: 'Đã xác minh và bàn giao lại cho chủ sở hữu.',
      resolvedAt: new Date(now.getTime() - 7 * day),
    },
    {
      id: 'a1000000-0000-4000-8000-000000000003',
      code: 'AN-INIT-CANCELLED',
      buildingId: buildingId(b0101),
      apartmentId: b0101,
      reportedById: renter.id,
      resolvedById: management.id,
      type: SecurityIncidentType.FIRE_SAFETY,
      title: 'Báo khói tại khu bếp',
      description: 'Cư dân báo nhầm do khói khi nấu ăn.',
      location: 'Căn B-0101',
      occurredAt: new Date(now.getTime() - 5 * day),
      status: SecurityIncidentStatus.CANCELLED,
      resolutionNote: 'Đã xác nhận không có sự cố cháy.',
      resolvedAt: new Date(now.getTime() - 5 * day),
    },
  ] as const;

  for (const incident of incidents) {
    await prisma.securityIncident.upsert({
      where: { id: incident.id },
      update: incident,
      create: incident,
    });
  }
}

async function seedNotificationReportData(
  users: Map<InitialUserKey, InitialUserRecord>,
): Promise<void> {
  const now = new Date();
  const day = 24 * 60 * 60 * 1000;
  const admin = await prisma.user.findFirst({
    where: { userRoles: { some: { role: { code: RoleCode.ADMIN } } } },
    select: { id: true },
  });
  const notifications = [
    {
      id: 'b3000000-0000-4000-8000-000000000001',
      userId: requireDemoUser(users, 'accountant').id,
      title: 'Có thanh toán cần đối chiếu',
      message: 'Giao dịch chuyển khoản của hóa đơn A-0101 đang chờ xác nhận.',
      type: NotificationType.INVOICE,
      referenceType: 'payment',
      referenceId: '74000000-0000-4000-8000-000000000003',
      readAt: null,
    },
    {
      id: 'b3000000-0000-4000-8000-000000000002',
      userId: requireDemoUser(users, 'receptionist').id,
      title: 'Có đăng ký khách lưu trú mới',
      message: 'Đăng ký khách lưu trú tại A-0101 đang chờ tiếp nhận.',
      type: NotificationType.SYSTEM,
      referenceType: 'temporary_stay',
      referenceId: '90000000-0000-4000-8000-000000000001',
      readAt: null,
    },
    {
      id: 'b3000000-0000-4000-8000-000000000003',
      userId: requireDemoUser(users, 'security').id,
      title: 'Sự cố đang cần kiểm tra',
      message: 'Vui lòng kiểm tra thông tin người lạ tại hành lang tòa A.',
      type: NotificationType.SYSTEM,
      referenceType: 'security_incident',
      referenceId: 'a1000000-0000-4000-8000-000000000001',
      readAt: null,
    },
    {
      id: 'b3000000-0000-4000-8000-000000000004',
      userId: requireDemoUser(users, 'technician').id,
      title: 'Bạn được phân công yêu cầu bảo trì',
      message: 'Yêu cầu kiểm tra điều hòa B-0101 đang được thực hiện.',
      type: NotificationType.MAINTENANCE,
      referenceType: 'maintenance_request',
      referenceId: '41000000-0000-4000-8000-000000000002',
      readAt: null,
    },
    {
      id: 'b3000000-0000-4000-8000-000000000005',
      userId: requireDemoUser(users, 'newcomer').id,
      title: 'Hồ sơ thuê căn hộ đã được ghi nhận',
      message: 'Ban quản lý sẽ liên hệ để sắp xếp lịch xem căn hộ.',
      type: NotificationType.HOUSING,
      referenceType: 'housing_application',
      referenceId: '31000000-0000-4000-8000-000000000001',
      readAt: null,
    },
    {
      id: 'b3000000-0000-4000-8000-000000000006',
      userId: requireDemoUser(users, 'buyer').id,
      title: 'Hợp đồng mua bán đang có hiệu lực',
      message: 'Quyền sở hữu căn A-0301 đã được ghi nhận trên hệ thống.',
      type: NotificationType.HOUSING,
      referenceType: 'housing_contract',
      referenceId: '32000000-0000-4000-8000-000000000001',
      readAt: new Date(now.getTime() - 170 * day),
    },
    {
      id: 'b3000000-0000-4000-8000-000000000007',
      userId: requireDemoUser(users, 'renter').id,
      title: 'Hợp đồng thuê đã được xác nhận',
      message: 'Thông tin cư trú tại căn B-0101 đã được cập nhật.',
      type: NotificationType.HOUSING,
      referenceType: 'housing_contract',
      referenceId: '32000000-0000-4000-8000-000000000002',
      readAt: new Date(now.getTime() - 140 * day),
    },
    {
      id: 'b3000000-0000-4000-8000-000000000009',
      userId: requireDemoUser(users, 'formerOwner').id,
      title: 'Giao dịch căn A-0301 đã hoàn tất',
      message: 'Bài đăng được đóng sau khi ban quản lý xác nhận hồ sơ.',
      type: NotificationType.HOUSING,
      referenceType: 'housing_listing',
      referenceId: '30000000-0000-4000-8000-000000000004',
      readAt: new Date(now.getTime() - 174 * day),
    },
  ];
  for (const notification of notifications) {
    await prisma.notification.upsert({
      where: { id: notification.id },
      update: notification,
      create: notification,
    });
  }

  if (admin) {
    const adminNotification = {
      id: 'b3000000-0000-4000-8000-000000000010',
      userId: admin.id,
      title: 'Bộ dữ liệu báo cáo đã sẵn sàng',
      message: 'Hệ thống đã có dữ liệu mẫu cho toàn bộ phân hệ nghiệp vụ.',
      type: NotificationType.SYSTEM,
      referenceType: null,
      referenceId: null,
      readAt: null,
    };
    await prisma.notification.upsert({
      where: { id: adminNotification.id },
      update: adminNotification,
      create: adminNotification,
    });
  }
}

async function main(): Promise<void> {
  for (const role of roles) {
    await prisma.role.upsert({
      where: { code: role.code },
      update: {
        name: role.name,
        description: role.description,
        isActive: true,
      },
      create: role,
    });
  }

  const building = await prisma.building.upsert({
    where: { code: 'HOMIE-A' },
    update: {
      name: 'Tòa nhà Homie A',
      address: 'Khu căn hộ Homie',
      floors: 20,
    },
    create: {
      code: 'HOMIE-A',
      name: 'Tòa nhà Homie A',
      address: 'Khu căn hộ Homie',
      floors: 20,
    },
  });

  for (const apartment of apartments) {
    await prisma.apartment.upsert({
      where: {
        buildingId_code: {
          buildingId: building.id,
          code: apartment.code,
        },
      },
      update: apartment,
      create: {
        ...apartment,
        buildingId: building.id,
        status: ApartmentStatus.VACANT,
      },
    });
  }

  const buildingB = await prisma.building.upsert({
    where: { code: 'HOMIE-B' },
    update: {
      name: 'Tòa nhà Homie B',
      address: 'Khu căn hộ Homie - phân khu B',
      floors: 18,
    },
    create: {
      code: 'HOMIE-B',
      name: 'Tòa nhà Homie B',
      address: 'Khu căn hộ Homie - phân khu B',
      floors: 18,
    },
  });
  const buildingBApartments = [
    { code: 'B-0101', floor: 1, area: 78, bedrooms: 2 },
    { code: 'B-0102', floor: 1, area: 92, bedrooms: 3 },
    { code: 'B-0201', floor: 2, area: 60, bedrooms: 2 },
    { code: 'B-0202', floor: 2, area: 110, bedrooms: 4 },
  ] as const;
  for (const apartment of buildingBApartments) {
    await prisma.apartment.upsert({
      where: {
        buildingId_code: { buildingId: buildingB.id, code: apartment.code },
      },
      update: apartment,
      create: {
        ...apartment,
        buildingId: buildingB.id,
        status: ApartmentStatus.VACANT,
      },
    });
  }

  for (const feeType of feeTypes) {
    await prisma.feeType.upsert({
      where: { code: feeType.code },
      update: { ...feeType, isActive: true },
      create: feeType,
    });
  }

  for (const service of services) {
    const isActive = 'isActive' in service ? service.isActive : true;
    const existing = await prisma.service.findFirst({
      where: { name: service.name },
      select: { id: true },
    });

    if (existing) {
      await prisma.service.update({
        where: { id: existing.id },
        data: { ...service, isActive },
      });
    } else {
      await prisma.service.create({ data: { ...service, isActive } });
    }
  }

  for (const amenity of amenities) {
    const existing = await prisma.amenity.findFirst({
      where: { buildingId: building.id, name: amenity.name },
      select: { id: true },
    });

    if (existing) {
      await prisma.amenity.update({
        where: { id: existing.id },
        data: { ...amenity, isActive: true },
      });
    } else {
      await prisma.amenity.create({
        data: { ...amenity, buildingId: building.id },
      });
    }
  }

  const roleRecords = await prisma.role.findMany({
    select: { id: true, code: true },
  });
  const roleIds = new Map<RoleCode, string>(
    roleRecords.map((role) => [role.code, role.id]),
  );
  const adminRoleId = roleIds.get(RoleCode.ADMIN);
  if (!adminRoleId) throw new Error('Không tìm thấy vai trò ADMIN.');
  const adminCreated = await seedAdmin(adminRoleId);

  let initialDatasetCreated = false;
  const initialAccountPassword = process.env.SEED_INITIAL_ACCOUNT_PASSWORD;
  if (initialAccountPassword) {
    await prisma.notification.deleteMany({
      where: {
        user: {
          email: {
            in: ['member.household@homie.com'],
          },
        },
      },
    });
    await prisma.user.deleteMany({
      where: {
        email: {
          in: ['member.household@homie.com'],
        },
        apartmentMemberships: { none: {} },
      },
    });
    const initialUserRecords = await seedInitialUsers(
      roleIds,
      initialAccountPassword,
    );
    await seedStaffBuildingAssignments(
      initialUserRecords,
      building.id,
      buildingB.id,
    );
    const apartmentRecords = await prisma.apartment.findMany({
      where: { buildingId: { in: [building.id, buildingB.id] } },
      select: { id: true, code: true },
    });
    const apartmentIds = new Map(
      apartmentRecords.map((apartment) => [apartment.code, apartment.id]),
    );
    await seedInitialMemberships(initialUserRecords, apartmentIds);
    await seedInitialTransactions(initialUserRecords, apartmentIds);
    await seedHousingReportData(initialUserRecords, apartmentIds);
    await seedAnnouncementReportData(initialUserRecords, building.id);
    await seedBillingReportData(initialUserRecords, apartmentIds);
    await seedMaintenanceReportData(initialUserRecords, apartmentIds);
    await seedServiceReportData(initialUserRecords, apartmentIds);
    await seedAmenityReportData(initialUserRecords, apartmentIds);
    await seedTemporaryStayReportData(initialUserRecords, apartmentIds);
    await seedSecurityReportData(initialUserRecords, apartmentIds);
    await seedNotificationReportData(initialUserRecords);
    initialDatasetCreated = true;
  } else {
    console.log(
      'Bỏ qua bộ dữ liệu nghiệm thu: chưa cấu hình SEED_INITIAL_ACCOUNT_PASSWORD.',
    );
  }

  console.log('Seed hoàn tất:');
  console.log(`- ${roles.length} vai trò`);
  console.log('- 2 tòa nhà');
  console.log(`- ${apartments.length + buildingBApartments.length} căn hộ mẫu`);
  console.log(`- ${feeTypes.length} loại phí`);
  console.log(`- ${services.length} dịch vụ`);
  console.log(`- ${amenities.length} tiện ích`);
  console.log(`- Tài khoản quản trị: ${adminCreated ? 'đã tạo' : 'chưa tạo'}`);
  console.log(
    `- Bộ dữ liệu nghiệm thu: ${initialDatasetCreated ? 'đã tạo/cập nhật' : 'chưa tạo'}`,
  );
  if (initialDatasetCreated) {
    console.log('- Tài khoản nghiệm thu:');
    for (const user of initialUsers) {
      console.log(`  ${user.role}: ${user.email}`);
    }
    console.log(
      '- Mật khẩu khởi tạo lấy từ SEED_INITIAL_ACCOUNT_PASSWORD; khi vận hành phải dùng thư mời/đặt lại mật khẩu.',
    );
  }
}

main()
  .catch((error: unknown) => {
    console.error('Seed thất bại:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
