import { Injectable, inject, signal, PLATFORM_ID } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';
import { SwUpdate, VersionReadyEvent } from '@angular/service-worker';
import { ToastrService } from 'ngx-toastr';
import { filter } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class PwaService {
  private platformId = inject(PLATFORM_ID);
  private swUpdate = inject(SwUpdate, { optional: true });
  private toastr = inject(ToastrService);

  private deferredPrompt: any = null;
  
  isInstallable = signal<boolean>(false);
  isInstalled = signal<boolean>(false);
  isOnline = signal<boolean>(true);
  updateAvailable = signal<boolean>(false);

  constructor() {
    if (isPlatformBrowser(this.platformId)) {
      this.checkInstallationState();
      this.initInstallPromptListener();
      this.initNetworkListeners();
      this.initUpdateListener();
    }
  }

  private checkInstallationState() {
    const isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as any).standalone === true;
    this.isInstalled.set(isStandalone);
  }

  private initInstallPromptListener() {
    window.addEventListener('beforeinstallprompt', (e: any) => {
      e.preventDefault();
      this.deferredPrompt = e;
      this.isInstallable.set(true);
    });

    window.addEventListener('appinstalled', () => {
      this.deferredPrompt = null;
      this.isInstallable.set(false);
      this.isInstalled.set(true);
      this.toastr.success('Application Club des Formateurs installée avec succès !');
    });
  }

  private initNetworkListeners() {
    this.isOnline.set(navigator.onLine);

    window.addEventListener('online', () => {
      this.isOnline.set(true);
      this.toastr.success('Connexion Internet rétablie.', 'En ligne');
    });

    window.addEventListener('offline', () => {
      this.isOnline.set(false);
      this.toastr.warning('Mode hors-ligne activé. Les données en cache restent disponibles.', 'Hors-ligne');
    });
  }

  private initUpdateListener() {
    if (!this.swUpdate?.isEnabled) return;

    this.swUpdate.versionUpdates
      .pipe(filter((evt): evt is VersionReadyEvent => evt.type === 'VERSION_READY'))
      .subscribe(() => {
        this.updateAvailable.set(true);
        this.toastr.info(
          'Une mise à jour est prête. Cliquez ici pour recharger.',
          'Mise à jour disponible',
          { timeOut: 8000 }
        );
      });
  }

  async installPwa(): Promise<boolean> {
    if (!this.deferredPrompt) {
      this.toastr.info("Sur iOS, appuyez sur le bouton Partager puis 'Sur l’écran d’accueil'.");
      return false;
    }

    this.deferredPrompt.prompt();
    const { outcome } = await this.deferredPrompt.userChoice;
    this.deferredPrompt = null;
    this.isInstallable.set(false);
    return outcome === 'accepted';
  }

  reloadForUpdate() {
    if (this.swUpdate?.isEnabled) {
      this.swUpdate.activateUpdate().then(() => document.location.reload());
    } else {
      document.location.reload();
    }
  }
}
