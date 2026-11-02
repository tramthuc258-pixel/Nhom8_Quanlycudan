import type { VnpayCallbackResult } from './vnpay.service';

const escapeHtml = (value: string): string =>
  value.replace(
    /[&<>'"]/g,
    (character) =>
      ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        "'": '&#39;',
        '"': '&quot;',
      })[character]!,
  );

export function renderVnpayReturnPage(result: VnpayCallbackResult): string {
  const state = result.successful
    ? 'success'
    : result.awaitingConfirmation
      ? 'waiting'
      : 'failed';
  const title =
    state === 'success'
      ? 'Thanh toán thành công'
      : state === 'waiting'
        ? 'Đang xác nhận thanh toán'
        : 'Thanh toán chưa hoàn tất';
  const subtitle =
    state === 'success'
      ? 'Giao dịch đã được ghi nhận. Cảm ơn bạn đã hoàn tất khoản phí căn hộ.'
      : state === 'waiting'
        ? 'VNPAY đã xử lý giao dịch. Homie đang chờ kết quả xác nhận cuối cùng.'
        : 'Giao dịch chưa thành công hoặc đã bị hủy. Bạn có thể quay lại để thử lại.';
  const badge =
    state === 'success'
      ? 'GIAO DỊCH THÀNH CÔNG'
      : state === 'waiting'
        ? 'ĐANG XÁC NHẬN'
        : 'GIAO DỊCH CHƯA HOÀN TẤT';
  const invoiceCode = escapeHtml(result.invoiceCode ?? 'Chưa xác định');
  const amount =
    result.amount == null
      ? null
      : new Intl.NumberFormat('vi-VN').format(result.amount);
  const appLink =
    'homie://payment-result' +
    (result.invoiceId
      ? `?invoiceId=${encodeURIComponent(result.invoiceId)}`
      : '');
  const symbol =
    state === 'success'
      ? '<path d="m15 29 9 9 20-21" />'
      : state === 'waiting'
        ? '<circle cx="30" cy="30" r="15" /><path d="M30 21v10l7 4" />'
        : '<path d="M22 22 38 38M38 22 22 38" />';

  return `<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#2467E8">
  <title>${title} · Homie</title>
  <style>
    :root{font-family:Inter,"Segoe UI",Arial,sans-serif;color:#1c2942;color-scheme:light}
    *{box-sizing:border-box}
    body{margin:0;min-height:100vh;background:#f5f8fe}
    body.success{--tone:#0e9270;--tone-soft:#e3f7f0;--tone-line:#bce8d9}
    body.waiting{--tone:#b86712;--tone-soft:#fff4e5;--tone-line:#f4dbb8}
    body.failed{--tone:#cc4b52;--tone-soft:#fff0f0;--tone-line:#f6d1d3}
    .hero{position:relative;overflow:hidden;min-height:258px;padding:30px max(24px,calc((100vw - 460px)/2));background:linear-gradient(128deg,#2058c7 0%,#2f6fed 52%,#13aeb9 100%);border-radius:0 0 36px 36px;color:#fff}
    .hero:before,.hero:after{content:"";position:absolute;border:1px solid #ffffff38;border-radius:50%;pointer-events:none}
    .hero:before{width:270px;height:270px;right:-80px;top:-126px;background:#ffffff12}
    .hero:after{width:170px;height:170px;left:-75px;bottom:-100px;background:#ffffff0d}
    .brand{position:relative;display:flex;align-items:center;gap:10px;font-size:19px;font-weight:900;letter-spacing:-.4px}
    .brand-mark{width:39px;height:39px;display:grid;place-items:center;border-radius:13px;background:#ffffff30;box-shadow:inset 0 0 0 1px #ffffff55}
    .brand-mark svg{width:23px;height:23px;fill:none;stroke:#fff;stroke-width:2.4;stroke-linecap:round;stroke-linejoin:round}
    .hero-caption{position:relative;margin-top:37px;font-size:12px;font-weight:700;letter-spacing:1.7px;text-transform:uppercase;color:#dceaff}
    .hero-title{position:relative;margin:7px 0 0;font-size:26px;font-weight:850;letter-spacing:-.7px}
    main{position:relative;width:min(calc(100% - 32px),428px);margin:-91px auto 0}
    .card{padding:26px 24px 24px;border:1px solid #e5ecf7;border-radius:30px;background:#fff;box-shadow:0 20px 56px #183f8324}
    .status-icon{width:78px;height:78px;display:grid;place-items:center;margin:0 auto 16px;border-radius:26px;background:var(--tone-soft);color:var(--tone);box-shadow:inset 0 0 0 1px var(--tone-line)}
    .status-icon svg{width:49px;height:49px;fill:none;stroke:currentColor;stroke-width:4;stroke-linecap:round;stroke-linejoin:round}
    .badge{width:max-content;max-width:100%;margin:0 auto;padding:8px 12px;border-radius:999px;background:var(--tone-soft);color:var(--tone);font-size:10px;font-weight:900;letter-spacing:1.1px;text-align:center}
    h1{margin:16px 0 8px;text-align:center;font-size:27px;line-height:1.2;letter-spacing:-.8px}
    .subtitle{max-width:335px;margin:0 auto;color:#6c7890;text-align:center;font-size:14px;line-height:1.6}
    .summary{margin-top:24px;padding:17px 18px;border:1px solid #e3ebf6;border-radius:20px;background:#f7faff}
    .amount-label{color:#74829a;font-size:12px;font-weight:650}
    .amount{margin-top:5px;color:#245ed6;font-size:29px;font-weight:900;letter-spacing:-.7px}
    .divider{height:1px;margin:15px 0;background:#e4ebf5}
    .detail{display:flex;justify-content:space-between;align-items:flex-start;gap:12px;font-size:13px;line-height:1.45}
    .detail+.detail{margin-top:11px}
    .detail span{color:#74829a}
    .detail strong{max-width:62%;text-align:right;overflow-wrap:anywhere;color:#263650;font-weight:750}
    .button{display:flex;align-items:center;justify-content:center;gap:10px;width:100%;min-height:54px;margin-top:22px;padding:12px 18px;border:0;border-radius:17px;background:linear-gradient(105deg,#2f6fed,#06b4c4);box-shadow:0 10px 22px #2f6fed35;color:#fff;font-size:15px;font-weight:800;text-align:center;text-decoration:none}
    .button:hover,.button:focus-visible{filter:brightness(.95)}
    .button svg{width:19px;height:19px;fill:none;stroke:currentColor;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round}
    .help{margin:14px 0 0;color:#8793a8;text-align:center;font-size:12px;line-height:1.5}
    footer{width:min(calc(100% - 32px),428px);margin:22px auto 28px;text-align:center;color:#8491a6;font-size:12px;line-height:1.5}
    @media(max-width:380px){.hero{padding-top:22px}.card{padding:23px 19px}h1{font-size:25px}.amount{font-size:27px}}
  </style>
</head>
<body class="${state}">
  <header class="hero">
    <div class="brand">
      <span class="brand-mark" aria-hidden="true"><svg viewBox="0 0 32 32"><path d="m4 15 12-10 12 10v12H4z"/><path d="M13 27v-9h6v9"/></svg></span>
      Homie
    </div>
    <div class="hero-caption">Thanh toán căn hộ</div>
    <div class="hero-title">Kết quả giao dịch</div>
  </header>
  <main>
    <section class="card" aria-live="polite">
      <div class="status-icon" aria-hidden="true"><svg viewBox="0 0 60 60">${symbol}</svg></div>
      <div class="badge">${badge}</div>
      <h1>${title}</h1>
      <p class="subtitle">${subtitle}</p>
      <div class="summary">
        ${amount == null ? '' : `<div class="amount-label">Số tiền giao dịch</div><div class="amount">${amount} đ</div><div class="divider"></div>`}
        <div class="detail"><span>Mã hóa đơn</span><strong>${invoiceCode}</strong></div>
        <div class="detail"><span>Phương thức</span><strong>VNPAY Sandbox</strong></div>
        <div class="detail"><span>Trạng thái</span><strong>${state === 'success' ? 'Đã thanh toán' : state === 'waiting' ? 'Chờ xác nhận' : 'Chưa thanh toán'}</strong></div>
      </div>
      <a class="button" id="return-home" href="${escapeHtml(appLink)}">
        Về Homie · Xem hóa đơn
        <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 12h15m-6-6 6 6-6 6"/></svg>
      </a>
      <p class="help">Nhấn nút để trở về ứng dụng và xem trạng thái hóa đơn.</p>
    </section>
  </main>
  <footer>Môi trường kiểm thử VNPAY · Không phát sinh tiền thật</footer>
</body>
</html>`;
}
