// 是甜姐呀 PWA Service Worker
const CACHE = 'tianjie-v3';
const ASSETS = [
  './',
  './index.html',
  './pages/home.html',
  './pages/diet.html',
  './pages/skincare.html',
  './pages/fitness.html',
  './pages/shaping.html',
  './pages/finance.html',
  './pages/stocks.html',
  './pages/english.html',
  './pages/mood.html',
  './pages/install.html',
  './manifest.json',
  './assets/app-icon-512.jpg',
  './assets/app-splash.jpg'
];

self.addEventListener('install', (e) => {
  self.skipWaiting();
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)).catch(() => {}));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  // 网络优先，失败回退缓存（保证联网标识生效时拿实时数据）
  e.respondWith(
    fetch(req)
      .then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
        return res;
      })
      .catch(() => caches.match(req).then((r) => r || caches.match('./pages/home.html')))
  );
});
