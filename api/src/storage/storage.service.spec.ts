import { StorageService } from './storage.service';

describe('StorageService', () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    process.env.SUPABASE_URL = 'https://example.supabase.co';
    process.env.SUPABASE_SECRET_KEY = 'sb_secret_test';
    process.env.SUPABASE_STORAGE_BUCKET = 'homie-files';
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    jest.restoreAllMocks();
  });

  it('tạo bucket khi Supabase trả HTTP 400 kèm NoSuchBucket', async () => {
    const fetchMock = jest
      .spyOn(global, 'fetch')
      .mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            statusCode: '404',
            error: 'Bucket not found',
            code: 'NoSuchBucket',
          }),
          { status: 400, headers: { 'content-type': 'application/json' } },
        ),
      )
      .mockResolvedValueOnce(new Response('{}', { status: 200 }))
      .mockResolvedValueOnce(new Response('{}', { status: 200 }))
      .mockResolvedValueOnce(
        new Response(JSON.stringify({ signedURL: '/object/sign/file' }), {
          status: 200,
          headers: { 'content-type': 'application/json' },
        }),
      );

    const service = new StorageService();
    const file = {
      originalname: 'hien-truong.png',
      mimetype: 'image/png',
      buffer: Buffer.from('image'),
      size: 5,
    } as Express.Multer.File;

    await expect(
      service.upload(file, 'resident-1', 'maintenance'),
    ).resolves.toMatchObject({
      fileName: 'hien-truong.png',
      mimeType: 'image/png',
      size: 5,
    });

    expect(fetchMock).toHaveBeenCalledTimes(4);
    expect(fetchMock.mock.calls[1][0]).toBe(
      'https://example.supabase.co/storage/v1/bucket',
    );
    expect(fetchMock.mock.calls[1][1]).toMatchObject({ method: 'POST' });
  });

  it('không cho dùng PDF làm ảnh đại diện', async () => {
    const service = new StorageService();
    const file = {
      originalname: 'avatar.pdf',
      mimetype: 'application/pdf',
      buffer: Buffer.from('pdf'),
      size: 3,
    } as Express.Multer.File;

    await expect(service.upload(file, 'resident-1', 'avatar')).rejects.toThrow(
      'Ảnh đại diện chỉ chấp nhận JPG, PNG hoặc WebP.',
    );
  });

  it('giới hạn ảnh đại diện ở mức 2 MB', async () => {
    const service = new StorageService();
    const file = {
      originalname: 'avatar.png',
      mimetype: 'image/png',
      buffer: Buffer.alloc(0),
      size: 2 * 1024 * 1024 + 1,
    } as Express.Multer.File;

    await expect(service.upload(file, 'resident-1', 'avatar')).rejects.toThrow(
      'Ảnh đại diện không được vượt quá 2 MB.',
    );
  });
});
