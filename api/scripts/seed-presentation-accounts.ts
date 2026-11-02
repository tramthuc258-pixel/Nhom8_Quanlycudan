import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import { hash } from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import {
  PrismaClient,
  RoleCode,
  UserStatus,
} from '../src/generated/prisma/client';

const connectionString = process.env.DIRECT_URL ?? process.env.DATABASE_URL;
if (!connectionString) throw new Error('Thiếu DIRECT_URL hoặc DATABASE_URL.');

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});
const credentialsPath = resolve('secrets/presentation-accounts.json');

const accounts = [
  {
    role: RoleCode.MANAGEMENT,
    fullName: 'Nguyễn Hải Đăng',
    email: 'dang.management@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.MANAGEMENT,
    fullName: 'Lê Thị Thu Hà',
    email: 'ha.management@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.MANAGEMENT,
    fullName: 'Phạm Quốc Khánh',
    email: 'khanh.management@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.ADMIN,
    fullName: 'Võ Minh Đức',
    email: 'duc.admin@homie.com',
    buildings: [],
  },
  {
    role: RoleCode.ADMIN,
    fullName: 'Trần Ngọc Lan',
    email: 'lan.admin@homie.com',
    buildings: [],
  },
  {
    role: RoleCode.ADMIN,
    fullName: 'Đặng Gia Huy',
    email: 'huy.admin@homie.com',
    buildings: [],
  },
  {
    role: RoleCode.ADMIN,
    fullName: 'Bùi Thu Trang',
    email: 'trang.admin@homie.com',
    buildings: [],
  },
  {
    role: RoleCode.ACCOUNTANT,
    fullName: 'Nguyễn Thị Minh Châu',
    email: 'chau.accountant@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.ACCOUNTANT,
    fullName: 'Lê Phương Anh',
    email: 'anh.accountant@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.ACCOUNTANT,
    fullName: 'Trần Quốc Tuấn',
    email: 'tuan.accountant@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.ACCOUNTANT,
    fullName: 'Phạm Thị Hồng',
    email: 'hong.accountant@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.RECEPTIONIST,
    fullName: 'Hồ Mỹ Linh',
    email: 'linh.receptionist@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.RECEPTIONIST,
    fullName: 'Đặng Thu Uyên',
    email: 'uyen.receptionist@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.RECEPTIONIST,
    fullName: 'Nguyễn Gia Hân',
    email: 'giahan.receptionist@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.RECEPTIONIST,
    fullName: 'Trịnh Ngọc Bích',
    email: 'bich.receptionist@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.SECURITY,
    fullName: 'Nguyễn Văn Dũng',
    email: 'dung.security@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.SECURITY,
    fullName: 'Lê Quốc Đạt',
    email: 'dat.security@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.SECURITY,
    fullName: 'Đỗ Minh Hiếu',
    email: 'hieu.security@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.SECURITY,
    fullName: 'Trần Nhật Nam',
    email: 'nhatnam.security@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.TECHNICIAN,
    fullName: 'Phạm Công Huy',
    email: 'conghuy.technician@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.TECHNICIAN,
    fullName: 'Nguyễn Thanh Tùng',
    email: 'tung.technician@homie.com',
    buildings: ['HOMIE-B'],
  },
  {
    role: RoleCode.TECHNICIAN,
    fullName: 'Bùi Đức Anh',
    email: 'ducanh.technician@homie.com',
    buildings: ['HOMIE-A'],
  },
  {
    role: RoleCode.TECHNICIAN,
    fullName: 'Lê Hoàng Phúc',
    email: 'phuc.technician@homie.com',
    buildings: ['HOMIE-B'],
  },
] as const;

type Credential = {
  role: RoleCode;
  fullName: string;
  email: string;
  password: string;
  buildings: readonly string[];
};

async function credentials(): Promise<Credential[]> {
  try {
    const saved = JSON.parse(
      await readFile(credentialsPath, 'utf8'),
    ) as Credential[];
    if (
      saved.length !== accounts.length ||
      accounts.some(
        (account, index) =>
          saved[index]?.email !== account.email ||
          saved[index]?.role !== account.role ||
          !saved[index]?.password,
      )
    ) {
      throw new Error(
        'Tệp thông tin đăng nhập không khớp với danh sách tài khoản.',
      );
    }
    return saved;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error;
  }

  const generated: Credential[] = accounts.map((account) => ({
    ...account,
    password: `Hm!${randomBytes(12).toString('base64url')}`,
  }));
  await mkdir(resolve('secrets'), { recursive: true });
  await writeFile(credentialsPath, JSON.stringify(generated, null, 2) + '\n', {
    flag: 'wx',
  });
  return generated;
}

async function main(): Promise<void> {
  const roleRows = await prisma.role.findMany({
    select: { id: true, code: true, isActive: true },
  });
  const roleIds = new Map(
    roleRows
      .filter((role) => role.isActive)
      .map((role) => [role.code, role.id]),
  );
  const buildingRows = await prisma.building.findMany({
    select: { id: true, code: true },
  });
  const buildingIds = new Map(
    buildingRows.map((building) => [building.code, building.id]),
  );
  for (const account of accounts) {
    if (!roleIds.has(account.role))
      throw new Error(`Vai trò ${account.role} chưa hoạt động.`);
    for (const code of account.buildings) {
      if (!buildingIds.has(code))
        throw new Error(`Không tìm thấy tòa ${code}.`);
    }
  }

  const admin = await prisma.user.findFirst({
    where: {
      status: UserStatus.ACTIVE,
      userRoles: { some: { role: { code: RoleCode.ADMIN } } },
    },
    select: { id: true },
  });
  if (!admin)
    throw new Error('Cần có quản trị viên hoạt động trước khi tạo nhân viên.');

  const savedCredentials = await credentials();
  let created = 0;
  let existing = 0;
  for (const account of savedCredentials) {
    const current = await prisma.user.findUnique({
      where: { email: account.email },
      include: { userRoles: { include: { role: true } } },
    });
    if (current) {
      if (current.userRoles[0]?.role.code !== account.role) {
        throw new Error(
          `Email ${account.email} đã thuộc vai trò khác; không ghi đè.`,
        );
      }
      existing++;
      continue;
    }

    await prisma.user.create({
      data: {
        email: account.email,
        fullName: account.fullName,
        passwordHash: await hash(account.password, 12),
        status: UserStatus.ACTIVE,
        mustChangePassword: false,
        userRoles: { create: { roleId: roleIds.get(account.role)! } },
        staffBuildingAssignments: account.buildings.length
          ? {
              create: account.buildings.map((code) => ({
                buildingId: buildingIds.get(code)!,
                assignedById: admin.id,
              })),
            }
          : undefined,
      },
    });
    created++;
  }

  const counts = await prisma.userRole.groupBy({
    by: ['roleId'],
    where: { user: { status: UserStatus.ACTIVE } },
    _count: { userId: true },
  });
  console.log(
    JSON.stringify(
      {
        created,
        alreadyPresent: existing,
        credentialsFile: credentialsPath,
        activeByRole: Object.fromEntries(
          roleRows.map((role) => [
            role.code,
            counts.find((row) => row.roleId === role.id)?._count.userId ?? 0,
          ]),
        ),
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error: Error) => {
    console.error(error.message);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
