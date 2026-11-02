import 'dotenv/config';

export const JWT_EXPIRES_IN = '15m';
export const REFRESH_TOKEN_EXPIRES_DAYS = 30;

export function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET;

  if (!secret || secret.length < 32) {
    throw new Error(
      'JWT_SECRET phải được cấu hình trong api/.env và có ít nhất 32 ký tự.',
    );
  }

  return secret;
}
