import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client';

const connectionString = process.env.DIRECT_URL ?? process.env.DATABASE_URL;
if (!connectionString) throw new Error('Thiếu DATABASE_URL hoặc DIRECT_URL.');

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

async function main(): Promise<void> {
  const users = await prisma.user.findMany({
    select: {
      email: true,
      fullName: true,
      status: true,
      mustChangePassword: true,
      userRoles: { select: { role: { select: { code: true } } } },
    },
    orderBy: [{ fullName: 'asc' }, { email: 'asc' }],
  });

  console.log(
    JSON.stringify(
      {
        total: users.length,
        users: users.map((user) => ({
          email: user.email,
          fullName: user.fullName,
          status: user.status,
          mustChangePassword: user.mustChangePassword,
          roles: user.userRoles.map((item) => item.role.code),
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
