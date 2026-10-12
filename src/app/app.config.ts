import { ApplicationConfig, importProvidersFrom, isDevMode, ErrorHandler, Injectable, provideZoneChangeDetection } from '@angular/core';
import {
  provideRouter, withComponentInputBinding, withViewTransitions, withPreloading,
  RouterFeatures,
} from '@angular/router';
import { SmartPreloadingStrategy } from './core/services/smart-preloading.strategy';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { provideServiceWorker } from '@angular/service-worker';
import { initializeApp, provideFirebaseApp } from '@angular/fire/app';
import { getAuth, provideAuth, connectAuthEmulator } from '@angular/fire/auth';
import { getFirestore, provideFirestore, connectFirestoreEmulator } from '@angular/fire/firestore';
import { getStorage, provideStorage, connectStorageEmulator } from '@angular/fire/storage';
import { getFunctions, provideFunctions, connectFunctionsEmulator } from '@angular/fire/functions';
import { getMessaging, provideMessaging } from '@angular/fire/messaging';
import { getAnalytics, provideAnalytics, ScreenTrackingService, UserTrackingService } from '@angular/fire/analytics';
import { provideStore } from '@ngrx/store';
import { provideEffects } from '@ngrx/effects';
import { provideStoreDevtools } from '@ngrx/store-devtools';
import { provideToastr } from 'ngx-toastr';

import { routes } from './app.routes';
import { environment } from '../environments/environment';
import { authReducer } from './store/auth/auth.reducer';
import { AuthEffects } from './store/auth/auth.effects';
import { coursesReducer } from './store/courses/courses.reducer';
import { CoursesEffects } from './store/courses/courses.effects';
import { notificationsReducer } from './store/notifications/notifications.reducer';
import { authInterceptor } from './core/interceptors/auth.interceptor';
import { loadingInterceptor } from './core/interceptors/loading.interceptor';

@Injectable()
export class GlobalErrorHandler implements ErrorHandler {
  handleError(error: any): void {
    const chunkFailedMessage = /Loading chunk [\d]+ failed|Failed to fetch dynamically imported module|Importing a module script failed/i;
    const msg = error?.message || (typeof error === 'string' ? error : '');
    if (msg && chunkFailedMessage.test(msg)) {
      const now = Date.now();
      const lastReload = parseInt(sessionStorage.getItem('chunk_reload_ts') || '0', 10);
      if (now - lastReload > 8000) {
        sessionStorage.setItem('chunk_reload_ts', now.toString());
        console.warn('New deployment detected, reloading page to fetch latest version...');
        window.location.reload();
        return;
      }
    }
    console.error(error);
  }
}

/**
 * View Transitions capture a screenshot of the whole page on every navigation.
 * On iOS Safari (and touch devices in general) this is expensive and blocks
 * interactions while the animation runs → we only enable it on desktop.
 */
function routerFeatures(): RouterFeatures[] {
  const features: RouterFeatures[] = [
    withComponentInputBinding(),
    withPreloading(SmartPreloadingStrategy),
  ];
  const canUseViewTransitions =
    typeof window !== 'undefined' &&
    typeof window.matchMedia === 'function' &&
    window.matchMedia('(hover: hover) and (pointer: fine)').matches &&
    !window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (canUseViewTransitions) {
    features.push(withViewTransitions());
  }
  return features;
}

export const appConfig: ApplicationConfig = {
  providers: [
    // Regroupe les événements (click, input…) en un seul cycle de détection → moins de travail CPU
    provideZoneChangeDetection({ eventCoalescing: true, runCoalescing: true }),
    provideRouter(routes, ...routerFeatures()),
    provideHttpClient(withInterceptors([authInterceptor, loadingInterceptor])),
    provideAnimations(),

    // Firebase
    provideFirebaseApp(() => initializeApp(environment.firebase)),
    provideAuth(() => {
      const auth = getAuth();
      if (environment.emulators?.enabled) {
        connectAuthEmulator(auth, `http://localhost:${environment.emulators.authPort}`, { disableWarnings: true });
      }
      return auth;
    }),
    provideFirestore(() => {
      const firestore = getFirestore();
      if (environment.emulators?.enabled) {
        connectFirestoreEmulator(firestore, 'localhost', environment.emulators.firestorePort);
      }
      return firestore;
    }),
    provideStorage(() => {
      const storage = getStorage();
      if (environment.emulators?.enabled) {
        connectStorageEmulator(storage, 'localhost', environment.emulators.storagePort);
      }
      return storage;
    }),
    provideFunctions(() => {
      const functions = getFunctions();
      if (environment.emulators?.enabled) {
        connectFunctionsEmulator(functions, 'localhost', environment.emulators.functionsPort);
      }
      return functions;
    }),
    provideMessaging(() => getMessaging()),
    provideAnalytics(() => getAnalytics()),
    ScreenTrackingService,
    UserTrackingService,

    // NgRx Store
    provideStore({
      auth: authReducer,
      courses: coursesReducer,
      notifications: notificationsReducer,
    }),
    provideEffects([AuthEffects, CoursesEffects]),
    ...(environment.production ? [] : [provideStoreDevtools({ maxAge: 25, logOnly: false })]),

    // Service Worker (PWA)
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode() || environment.production,
      registrationStrategy: 'registerWhenStable:30000',
    }),

    // Toast notifications
    provideToastr({
      timeOut: 4000,
      positionClass: 'toast-bottom-right',
      preventDuplicates: true,
    }),

    // Global Chunk & Deployment Error Handler
    { provide: ErrorHandler, useClass: GlobalErrorHandler },
  ],
};
