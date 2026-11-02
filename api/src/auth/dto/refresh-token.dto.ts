import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class RefreshTokenDto {
  @ApiProperty({
    description: 'Refresh token nhận được khi đăng nhập hoặc làm mới phiên.',
    example: '550e8400-e29b-41d4-a716-446655440000.secret-token',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^[0-9a-f-]{36}\.[A-Za-z0-9_-]+$/i, {
    message: 'Refresh token không đúng định dạng.',
  })
  refreshToken!: string;
}
