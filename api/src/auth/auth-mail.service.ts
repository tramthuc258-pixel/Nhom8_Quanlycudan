import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import nodemailer, { type Transporter } from 'nodemailer';

@Injectable()
export class AuthMailService {
  private readonly transporter: Transporter | null;

  constructor() {
    const host = process.env.SMTP_HOST?.trim();
    const user = process.env.SMTP_USER?.trim();
    const pass = process.env.SMTP_PASSWORD;

    this.transporter =
      host && user && pass
        ? nodemailer.createTransport({
            host,
            port: Number(process.env.SMTP_PORT ?? 587),
            secure: process.env.SMTP_SECURE === 'true',
            auth: { user, pass },
          })
        : null;
  }

  async sendPasswordResetCode(email: string, code: string): Promise<boolean> {
    if (!this.transporter) {
      if (process.env.NODE_ENV === 'production') {
        throw new ServiceUnavailableException(
          'Dịch vụ gửi email chưa được cấu hình.',
        );
      }
      return false;
    }

    await this.transporter.sendMail({
      from: process.env.SMTP_FROM ?? process.env.SMTP_USER,
      to: email,
      subject: 'Mã đặt lại mật khẩu Homie',
      text: `Mã đặt lại mật khẩu Homie của bạn là ${code}. Mã có hiệu lực trong 15 phút.`,
      html: `<p>Mã đặt lại mật khẩu Homie của bạn là:</p><p style="font-size:28px;font-weight:700;letter-spacing:6px">${code}</p><p>Mã có hiệu lực trong 15 phút. Nếu bạn không yêu cầu, hãy bỏ qua email này.</p>`,
    });
    return true;
  }

  async sendRegistrationVerificationCode(
    email: string,
    code: string,
  ): Promise<boolean> {
    if (!this.transporter) {
      if (process.env.NODE_ENV === 'production') {
        throw new ServiceUnavailableException(
          'Dịch vụ gửi email chưa được cấu hình.',
        );
      }
      return false;
    }

    await this.transporter.sendMail({
      from: process.env.SMTP_FROM ?? process.env.SMTP_USER,
      to: email,
      subject: 'Mã xác minh đăng ký Homie',
      text: `Mã xác minh đăng ký Homie của bạn là ${code}. Mã có hiệu lực trong 15 phút.`,
      html: `<p>Chào mừng bạn đến với Homie.</p><p>Mã xác minh đăng ký của bạn là:</p><p style="font-size:28px;font-weight:700;letter-spacing:6px">${code}</p><p>Mã có hiệu lực trong 15 phút. Nếu bạn không thực hiện đăng ký, hãy bỏ qua email này.</p>`,
    });
    return true;
  }

  async sendStaffInvitation(
    email: string,
    fullName: string,
    temporaryPassword: string,
    roleName: string,
  ): Promise<boolean> {
    if (!this.transporter) {
      if (process.env.NODE_ENV === 'production') {
        throw new ServiceUnavailableException(
          'Dịch vụ gửi email chưa được cấu hình.',
        );
      }
      return false;
    }

    await this.transporter.sendMail({
      from: process.env.SMTP_FROM ?? process.env.SMTP_USER,
      to: email,
      subject: 'Tài khoản nhân viên Homie của bạn',
      text: `Xin chào ${fullName}. Bạn đã được cấp tài khoản Homie với vai trò ${roleName}. Mật khẩu tạm thời: ${temporaryPassword}. Hãy đổi mật khẩu ngay trong lần đăng nhập đầu tiên.`,
      html: `<p>Xin chào <strong>${fullName}</strong>,</p><p>Bạn đã được cấp tài khoản Homie với vai trò <strong>${roleName}</strong>.</p><p>Mật khẩu tạm thời:</p><p style="font-size:24px;font-weight:700;letter-spacing:2px">${temporaryPassword}</p><p>Vì lý do bảo mật, hệ thống sẽ yêu cầu bạn đổi mật khẩu ngay trong lần đăng nhập đầu tiên.</p>`,
    });
    return true;
  }
}
