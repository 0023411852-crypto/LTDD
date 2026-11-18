import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// --- Custom Metrics (Grafana k6 Standard) ---
const errorRate = new Rate('custom_error_rate');
const weatherDuration = new Trend('weather_duration_ms');
const rssDuration = new Trend('rss_duration_ms');
const geocodeDuration = new Trend('geocode_duration_ms');

// --- Test Configuration & Ramp-up Stages ---
export const options = {
  stages: [
    { duration: '30s', target: 10 }, // Stage 1: Warm-up (10 Virtual Users)
    { duration: '1m', target: 30 },  // Stage 2: Peak load (30 Concurrent Users)
    { duration: '30s', target: 50 }, // Stage 3: Stress test burst (50 Concurrent Users)
    { duration: '30s', target: 0 },  // Stage 4: Ramp-down / Cool-down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<600'], // 95% of requests must complete under 600ms
    'custom_error_rate': ['rate<0.02'], // Failure rate strictly below 2%
    'weather_duration_ms': ['p(90)<500'],
    'rss_duration_ms': ['p(90)<800'],
  },
};

const HEADERS = {
  'User-Agent': 'DailyNewsWeather-k6-LoadTest/1.0 (k6 load testing client)',
  'Accept': 'application/json, text/xml, application/xml',
};

export default function () {
  // Scenario 1: Weather Forecast Query (Open-Meteo)
  group('Weather Forecast API', () => {
    const lat = 21.0285;
    const lon = 105.8542;
    const weatherUrl = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Asia%2FBangkok&forecast_days=7`;

    const res = http.get(weatherUrl, { headers: HEADERS });
    weatherDuration.add(res.timings.duration);

    const success = check(res, {
      'weather status is 200': (r) => r.status === 200,
      'weather payload has current temperature': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body && body.current && body.current.temperature_2m !== undefined;
        } catch (_) {
          return false;
        }
      },
    });

    errorRate.add(!success);
  });

  sleep(1);

  // Scenario 2: Geocoding Search (Open-Meteo Geocoding)
  group('Geocoding Location Search API', () => {
    const query = encodeURIComponent('Đà Nẵng');
    const geoUrl = `https://geocoding-api.open-meteo.com/v1/search?name=${query}&count=5&language=vi&format=json`;

    const res = http.get(geoUrl, { headers: HEADERS });
    geocodeDuration.add(res.timings.duration);

    const success = check(res, {
      'geocoding status is 200': (r) => r.status === 200,
      'geocoding returns results array': (r) => {
        try {
          const body = JSON.parse(r.body);
          return Array.isArray(body.results);
        } catch (_) {
          return false;
        }
      },
    });

    errorRate.add(!success);
  });

  sleep(1);

  // Scenario 3: RSS Feed Aggregation (VnExpress & Tuoi Tre)
  group('RSS News Aggregator Feed', () => {
    const rssUrls = [
      'https://vnexpress.net/rss/tin-moi-nhat.rss',
      'https://tuoitre.vn/rss/tin-moi-nhat.rss',
    ];
    const targetUrl = rssUrls[Math.floor(Math.random() * rssUrls.length)];

    const res = http.get(targetUrl, { headers: HEADERS });
    rssDuration.add(res.timings.duration);

    const success = check(res, {
      'rss feed status is 200': (r) => r.status === 200,
      'rss feed has valid xml content': (r) => r.body && r.body.includes('<rss') && r.body.includes('<item>'),
    });

    errorRate.add(!success);
  });

  sleep(1);
}
