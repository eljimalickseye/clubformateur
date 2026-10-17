// ============================================================================
// Club des Formateurs - Self-Destructing Service Worker
// Désenregistre automatiquement tout ancien service worker et vide les caches
// ============================================================================

self.addEventListener('install', function(e) {
  self.skipWaiting();
});

self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.map(function(k) {
          return caches.delete(k);
        })
      );
    }).then(function() {
      return self.registration.unregister();
    }).then(function() {
      return self.clients.matchAll({ type: 'window' });
    }).then(function(clients) {
      clients.forEach(function(client) {
        if (client.url && 'navigate' in client) {
          client.navigate(client.url);
        }
      });
    })
  );
});

self.addEventListener('fetch', function(e) {
  // Pas d'interception de cache : laisser le réseau répondre directement
  return;
});
