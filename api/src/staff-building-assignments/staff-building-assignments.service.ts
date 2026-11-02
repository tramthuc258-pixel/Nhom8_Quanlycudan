import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { hash } from 'bcryptjs';
import { randomBytes } from 'node:crypto';
import { AuthMailService } from '../auth/auth-mail.service';
import type { AuthenticatedUser } from '../auth/auth.types';
import { PrismaService } from '../database/prisma.service';
import { RoleCode, UserStatus } from '../generated/prisma/client';
import type { CreateStaffAccountDto } from './dto/create-staff-account.dto';
import { STAFF_ROLE_CODES } from './dto/create-staff-account.dto';
import type { SaveStaffBuildingAssignmentDto } from './dto/save-staff-building-assignment.dto';
import type { UpdateStaffAccountDto } from './dto/update-staff-account.dto';

const assignmentInclude = {
  user: {
    select: {
      id: true,
      fullName: true,
      email: true,
      status: true,
      userRoles: { select: { role: { select: { code: true, name: true } } } },
    },
  },
  building: { select: { id: true, code: true, name: true } },
  assignedBy: { select: { id: true, fullName: true } },
} as const;

@Injectable()
export class StaffBuildingAssignmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly authMail: AuthMailService,
  ) {}

  async createStaffAccount(
    dto: CreateStaffAccountDto,
    admin: AuthenticatedUser,
  ): Promise<object> {
    this.assertStaffRole(dto.role);
    const email = dto.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });
    if (existing) throw new ConflictException('Email đã được sử dụng.');

    const buildingIds = [...new Set(dto.buildingIds ?? [])];
    if (buildingIds.length) {
      const buildingCount = await this.prisma.building.count({
        where: { id: { in: buildingIds } },
      });
      if (buildingCount !== buildingIds.length) {
        throw new NotFoundException('Có tòa nhà được chọn không tồn tại.');
      }
    }
    const role = await this.prisma.role.findUnique({
      where: { code: dto.role },
      select: { id: true, name: true, isActive: true },
    });
    if (!role?.isActive) {
      throw new ConflictException('Vai trò nhân viên chưa được kích hoạt.');
    }

    const temporaryPassword = this.generateTemporaryPassword();
    const created = await this.prisma.user.create({
      data: {
        email,
        fullName: dto.fullName.trim(),
        passwordHash: await hash(temporaryPassword, 12),
        mustChangePassword: true,
        userRoles: { create: { roleId: role.id } },
        staffBuildingAssignments: buildingIds.length
          ? {
              create: buildingIds.map((buildingId) => ({
                buildingId,
                assignedById: admin.id,
              })),
            }
          : undefined,
      },
      select: { id: true },
    });

    let emailDelivered = false;
    try {
      emailDelivered = await this.authMail.sendStaffInvitation(
        email,
        dto.fullName.trim(),
        temporaryPassword,
        role.name,
      );
    } catch {
      emailDelivered = false;
    }
    return {
      item: await this.findStaffAccount(created.id),
      invitation: {
        emailDelivered,
        ...(emailDelivered
          ? {}
          : { developmentTemporaryPassword: temporaryPassword }),
      },
    };
  }

  async updateStaffAccount(
    id: string,
    dto: UpdateStaffAccountDto,
  ): Promise<object> {
    await this.assertStaffAccount(id);
    if (!dto.fullName && !dto.role) {
      throw new BadRequestException('Không có thông tin nào để cập nhật.');
    }
    if (dto.role) this.assertStaffRole(dto.role);
    await this.prisma.$transaction(async (transaction) => {
      if (dto.fullName) {
        await transaction.user.update({
          where: { id },
          data: { fullName: dto.fullName.trim() },
        });
      }
      if (dto.role) {
        const role = await transaction.role.findUnique({
          where: { code: dto.role },
          select: { id: true, isActive: true },
        });
        if (!role?.isActive) {
          throw new ConflictException('Vai trò nhân viên chưa được kích hoạt.');
        }
        await transaction.userRole.deleteMany({ where: { userId: id } });
        await transaction.userRole.create({
          data: { userId: id, roleId: role.id },
        });
      }
    });
    return this.findStaffAccount(id);
  }

  async updateStaffStatus(id: string, status: UserStatus): Promise<object> {
    await this.assertStaffAccount(id);
    await this.prisma.user.update({ where: { id }, data: { status } });
    if (status !== UserStatus.ACTIVE) {
      await this.prisma.deviceInstallation.updateMany({
        where: { userId: id },
        data: { isActive: false },
      });
    }
    return this.findStaffAccount(id);
  }

  async resetStaffPassword(id: string): Promise<object> {
    const staff = await this.assertStaffAccount(id);
    const temporaryPassword = this.generateTemporaryPassword();
    await this.prisma.user.update({
      where: { id },
      data: {
        passwordHash: await hash(temporaryPassword, 12),
        mustChangePassword: true,
        passwordResetCodeHash: null,
        passwordResetExpiresAt: null,
      },
    });
    const roleName = staff.userRoles[0]?.role.name ?? 'Nhân viên';
    let emailDelivered = false;
    try {
      emailDelivered = await this.authMail.sendStaffInvitation(
        staff.email,
        staff.fullName,
        temporaryPassword,
        roleName,
      );
    } catch {
      emailDelivered = false;
    }
    return {
      success: true,
      emailDelivered,
      ...(emailDelivered
        ? {}
        : { developmentTemporaryPassword: temporaryPassword }),
    };
  }

  async findStaff(): Promise<object> {
    const users = await this.prisma.user.findMany({
      where: {
        userRoles: {
          some: {
            role: {
              code: {
                in: [
                  RoleCode.MANAGEMENT,
                  RoleCode.ACCOUNTANT,
                  RoleCode.RECEPTIONIST,
                  RoleCode.SECURITY,
                  RoleCode.TECHNICIAN,
                ],
              },
            },
          },
        },
      },
      orderBy: { fullName: 'asc' },
      select: {
        id: true,
        fullName: true,
        email: true,
        status: true,
        mustChangePassword: true,
        userRoles: { select: { role: { select: { code: true, name: true } } } },
        staffBuildingAssignments: {
          include: {
            building: { select: { id: true, code: true, name: true } },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    return {
      items: users.map((user) => ({
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        status: user.status,
        mustChangePassword: user.mustChangePassword,
        roles: user.userRoles.map((item) => item.role.code),
        buildings: user.staffBuildingAssignments.map((item) => ({
          assignmentId: item.id,
          id: item.building.id,
          code: item.building.code,
          name: item.building.name,
          isActive: item.isActive,
          startDate: item.startDate,
          endDate: item.endDate,
        })),
      })),
    };
  }

  async findAll(): Promise<object> {
    const items = await this.prisma.staffBuildingAssignment.findMany({
      include: assignmentInclude,
      orderBy: [{ isActive: 'desc' }, { createdAt: 'desc' }],
    });
    return { items: items.map((item) => this.response(item)) };
  }

  private assertStaffRole(role: RoleCode): void {
    if (!(STAFF_ROLE_CODES as readonly RoleCode[]).includes(role)) {
      throw new BadRequestException(
        'Vai trò nhân viên không hợp lệ. Chỉ dùng MANAGEMENT, ACCOUNTANT, RECEPTIONIST, SECURITY hoặc TECHNICIAN.',
      );
    }
  }

  private async assertStaffAccount(id: string) {
    const staff = await this.prisma.user.findUnique({
      where: { id },
      include: {
        userRoles: { include: { role: true } },
      },
    });
    if (!staff) throw new NotFoundException('Không tìm thấy nhân viên.');
    if (
      !staff.userRoles.some((item) =>
        (STAFF_ROLE_CODES as readonly RoleCode[]).includes(item.role.code),
      )
    ) {
      throw new ConflictException(
        'Tài khoản này không phải tài khoản nhân viên có thể quản lý.',
      );
    }
    return staff;
  }

  private async findStaffAccount(id: string): Promise<object> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        fullName: true,
        email: true,
        status: true,
        mustChangePassword: true,
        userRoles: { select: { role: { select: { code: true } } } },
        staffBuildingAssignments: {
          include: {
            building: { select: { id: true, code: true, name: true } },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    if (!user) throw new NotFoundException('Không tìm thấy nhân viên.');
    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      status: user.status,
      mustChangePassword: user.mustChangePassword,
      roles: user.userRoles.map((item) => item.role.code),
      buildings: user.staffBuildingAssignments.map((item) => ({
        assignmentId: item.id,
        id: item.building.id,
        code: item.building.code,
        name: item.building.name,
        isActive: item.isActive,
        startDate: item.startDate,
        endDate: item.endDate,
      })),
    };
  }

  private generateTemporaryPassword(): string {
    return `Hm!${randomBytes(7).toString('base64url')}`;
  }

  async findMine(user: AuthenticatedUser): Promise<object> {
    if (user.roles.includes(RoleCode.ADMIN)) {
      const buildings = await this.prisma.building.findMany({
        orderBy: { name: 'asc' },
        select: { id: true, code: true, name: true },
      });
      return { globalAccess: true, items: buildings };
    }
    const now = new Date();
    const items = await this.prisma.staffBuildingAssignment.findMany({
      where: {
        userId: user.id,
        isActive: true,
        startDate: { lte: now },
        OR: [{ endDate: null }, { endDate: { gte: now } }],
      },
      include: assignmentInclude,
      orderBy: { building: { name: 'asc' } },
    });
    return {
      globalAccess: false,
      items: items.map((item) => this.response(item)),
    };
  }

  async save(
    dto: SaveStaffBuildingAssignmentDto,
    admin: AuthenticatedUser,
  ): Promise<object> {
    const startDate = dto.startDate ? new Date(dto.startDate) : new Date();
    const endDate = dto.endDate ? new Date(dto.endDate) : null;
    if (endDate && endDate < startDate) {
      throw new BadRequestException('Ngày kết thúc phải sau ngày bắt đầu.');
    }

    const [staff, building] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: dto.userId },
        select: {
          id: true,
          userRoles: { select: { role: { select: { code: true } } } },
        },
      }),
      this.prisma.building.findUnique({
        where: { id: dto.buildingId },
        select: { id: true },
      }),
    ]);
    if (!staff) throw new NotFoundException('Không tìm thấy nhân viên.');
    if (!building) throw new NotFoundException('Không tìm thấy tòa nhà.');
    if (!staff.userRoles.some((item) => item.role.code !== RoleCode.RESIDENT)) {
      throw new ConflictException(
        'Chỉ có thể phân công tài khoản nhân viên cho tòa nhà.',
      );
    }

    const item = await this.prisma.staffBuildingAssignment.upsert({
      where: {
        userId_buildingId: {
          userId: dto.userId,
          buildingId: dto.buildingId,
        },
      },
      update: {
        assignedById: admin.id,
        startDate,
        endDate,
        isActive: true,
      },
      create: {
        userId: dto.userId,
        buildingId: dto.buildingId,
        assignedById: admin.id,
        startDate,
        endDate,
      },
      include: assignmentInclude,
    });
    return this.response(item);
  }

  async end(id: string, admin: AuthenticatedUser): Promise<object> {
    const current = await this.prisma.staffBuildingAssignment.findUnique({
      where: { id },
      select: { id: true, isActive: true },
    });
    if (!current) throw new NotFoundException('Không tìm thấy phân công.');
    if (!current.isActive) {
      throw new ConflictException('Phân công này đã kết thúc trước đó.');
    }
    const item = await this.prisma.staffBuildingAssignment.update({
      where: { id },
      data: { isActive: false, endDate: new Date(), assignedById: admin.id },
      include: assignmentInclude,
    });
    return this.response(item);
  }

  private response(item: {
    id: string;
    userId: string;
    buildingId: string;
    assignedById: string | null;
    startDate: Date;
    endDate: Date | null;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    user: {
      id: string;
      fullName: string;
      email: string;
      status: string;
      userRoles: Array<{ role: { code: RoleCode; name: string } }>;
    };
    building: { id: string; code: string; name: string };
    assignedBy: { id: string; fullName: string } | null;
  }): object {
    return {
      id: item.id,
      user: {
        id: item.user.id,
        fullName: item.user.fullName,
        email: item.user.email,
        status: item.user.status,
        roles: item.user.userRoles.map((entry) => entry.role.code),
      },
      building: item.building,
      assignedBy: item.assignedBy,
      startDate: item.startDate,
      endDate: item.endDate,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    };
  }
}
