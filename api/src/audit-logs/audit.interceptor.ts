import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { catchError, Observable, tap, throwError } from 'rxjs';
import type { AuthenticatedUser } from '../auth/auth.types';
import type { Prisma } from '../generated/prisma/client';
import { AuditLogsService } from './audit-logs.service';

type AuthenticatedRequest = Request & { user?: AuthenticatedUser };

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private readonly auditLogs: AuditLogsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const response = context.switchToHttp().getResponse<Response>();
    const user = request.user;
    if (!this.shouldAudit(request, user)) return next.handle();

    return next.handle().pipe(
      tap((result: unknown) => {
        void this.record(request, response.statusCode, user!, result);
      }),
      catchError((error: unknown) => {
        const status = this.statusOf(error);
        void this.record(request, status, user!, undefined, error);
        return throwError(() => error);
      }),
    );
  }

  private shouldAudit(
    request: AuthenticatedRequest,
    user?: AuthenticatedUser,
  ): boolean {
    if (!user || !['POST', 'PATCH', 'PUT', 'DELETE'].includes(request.method)) {
      return false;
    }
    return !request.path.includes('/audit-logs');
  }

  private async record(
    request: AuthenticatedRequest,
    statusCode: number,
    user: AuthenticatedUser,
    result?: unknown,
    error?: unknown,
  ): Promise<void> {
    try {
      const segments = request.path.split('/').filter(Boolean);
      const apiIndex = segments.indexOf('api');
      const body = this.sanitize(request.body);
      await this.auditLogs.write({
        actorId: user.id,
        action: request.method,
        resource:
          (apiIndex >= 0 ? segments[apiIndex + 1] : segments[0]) ?? 'unknown',
        targetId: this.paramId(request.params?.id) ?? this.resultId(result),
        path: request.path,
        statusCode,
        metadata: this.jsonValue({
          ...(body ? { input: body } : {}),
          ...(error ? { error: this.errorMessage(error) } : {}),
        }),
        ipAddress: request.ip,
      });
    } catch {
      // Audit không được làm hỏng nghiệp vụ chính nếu cơ sở dữ liệu tạm lỗi.
    }
  }

  private sanitize(value: unknown): Record<string, unknown> | undefined {
    if (!value || typeof value !== 'object' || Array.isArray(value)) return;
    const hidden = new Set([
      'password',
      'currentPassword',
      'newPassword',
      'code',
      'firebaseToken',
    ]);
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, item]) => [
        key,
        hidden.has(key) ? '[REDACTED]' : item,
      ]),
    );
  }

  private resultId(result: unknown): string | undefined {
    if (!result || typeof result !== 'object') return;
    const id = (result as { id?: unknown }).id;
    return typeof id === 'string' ? id : undefined;
  }

  private paramId(value: string | string[] | undefined): string | undefined {
    return Array.isArray(value) ? value[0] : value;
  }

  private jsonValue(value: unknown): Prisma.InputJsonValue {
    return JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;
  }

  private statusOf(error: unknown): number {
    const status = (error as { getStatus?: () => number })?.getStatus?.();
    return typeof status === 'number' ? status : 500;
  }

  private errorMessage(error: unknown): string {
    return error instanceof Error ? error.message : 'Unknown error';
  }
}
