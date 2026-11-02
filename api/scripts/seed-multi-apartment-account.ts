import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import { compare, hash } from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import {
  ApartmentStatus,
  MembershipStatus,
  MembershipType,
  PrismaClient,
  RoleCode,
  UserStatus,
} from '../src/generated/prisma/client';

const connectionString = process.env.DIRECT_URL ?? process.env.DATABASE_URL;
if (!connectionString) throw new Error('Thiếu kết nối cơ sở dữ liệu.');

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});
const email = 'phuc.multihome@homie.com';
const fullName = 'Nguyễn Minh Phúc';
const phone = '0901000099';
const credentialsPath = resolve('secrets/multi-apartment-account.json');
const apartmentTargets = [
  { buildingCode: 'HOMIE-A', apartmentCode: 'A-0201' },
  { buildingCode: 'HOMIE-B', apartmentCode: 'B-0102' },
] as const;

async function main(): Promise<void> {
  const residentRole = await prisma.role.findUnique({
    where: { code: RoleCode.RESIDENT },
    select: { id: true },
  });
  if (!residentRole) throw new Error('Chưa có vai trò cư dân.');

  const targets = await Promise.all(
    apartmentTargets.map(async (target) => {
      const apartment = await prisma.apartment.findFirst({
        where: {
          code: target.apartmentCode,
          building: { code: target.buildingCode },
        },
        include: {
          building: { select: { name: true } },
          memberships: { where: { status: MembershipStatus.ACTIVE } },
        },
      });
      if (!apartment)
        throw new Error(`Không tìm thấy ${target.apartmentCode}.`);
      return apartment;
    }),
  );

  let password: string;
  try {
    const saved = JSON.parse(await readFile(credentialsPath, 'utf8')) as {
      email: string;
      password: string;
    };
    if (saved.email !== email || !saved.password) {
      throw new Error('Tệp thông tin đăng nhập không khớp.');
    }
    password = saved.password;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code !== 'ENOENT') throw error;
    if (await prisma.user.findUnique({ where: { email } })) {
      throw new Error('Tài khoản đã tồn tại nhưng thiếu mật khẩu đã lưu.');
    }
    password = `Hm!${randomBytes(12).toString('base64url')}`;
    await mkdir(resolve('secrets'), { recursive: true });
    await writeFile(
      credentialsPath,
      JSON.stringify({ email, password }, null, 2),
      {
        flag: 'wx',
      },
    );
  }

  const passwordHash = await hash(password, 12);
  await prisma.$transaction(async (transaction) => {
    let user = await transaction.user.findUnique({ where: { email } });
    if (!user) {
      if (await transaction.user.findFirst({ where: { phone } })) {
        throw new Error('Số điện thoại thử nghiệm đã được sử dụng.');
      }
      user = await transaction.user.create({
        data: {
          email,
          fullName,
          phone,
          passwordHash,
          status: UserStatus.ACTIVE,
        },
      });
    }
    await transaction.userRole.upsert({
      where: { userId: user.id },
      update: { roleId: residentRole.id },
      create: { userId: user.id, roleId: residentRole.id },
    });

    for (const apartment of targets) {
      const existing = await transaction.apartmentMembership.findFirst({
        where: {
          apartmentId: apartment.id,
          userId: user.id,
          status: MembershipStatus.ACTIVE,
        },
      });
      if (existing) continue;
      const otherActive = await transaction.apartmentMembership.findFirst({
        where: {
          apartmentId: apartment.id,
          status: MembershipStatus.ACTIVE,
        },
      });
      if (otherActive || apartment.memberships.length > 0) {
        throw new Error(`${apartment.code} đã có cư dân đang hiệu lực.`);
      }
      await transaction.apartmentMembership.create({
        data: {
          apartmentId: apartment.id,
          userId: user.id,
          type: MembershipType.OWNER,
          status: MembershipStatus.ACTIVE,
          isPrimary: true,
          startDate: new Date(),
        },
      });
      if (apartment.status === ApartmentStatus.VACANT) {
        await transaction.apartment.update({
          where: { id: apartment.id },
          data: { status: ApartmentStatus.OCCUPIED },
        });
      }
    }
  });

  const account = await prisma.user.findUnique({
    where: { email },
    include: {
      userRoles: { include: { role: true } },
      apartmentMemberships: {
        where: { status: MembershipStatus.ACTIVE },
        include: { apartment: { include: { building: true } } },
      },
    },
  });
  if (
    !account ||
    account.status !== UserStatus.ACTIVE ||
    !(await compare(password, account.passwordHash)) ||
    !account.userRoles.some((item) => item.role.code === RoleCode.RESIDENT) ||
    !apartmentTargets.every((target) =>
      account.apartmentMemberships.some(
        (item) =>
          item.apartment.code === target.apartmentCode &&
          item.apartment.building.code === target.buildingCode &&
          item.type === MembershipType.OWNER,
      ),
    )
  ) {
    throw new Error('Không thể xác nhận tài khoản có đủ quyền và hai căn hộ.');
  }

  console.log(
    JSON.stringify(
      {
        email,
        password,
        apartments: targets.map((apartment) => ({
          code: apartment.code,
          building: apartment.building.name,
        })),
      },
      null,
      2,
    ),
  );
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
