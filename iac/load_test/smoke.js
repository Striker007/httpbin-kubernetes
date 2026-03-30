import http from 'k6/http';
import { check, group } from 'k6';

export const options = {
  vus: 1,
  iterations: 1,
  thresholds: {
    http_req_failed:   ['rate<0.01'],        // <1% errors
    http_req_duration: ['p(95)<500'],        // 95th percentile < 500ms
    checks:            ['rate==1.0'],        // all checks must pass
  },
};

const BASE = __ENV.BASE_URL || 'http://httpbin.httpbin-production';

export default function () {
  group('basic response', () => {
    const res = http.get(`${BASE}/get`);
    check(res, {
      'status is 200':      (r) => r.status === 200,
      'has Content-Type':   (r) => r.headers['Content-Type'].includes('application/json'),
      'has url field':      (r) => r.json('url') !== undefined,
    });
  });

  group('status codes', () => {
    const params = { responseCallback: http.expectedStatuses({ min: 100, max: 599 }) };
    check(http.get(`${BASE}/status/200`, params), { '200 ok':       (r) => r.status === 200 });
    check(http.get(`${BASE}/status/404`, params), { '404 not found': (r) => r.status === 404 });
    check(http.get(`${BASE}/status/503`, params), { '503 error':    (r) => r.status === 503 });
  });

  // group('request inspection', () => {
  //   const res = http.get(`${BASE}/headers`, { headers: { 'X-Smoke-Test': 'k6' } });
  //   check(res, {
  //     'headers status 200':     (r) => r.status === 200,
  //     'echo X-Smoke-Test header': (r) => {
  //       const h = r.json('headers') || {};
  //       const key = Object.keys(h).find(k => k.toLowerCase() === 'x-smoke-test');
  //       // kennethreitz/httpbin returns flat strings; go-httpbin returns arrays
  //       const val = Array.isArray(h[key]) ? h[key][0] : h[key];
  //       return val === 'k6';
  //     },
  //   });
  // });
}
