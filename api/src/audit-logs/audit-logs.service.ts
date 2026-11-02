import { Injectable } from '@nestjs/common';
import type { Prisma } from '../generated/prisma/client';
import { PrismaService } from '../database/prisma.service';
import type { FindAuditLogsDto } from './dto/find-audit-logs.dto';

export interface WriteAuditLog {
  actorId: string;
  action: string;
  resource: string;
  targetId?: string;
  path: string;
  statusCode: number;
  metadata?: Prisma.InputJsonValue;
  ipAddress?: string;
}

@Injectable()
export class AuditLogsService {
  constructor(private readonly prisma: PrismaService) {}

  write(entry: WriteAuditLog): Promise<unknown> {
    return this.prisma.auditLog.create({ data: entry });
  }

  async findAll(query: FindAuditLogsDto): Promise<unknown> {
    const items = await this.prisma.auditLog.findMany({
      where: {
        actorId: query.actorId,
        action: query.action,
        resource: query.resource,
        createdAt:
          query.from || query.to
            ? {
                gte: query.from ? new Date(query.from) : undefined,
                lte: query.to ? new Date(query.to) : undefined,
              }
            : undefined,
      },
      include: {
        actor: {
          select: { id: true, fullName: true, email: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: query.limit,
    });
    return { items };
  }
}
