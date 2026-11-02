import 'dotenv/config';

import { Injectable, Logger } from '@nestjs/common';
import {
  applicationDefault,
  cert,
  getApps,
  initializeApp,
  type App,
} from 'firebase-admin/app';
import { getMessaging, type Message } from 'firebase-admin/messaging';
import { PrismaService } from '../database/prisma.service';

export interface PushNotificationInput {
  title: string;
  message: string;
  type: string;
  notificationId?: string;
  referenceType?: string;
  referenceId?: string;
}

@Injectable()
export class PushNotificationsService {
  private readonly logger = new Logger(PushNotificationsService.name);
  private readonly firebaseApp: App | null;

  constructor(private readonly prisma: PrismaService) {
    this.firebaseApp = this.initializeFirebase();
  }

  async sendToUsers(
    userIds: string[],
    input: PushNotificationInput,
  ): Promise<void> {
    if (!this.firebaseApp || !userIds.length) return;
    try {
      const installations = await this.prisma.deviceInstallation.findMany({
        where: { userId: { in: [...new Set(userIds)] }, isActive: true },
        select: { firebaseToken: true },
      });
      if (!installations.length) return;

      for (let index = 0; index < installations.length; index += 500) {
        const batch = installations.slice(index, index + 500);
        const messages: Message[] = batch.map((item) => ({
          token: item.firebaseToken,
          notification: { title: input.title, body: input.message },
          data: {
            type: input.type,
            notificationId: input.notificationId ?? '',
            referenceType: input.referenceType ?? '',
            referenceId: input.referenceId ?? '',
          },
          android: {
            priority: 'high',
            notification: { channelId: 'homie_important' },
          },
        }));
        const result = await getMessaging(this.firebaseApp).sendEach(messages);
        const invalidTokens = result.responses
          .map((response, responseIndex) => ({
            response,
            token: batch[responseIndex].firebaseToken,
          }))
          .filter(({ response }) => this.isInvalidToken(response.error?.code))
          .map(({ token }) => token);
        if (invalidTokens.length) {
          await this.prisma.deviceInstallation.updateMany({
            where: { firebaseToken: { in: invalidTokens } },
            data: { isActive: false },
          });
        }
      }
    } catch (error) {
      this.logger.warn(
        `Không thể gửi Firebase push: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }

  private initializeFirebase(): App | null {
    if (getApps().length) return getApps()[0];
    const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS?.trim();
    const projectId = process.env.FIREBASE_PROJECT_ID?.trim();
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();
    const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY;
    const hasInlineCredentials = projectId && clientEmail && rawPrivateKey;
    if (!credentialsPath && !hasInlineCredentials) {
      this.logger.warn(
        'Firebase Admin chưa cấu hình; hãy đặt GOOGLE_APPLICATION_CREDENTIALS hoặc bộ biến FIREBASE_*. Thông báo vẫn được lưu trong Supabase.',
      );
      return null;
    }
    try {
      return initializeApp({
        credential: credentialsPath
          ? applicationDefault()
          : cert({
              projectId: projectId!,
              clientEmail: clientEmail!,
              privateKey: rawPrivateKey!.replace(/\\n/g, '\n'),
            }),
        ...(projectId ? { projectId } : {}),
      });
    } catch (error) {
      this.logger.error(
        `Không thể khởi tạo Firebase Admin: ${error instanceof Error ? error.message : String(error)}`,
      );
      return null;
    }
  }

  private isInvalidToken(code: string | undefined): boolean {
    return (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token' ||
      code === 'messaging/invalid-argument'
    );
  }
}
