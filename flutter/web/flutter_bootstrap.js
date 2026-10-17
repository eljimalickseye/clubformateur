// ============================================================================
// Club des Formateurs - Custom Bootstrap Loader
// Optimisé pour la compatibilité iOS Safari (WebKit), Android et Desktop
// ============================================================================

// 1. Polyfill et sécurisation WebAssembly pour Safari iOS
(function() {
  if (typeof WebAssembly !== 'undefined') {
    var origCompile = WebAssembly.compileStreaming;
    if (origCompile) {
      WebAssembly.compileStreaming = async function(responsePromise) {
        try {
          return await origCompile(responsePromise);
        } catch (err) {
          console.warn('[CF Web] compileStreaming non supporté ou échoué sur Safari iOS, repli sur ArrayBuffer:', err);
          var resp = await responsePromise;
          var bytes = await resp.arrayBuffer();
          return await WebAssembly.compile(bytes);
        }
      };
    }
    var origInstantiate = WebAssembly.instantiateStreaming;
    if (origInstantiate) {
      WebAssembly.instantiateStreaming = async function(responsePromise, importObject) {
        try {
          return await origInstantiate(responsePromise, importObject);
        } catch (err) {
          console.warn('[CF Web] instantiateStreaming non supporté ou échoué sur Safari iOS, repli sur ArrayBuffer:', err);
          var resp = await responsePromise;
          var bytes = await resp.arrayBuffer();
          return await WebAssembly.instantiate(bytes, importObject);
        }
      };
    }
  }
})();

{{flutter_js}}
{{flutter_build_config}}

// 2. Démarrage résilient avec gestion des limites WebGL et CPU Fallback
(function() {
  var isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) || 
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  var isWebKit = /WebKit/.test(navigator.userAgent) && !/Chrome|CriOS|Edg/.test(navigator.userAgent);

  console.log('[CF Web] Détection environnement : iOS=' + isIOS + ', WebKit=' + isWebKit);

  // Sur iOS Safari, limiter les surfaces à 6 évite l'épuisement mémoire du GPU WebKit
  var engineConfig = {
    canvasKitMaximumSurfaces: (isIOS || isWebKit) ? 6 : 16
  };

  _flutter.loader.load({
    config: engineConfig,
    onEntrypointLoaded: async function(engineInitializer) {
      try {
        console.log('[CF Web] Initialisation du moteur Flutter Web...');
        var appRunner;
        try {
          appRunner = await engineInitializer.initializeEngine(engineConfig);
        } catch (webglErr) {
          console.warn('[CF Web] Erreur WebGL CanvasKit, bascule automatique sur CPU fallback:', webglErr);
          appRunner = await engineInitializer.initializeEngine({
            canvasKitMaximumSurfaces: 4,
            canvasKitForceCpuOnly: true
          });
        }

        console.log('[CF Web] Démarrage de l\'application...');
        await appRunner.runApp();
        console.log('[CF Web] Application lancée avec succès.');

        // Sécurité supplémentaire : s'assurer que le splash est masqué une fois runApp terminé
        setTimeout(function() {
          if (typeof window.removeSplash === 'function') {
            window.removeSplash();
          }
        }, 1000);
      } catch (fatalErr) {
        console.error('[CF Web] Erreur fatale au démarrage:', fatalErr);
        if (typeof window.showStartupError === 'function') {
          window.showStartupError(fatalErr);
        }
      }
    }
  }).catch(function(loaderErr) {
    console.error('[CF Web] Erreur du chargeur Flutter:', loaderErr);
    if (typeof window.showStartupError === 'function') {
      window.showStartupError(loaderErr);
    }
  });
})();
