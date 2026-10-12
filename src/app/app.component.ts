import { Component, OnInit, inject, signal } from '@angular/core';
import { RouterOutlet, Router, NavigationEnd, NavigationStart } from '@angular/router';
import { Store } from '@ngrx/store';
import { CommonModule } from '@angular/common';
import { NavbarComponent } from './shared/components/navbar/navbar.component';
import { FooterComponent } from './shared/components/footer/footer.component';
import { LoadingBarComponent } from './shared/components/loading-bar/loading-bar.component';
import { authActions } from './store/auth/auth.actions';
import { distinctUntilChanged } from 'rxjs';

import { PwaNavigationComponent } from './shared/components/pwa-navigation/pwa-navigation.component';
import { ProfileCompletionModalComponent } from './shared/components/profile-completion-modal/profile-completion-modal.component';
import { PresenceService } from './core/services/presence.service';
import { selectCurrentUser } from './store/auth/auth.selectors';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    RouterOutlet, NavbarComponent, FooterComponent, LoadingBarComponent,
    CommonModule, PwaNavigationComponent, ProfileCompletionModalComponent
  ],
  template: `
    <app-loading-bar />
    @if (!isWorkspaceRoute()) {
      <app-navbar />
      <main class="min-h-screen bg-slate-50 text-slate-900 font-body pt-20 pb-20 md:pb-0">
        <router-outlet />
      </main>
      <app-footer />
    } @else {
      <main class="min-h-screen bg-slate-50 text-slate-900 font-body pb-20 md:pb-0">
        <router-outlet />
      </main>
    }
    <app-pwa-navigation />
    <app-profile-completion-modal />
  `,
})
export class AppComponent implements OnInit {
  private store = inject(Store);
  private router = inject(Router);
  private presenceService = inject(PresenceService);

  isWorkspaceRoute = signal(false);
  private lastPath = '';

  ngOnInit(): void {
    this.store.dispatch(authActions.initAuth());

    // N'initialise la présence que lorsque l'utilisateur connecté change réellement
    // (et non à chaque mise à jour du profil) → évite les écritures Firestore et écouteurs en double.
    this.store.select(selectCurrentUser).pipe(
      distinctUntilChanged((a, b) => (a?.uid ?? null) === (b?.uid ?? null))
    ).subscribe(user => {
      this.presenceService.initPresence(user);
    });

    this.checkRoute(this.router.url);
    this.lastPath = this.pathOf(this.router.url);

    let lastTrigger: string = 'imperative';
    this.router.events.subscribe(event => {
      if (event instanceof NavigationStart) {
        lastTrigger = event.navigationTrigger ?? 'imperative';
        return;
      }
      if (!(event instanceof NavigationEnd)) return;

      const url = event.urlAfterRedirects || event.url;
      this.checkRoute(url);

      // Remonte instantanément en haut de page quand on change de page
      // (pas lors d'un simple changement de filtres/query params, ni sur « retour » où le navigateur restaure la position).
      const path = this.pathOf(url);
      if (path !== this.lastPath && lastTrigger !== 'popstate') {
        window.scrollTo({ top: 0, left: 0, behavior: 'instant' as ScrollBehavior });
      }
      this.lastPath = path;
    });
  }

  private pathOf(url: string): string {
    return (url || '').split(/[?#]/)[0];
  }

  private checkRoute(url: string): void {
    const isCustomLayout = url.startsWith('/teacher') ||
                           url.startsWith('/student') ||
                           url.startsWith('/admin') ||
                           url.startsWith('/learn') ||
                           url.startsWith('/auth');
    // Évite une détection de changement inutile si la valeur ne change pas
    if (this.isWorkspaceRoute() !== isCustomLayout) {
      this.isWorkspaceRoute.set(isCustomLayout);
    }
  }
}
