import { Controller, Get, Header, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { VnpayService } from './vnpay.service';

type VnpayQuery = Record<string, string | string[] | undefined>;

@ApiTags('Thanh toán VNPAY')
@Controller('payments/vnpay')
export class VnpayController {
  constructor(private readonly vnpay: VnpayService) {}

  @Get('ipn')
  @ApiOperation({ summary: 'IPN công khai để VNPAY xác nhận giao dịch' })
  async ipn(@Query() query: VnpayQuery): Promise<object> {
    const { RspCode, Message } = await this.vnpay.processCallback(query);
    return { RspCode, Message };
  }

  @Get('return')
  @Header('content-type', 'text/html; charset=utf-8')
  @ApiOperation({ summary: 'Trang kết quả được VNPAY chuyển hướng về' })
  async returnPage(@Query() query: VnpayQuery): Promise<string> {
    const result = await this.vnpay.processReturn(query);
    return this.vnpay.renderReturnPage(result);
  }
}
