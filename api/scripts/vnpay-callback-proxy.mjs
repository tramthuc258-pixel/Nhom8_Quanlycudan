import { createServer } from 'node:http';

const port = Number(process.env.VNPAY_CALLBACK_PROXY_PORT ?? 3001);
const apiOrigin = 'http://127.0.0.1:3000';
const allowedPaths = new Set([
  '/api/payments/vnpay/ipn',
  '/api/payments/vnpay/return',
]);

createServer(async (request, response) => {
  if (request.method !== 'GET' || !request.url || request.url.length > 8192) {
    response.writeHead(404).end();
    return;
  }

  const url = new URL(request.url, 'http://localhost');
  if (
    !allowedPaths.has(url.pathname) ||
    !url.searchParams.has('vnp_SecureHash') ||
    [...url.searchParams.keys()].some(
      (key) => !key.startsWith('vnp_') || url.searchParams.getAll(key).length > 1,
    )
  ) {
    response.writeHead(404).end();
    return;
  }

  try {
    const upstream = await fetch(`${apiOrigin}${url.pathname}${url.search}`, {
      signal: AbortSignal.timeout(10_000),
    });
    response.writeHead(upstream.status, {
      'content-type':
        upstream.headers.get('content-type') ?? 'application/octet-stream',
      'cache-control': 'no-store',
    });
    response.end(Buffer.from(await upstream.arrayBuffer()));
  } catch {
    response.writeHead(502, { 'content-type': 'text/plain; charset=utf-8' });
    response.end('Homie API is unavailable.');
  }
}).listen(port, '127.0.0.1', () => {
  process.stdout.write(`VNPAY callback proxy listening on 127.0.0.1:${port}\n`);
});
