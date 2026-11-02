import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import {
  InvoiceStatus,
  MembershipStatus,
  MembershipType,
  PrismaClient,
  RoleCode,
} from '../src/generated/prisma/client';

const connectionString = process.env.DIRECT_URL ?? process.env.DATABASE_URL;
if (!connectionString) throw new Error('Thiếu DIRECT_URL hoặc DATABASE_URL.');

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

const email = process.env.SHOWCASE_RESIDENT_EMAIL?.trim();
if (!email) {
  throw new Error('Thiếu SHOWCASE_RESIDENT_EMAIL trong api/.env.');
}
const billingMonth = new Date('2027-01-01T00:00:00.000Z');
const dueDate = new Date('2027-01-15T00:00:00.000Z');
const invoiceCode = 'HD-202701-A0301-VNPAY';

async function main() {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error(`Không tìm thấy tài khoản ${email}.`);

  const membership = await prisma.apartmentMembership.findFirst({
    where: {
      userId: user.id,
      status: MembershipStatus.ACTIVE,
      type: MembershipType.TENANT,
      apartment: { code: 'A-0301' },
    },
    include: { apartment: true },
  });
  if (!membership) throw new Error('Tài khoản chưa là người thuê căn A-0301.');

  const apartment = membership.apartment;
  const existing = await prisma.invoice.findFirst({
    where: { apartmentId: apartment.id, billingMonth },
    select: { code: true, status: true, payerId: true, totalAmount: true },
  });
  const recentInvoices = await prisma.invoice.findMany({
    where: { payerId: user.id },
    orderBy: { billingMonth: 'desc' },
    select: { code: true, billingMonth: true, status: true, totalAmount: true },
    take: 5,
  });
  console.log('Hóa đơn hiện có:', recentInvoices);
  if (existing) {
    if (existing.payerId !== user.id) {
      throw new Error('Kỳ 01/2027 đã có hóa đơn của người thanh toán khác.');
    }
    console.log('Kỳ 01/2027 đã có hóa đơn:', existing);
    return;
  }
  if (!process.argv.includes('--create')) {
    console.log('Chưa có hóa đơn kỳ 01/2027. Dùng --create để tạo.');
    return;
  }

  const accountant = await prisma.user.findFirst({
    where: {
      status: 'ACTIVE',
      staffBuildingAssignments: {
        some: { buildingId: apartment.buildingId, isActive: true },
      },
      userRoles: { some: { role: { code: RoleCode.ACCOUNTANT } } },
    },
  });
  if (!accountant) throw new Error('Không tìm thấy kế toán phụ trách tòa A.');

  const feeTypes = await prisma.feeType.findMany({
    where: {
      isActive: true,
      code: { in: ['MANAGEMENT_FEE', 'ELECTRICITY_FEE', 'INTERNET_FEE'] },
    },
  });
  const fee = (code: string) => {
    const item = feeTypes.find((value) => value.code === code);
    if (!item) throw new Error(`Thiếu danh mục phí ${code}.`);
    return item;
  };
  const items = [
    { feeType: fee('MANAGEMENT_FEE'), quantity: apartment.area.toNumber() },
    { feeType: fee('ELECTRICITY_FEE'), quantity: 100 },
    { feeType: fee('INTERNET_FEE'), quantity: 1 },
  ].map(({ feeType, quantity }) => {
    const unitPrice = feeType.defaultUnitPrice.toNumber();
    return {
      feeTypeId: feeType.id,
      name: feeType.name,
      quantity,
      unitPrice,
      amount: quantity * unitPrice,
    };
  });

  const now = new Date();
  const invoice = await prisma.invoice.create({
    data: {
      code: invoiceCode,
      apartmentId: apartment.id,
      payerId: user.id,
      createdById: accountant.id,
      publishedById: accountant.id,
      billingMonth,
      issuedAt: now,
      publishedAt: now,
      dueDate,
      status: InvoiceStatus.UNPAID,
      totalAmount: items.reduce((total, item) => total + item.amount, 0),
      note: 'Hóa đơn kỳ 01/2027 của căn A-0301.',
      items: { create: items },
    },
    include: { items: true },
  });
  console.log('Đã tạo hóa đơn:', {
    code: invoice.code,
    status: invoice.status,
    totalAmount: invoice.totalAmount.toString(),
    itemCount: invoice.items.length,
  });
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
