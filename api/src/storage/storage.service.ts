import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';

const allowedMimeTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'application/pdf',
]);

@Injectable()
export class StorageService {
  private readonly baseUrl = process.env.SUPABASE_URL?.replace(/\/$/, '');
  private readonly serviceKey =
    process.env.SUPABASE_SECRET_KEY ?? process.env.SUPABASE_SERVICE_ROLE_KEY;
  private readonly bucket =
    process.env.SUPABASE_STORAGE_BUCKET ?? 'homie-files';

  async upload(
    file: Express.Multer.File | undefined,
    userId: string,
    category?: string,
  ): Promise<object> {
    if (!file) throw new BadRequestException('Hãy chọn tệp cần tải lên.');
    if (!allowedMimeTypes.has(file.mimetype)) {
      throw new BadRequestException('Chỉ chấp nhận JPG, PNG, WebP hoặc PDF.');
    }
    const normalizedCategory = (category ?? 'general')
      .toLowerCase()
      .replace(/[^a-z0-9_-]/g, '-')
      .slice(0, 40);
    const isAvatar = normalizedCategory === 'avatar';
    if (isAvatar && !file.mimetype.startsWith('image/')) {
      throw new BadRequestException(
        'Ảnh đại diện chỉ chấp nhận JPG, PNG hoặc WebP.',
      );
    }
    if (isAvatar && file.size > 2 * 1024 * 1024) {
      throw new BadRequestException('Ảnh đại diện không được vượt quá 2 MB.');
    }
    if (!this.baseUrl || !this.serviceKey) {
      throw new ServiceUnavailableException(
        'Supabase Storage chưa được cấu hình trên máy chủ.',
      );
    }

    await this.ensureBucket();
    const extension = this.extension(file.originalname, file.mimetype);
    const folder = isAvatar ? 'avatars' : normalizedCategory;
    const path = `${folder}/${userId}/${Date.now()}-${randomUUID()}${extension}`;
    const response = await fetch(
      `${this.baseUrl}/storage/v1/object/${this.bucket}/${path}`,
      {
        method: 'POST',
        headers: {
          ...this.authHeaders(),
          'content-type': file.mimetype,
          'x-upsert': 'false',
        },
        body: new Uint8Array(file.buffer),
      },
    );
    if (!response.ok) {
      throw new ServiceUnavailableException(
        `Không thể tải tệp lên Supabase Storage (${response.status}).`,
      );
    }
    const signedUrl = await this.createSignedUrl(path);
    return {
      path,
      url: signedUrl,
      fileName: file.originalname,
      mimeType: file.mimetype,
      size: file.size,
    };
  }

  private async ensureBucket(): Promise<void> {
    const headers = {
      ...this.authHeaders(),
      'content-type': 'application/json',
    };
    const existing = await fetch(
      `${this.baseUrl}/storage/v1/bucket/${this.bucket}`,
      { headers },
    );
    if (existing.ok) return;
    if (!(await this.isMissingBucketResponse(existing))) {
      throw new ServiceUnavailableException(
        'Không thể kiểm tra Supabase Storage bucket.',
      );
    }
    const created = await fetch(`${this.baseUrl}/storage/v1/bucket`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        id: this.bucket,
        name: this.bucket,
        public: false,
        file_size_limit: 10485760,
        allowed_mime_types: [...allowedMimeTypes],
      }),
    });
    if (!created.ok && created.status !== 409) {
      throw new ServiceUnavailableException(
        'Không thể tạo Supabase Storage bucket.',
      );
    }
  }

  private async isMissingBucketResponse(response: Response): Promise<boolean> {
    if (response.status === 404) return true;
    if (response.status !== 400) return false;

    const payload = (await response.json().catch(() => null)) as {
      statusCode?: string | number;
      code?: string;
      error?: string;
    } | null;
    return (
      payload?.code === 'NoSuchBucket' ||
      String(payload?.statusCode) === '404' ||
      payload?.error === 'Bucket not found'
    );
  }

  private async createSignedUrl(path: string): Promise<string> {
    const response = await fetch(
      `${this.baseUrl}/storage/v1/object/sign/${this.bucket}/${path}`,
      {
        method: 'POST',
        headers: {
          ...this.authHeaders(),
          'content-type': 'application/json',
        },
        body: JSON.stringify({ expiresIn: 365 * 24 * 60 * 60 }),
      },
    );
    if (!response.ok) {
      throw new ServiceUnavailableException(
        'Tệp đã tải lên nhưng không thể tạo đường dẫn truy cập bảo mật.',
      );
    }
    const result = (await response.json()) as {
      signedURL?: string;
      signedUrl?: string;
    };
    const signed = result.signedUrl ?? result.signedURL;
    if (!signed) {
      throw new ServiceUnavailableException(
        'Supabase không trả về đường dẫn tệp đã ký.',
      );
    }
    if (signed.startsWith('http://') || signed.startsWith('https://')) {
      return signed;
    }
    const normalized = signed.startsWith('/') ? signed : `/${signed}`;
    if (normalized.startsWith('/storage/v1/')) {
      return `${this.baseUrl}${normalized}`;
    }
    return `${this.baseUrl}/storage/v1${normalized}`;
  }

  private authHeaders(): Record<string, string> {
    const key = this.serviceKey!;
    return {
      apikey: key,
      ...(key.startsWith('sb_secret_')
        ? {}
        : { authorization: `Bearer ${key}` }),
    };
  }

  private extension(name: string, mimeType: string): string {
    const match = name.toLowerCase().match(/\.[a-z0-9]{1,8}$/);
    if (match) return match[0];
    if (mimeType === 'image/jpeg') return '.jpg';
    if (mimeType === 'image/png') return '.png';
    if (mimeType === 'image/webp') return '.webp';
    if (mimeType === 'application/pdf') return '.pdf';
    return '';
  }
}
