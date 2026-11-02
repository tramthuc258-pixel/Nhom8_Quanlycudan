import { renderVnpayReturnPage } from './vnpay-return-page';

describe('VNPAY return page', () => {
  it('hiển thị hóa đơn và liên kết mở lại Homie sau thanh toán', () => {
    const html = renderVnpayReturnPage({
      RspCode: '00',
      Message: 'Confirm success',
      successful: true,
      invoiceId: '72000000-0000-4000-8000-000000000001',
      invoiceCode: 'HD-202610-INIT01',
      amount: 1384000,
    });

    expect(html).toContain('Thanh toán thành công');
    expect(html).toContain('1.384.000 đ');
    expect(html).toContain('Về Homie · Xem hóa đơn');
    expect(html).toContain(
      'homie://payment-result?invoiceId=72000000-0000-4000-8000-000000000001',
    );
    expect(html).toContain('Nhấn nút để trở về ứng dụng');
  });

  it('ẩn dữ liệu hóa đơn không an toàn khỏi HTML', () => {
    const html = renderVnpayReturnPage({
      RspCode: '97',
      Message: 'Invalid checksum',
      successful: false,
      invoiceCode: '<img src=x onerror=alert(1)>',
    });

    expect(html).not.toContain('<img src=x onerror=alert(1)>');
    expect(html).toContain('&lt;img src=x onerror=alert(1)&gt;');
    expect(html).not.toContain('data-auto-open');
  });
});
