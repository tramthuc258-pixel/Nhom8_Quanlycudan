import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { CreateHousingInquiryDto } from './dto/create-housing-inquiry.dto';
import { HousingService } from './housing.service';

@ApiTags('Căn hộ công khai')
@Controller('public/housing')
export class PublicHousingController {
  constructor(private readonly housingService: HousingService) {}

  @Get('listings')
  @ApiOperation({
    summary: 'Danh sách căn hộ đang bán hoặc cho thuê cho khách',
    description:
      'API công khai, không yêu cầu đăng nhập và chỉ trả về bài đăng đang hoạt động.',
  })
  findListings(): Promise<object> {
    return this.housingService.findPublicListings();
  }

  @Post('inquiries')
  @ApiOperation({
    summary: 'Khách gửi thông tin quan tâm căn hộ',
    description:
      'Không cần tài khoản. Ban quản lý sẽ liên hệ lại qua số điện thoại hoặc email khách cung cấp.',
  })
  createInquiry(@Body() dto: CreateHousingInquiryDto): Promise<object> {
    return this.housingService.createPublicInquiry(dto);
  }
}
