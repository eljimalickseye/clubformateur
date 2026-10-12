import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule, Location } from '@angular/common';
import { Router, RouterLink, RouterLinkActive, NavigationEnd } from '@angular/router';
import { Store } from '@ngrx/store';
import { filter } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { PwaService } from '../../../core/services/pwa.service';

@Component({
  selector: 'app-pwa-navigation',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  template: `
    <!-- PWA Bottom Navigation Bar for Mobile / PWA App -->
    @if (showBottomBar()) {
      <nav class="fixed bottom-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-xl border-t border-slate-200/90 shadow-[0_-4px_20px_rgba(0,0,0,0.06)] md:hidden transition-all duration-300 pb-[env(safe-area-inset-bottom,0px)]">
        <div class="max-w-md mx-auto px-2 h-16 flex items-center justify-around">
          
          <!-- Non-connected Guest Navigation -->
          @if (!(user$ | async)) {
            <!-- 1. Accueil -->
            <a routerLink="/"
               [routerLinkActiveOptions]="{ exact: true }"
               routerLinkActive="text-primary font-extrabold"
               class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
              <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1-1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
              </svg>
              <span class="text-[10px] mt-1 font-semibold tracking-tight">Accueil</span>
            </a>

            <!-- 2. Catalogue -->
            <a routerLink="/catalogue"
               routerLinkActive="text-primary font-extrabold"
               class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
              <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="7" height="7" rx="1.5"/>
                <rect x="14" y="3" width="7" height="7" rx="1.5"/>
                <rect x="14" y="14" width="7" height="7" rx="1.5"/>
                <rect x="3" y="14" width="7" height="7" rx="1.5"/>
              </svg>
              <span class="text-[10px] mt-1 font-semibold tracking-tight">Catalogue</span>
            </a>

            <!-- 3. Formateurs -->
            <a routerLink="/formateurs"
               routerLinkActive="text-primary font-extrabold"
               class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
              <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
              <span class="text-[10px] mt-1 font-semibold tracking-tight">Formateurs</span>
            </a>

            <!-- 4. Connexion -->
            <a routerLink="/auth/login"
               routerLinkActive="text-primary font-extrabold"
               class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
              <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1"/>
              </svg>
              <span class="text-[10px] mt-1 font-semibold tracking-tight">Connexion</span>
            </a>

            <!-- 5. Inscription -->
            <a routerLink="/auth/register"
               routerLinkActive="text-primary font-extrabold"
               class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
              <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"/>
              </svg>
              <span class="text-[10px] mt-1 font-semibold tracking-tight">S'inscrire</span>
            </a>
          } @else {
            <!-- Connected User Navigation -->
            @if (user$ | async; as user) {
              <!-- 1. Accueil -->
              <a routerLink="/"
                 [routerLinkActiveOptions]="{ exact: true }"
                 routerLinkActive="text-primary font-extrabold"
                 class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
                <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1-1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                </svg>
                <span class="text-[10px] mt-1 font-semibold tracking-tight">Accueil</span>
              </a>

              <!-- 2. Catalogue -->
              <a routerLink="/catalogue"
                 routerLinkActive="text-primary font-extrabold"
                 class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
                <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <rect x="3" y="3" width="7" height="7" rx="1.5"/>
                  <rect x="14" y="3" width="7" height="7" rx="1.5"/>
                  <rect x="14" y="14" width="7" height="7" rx="1.5"/>
                  <rect x="3" y="14" width="7" height="7" rx="1.5"/>
                </svg>
                <span class="text-[10px] mt-1 font-semibold tracking-tight">Catalogue</span>
              </a>

              <!-- 3. Dashboard Central Button -->
              <a [routerLink]="'/' + user.role + '/dashboard'"
                 routerLinkActive="text-primary font-extrabold"
                 class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group relative">
                <div class="w-9 h-9 -mt-3 rounded-full bg-primary text-white flex items-center justify-center shadow-lg shadow-primary/30 group-active:scale-95 transition-transform">
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/>
                  </svg>
                </div>
                <span class="text-[10px] mt-0.5 font-bold tracking-tight">Espace</span>
              </a>

              <!-- 4. Lives -->
              <a [routerLink]="user.role === 'teacher' ? '/teacher/lives' : '/student/lives'"
                 routerLinkActive="text-red-500 font-extrabold"
                 class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-red-500 transition-all active:scale-90 select-none group">
                <div class="relative">
                  <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <polygon points="23 7 16 12 23 17 23 7"></polygon>
                    <rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect>
                  </svg>
                  <span class="absolute -top-0.5 -right-0.5 w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                </div>
                <span class="text-[10px] mt-1 font-semibold tracking-tight">{{ user.role === 'teacher' ? 'Studio' : 'Lives' }}</span>
              </a>

              <!-- 5. Mes Cours / Devoirs -->
              <a [routerLink]="user.role === 'teacher' ? '/teacher/assignments' : '/student/my-courses'"
                 routerLinkActive="text-primary font-extrabold"
                 class="flex flex-col items-center justify-center flex-1 py-1 text-slate-500 hover:text-primary transition-all active:scale-90 select-none group">
                <svg class="w-5 h-5 transition-transform group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"/>
                </svg>
                <span class="text-[10px] mt-1 font-semibold tracking-tight">{{ user.role === 'teacher' ? 'Devoirs' : 'Mes cours' }}</span>
              </a>
            }
          }

        </div>
      </nav>
    }
  `
})
export class PwaNavigationComponent implements OnInit {
  private store = inject(Store);
  private router = inject(Router);
  private location = inject(Location);
  pwaService = inject(PwaService);

  user$ = this.store.select(selectCurrentUser);
  currentUrl = signal<string>('');
  showBottomBar = signal<boolean>(true);

  ngOnInit(): void {
    this.checkRoute(this.router.url);
    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe((event: any) => {
      this.checkRoute(event.urlAfterRedirects || event.url);
    });
  }

  private checkRoute(url: string): void {
    this.currentUrl.set(url);
    // Hide bottom bar in full-screen player or live room or auth to keep clean view
    const isFullscreenMedia = url.startsWith('/learn') || 
                              url.startsWith('/student/live/') ||
                              url.startsWith('/teacher/chat') ||
                              url.startsWith('/auth');
    this.showBottomBar.set(!isFullscreenMedia);
  }

  refreshPage(): void {
    window.location.reload();
  }
}
