const CACHE_NAME = 'jtech-fit-v1.0.0';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './manifest.json',
  './sw.js',
  './BUILD_GUIDE.md',
  'https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&display=swap'
];

// Instalação do Service Worker e Caching dos Recursos Estáticos
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[ServiceWorker] Pré-cache de arquivos estáticos concluído.');
      return cache.addAll(ASSETS_TO_CACHE);
    }).then(() => self.skipWaiting())
  );
});

// Ativação e Limpeza de Caches Antigos
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cache) => {
          if (cache !== CACHE_NAME) {
            console.log('[ServiceWorker] Removendo cache antigo:', cache);
            return caches.delete(cache);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Intercepção de Requisições Network com Estratégia Híbrida (Stale-While-Revalidate)
self.addEventListener('fetch', (event) => {
  // Ignorar requisições não GET ou extensões do navegador
  if (event.request.method !== 'GET' || !event.request.url.startsWith('http')) {
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      const fetchPromise = fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      }).catch((err) => {
        console.log('[ServiceWorker] Offline - Servindo do cache local:', err);
      });

      return cachedResponse || fetchPromise;
    })
  );
});

// Manipulador de Notificações em Segundo Plano (Rest Timer)
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      for (const client of clientList) {
        if (client.url === '/' && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
<<<<<<< HEAD
        return clients.openWindow('./index.html#active');
=======
        return clients.openWindow('./#active');
>>>>>>> 992c6cf (feat: adicionar configuracoes PWA Vercel, chaves Supabase e estrutura nativa mobile)
      }
    })
  );
});
