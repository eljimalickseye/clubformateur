import { Component, inject, OnInit } from '@angular/core';
import { Title, Meta } from '@angular/platform-browser';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { AsyncPipe } from '@angular/common';
import { CourseCardComponent } from '../../shared/components/course-card/course-card.component';
import { coursesActions } from '../../store/courses/courses.actions';
import { selectFeaturedCourses, selectCoursesLoading } from '../../store/courses/courses.reducer';
import { LivekitService } from '../../core/services/livekit.service';
import { LiveSession } from '../../core/models';
import { signal } from '@angular/core';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [RouterLink, AsyncPipe, CourseCardComponent],
  template: `
    <!-- Hero Section -->
    <section class="relative min-h-screen flex flex-col justify-center overflow-hidden bg-dark pt-20">
      <!-- Ambient Background Glows -->
      <div class="absolute top-10 left-1/4 w-[600px] h-[600px] bg-primary/10 rounded-full blur-[120px] opacity-60"></div>
      <div class="absolute bottom-20 right-1/4 w-[500px] h-[500px] bg-sky-400/10 rounded-full blur-[120px] opacity-50"></div>
      
      <!-- Subtle Pattern Overlay -->
      <div class="absolute inset-0 opacity-[0.03]" style="background-image: url('data:image/svg+xml,%3Csvg width=\\'60\\' height=\\'60\\' viewBox=\\'0 0 60 60\\' xmlns=\\'http://www.w3.org/2000/svg\\'%3E%3Cg fill=\\'none\\' fill-rule=\\'evenodd\\'%3E%3Cg fill=\\'%232563EB\\' fill-opacity=\\'1\\'%3E%3Cpath d=\\'M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z\\'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E');"></div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 w-full">
        
        <!-- DYNAMIC LIVE BANNER -->
        @if (activeLives().length > 0) {
          <div class="mb-8 p-4 sm:p-5 rounded-3xl bg-gradient-to-r from-red-600 via-rose-600 to-red-700 text-white shadow-xl shadow-red-600/20 flex flex-col sm:flex-row items-center justify-between gap-4 animate-bounce-short">
            <div class="flex items-center gap-3.5">
              <span class="flex h-3.5 w-3.5 relative">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3.5 w-3.5 bg-white"></span>
              </span>
              <div>
                <div class="flex items-center gap-2">
                  <span class="px-2 py-0.5 rounded-full bg-black/30 text-[10px] font-black uppercase tracking-wider">
                    🔴 EN DIRECT MAINTENANT
                  </span>
                  <span class="text-xs font-bold text-red-100">
                    {{ activeLives()[0].teacherName }}
                  </span>
                </div>
                <h2 class="font-display text-sm sm:text-base font-extrabold text-white mt-0.5">
                  {{ activeLives()[0].title }} ({{ activeLives()[0].courseName }})
                </h2>
              </div>
            </div>

            <a [routerLink]="['/student/live', activeLives()[0].id]"
               class="px-5 py-2.5 bg-white hover:bg-slate-100 text-red-600 font-black text-xs rounded-2xl shadow-lg transition-all active:scale-95 flex items-center gap-2 shrink-0">
              <span>Rejoindre le Live</span>
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
              </svg>
            </a>
          </div>
        }

        <div class="grid lg:grid-cols-2 gap-12 items-center">
          
          <!-- Left Content -->
          <div class="flex flex-col items-start text-left space-y-8 animate-fade-in">
            <!-- Badge -->
            <div class="inline-flex items-center gap-2 px-4 py-2 rounded-full border border-primary/20 bg-white/60 backdrop-blur-md text-primary text-sm font-semibold shadow-sm transform hover:scale-105 transition-transform cursor-default">
              <span class="w-2.5 h-2.5 bg-primary rounded-full animate-pulse shadow-[0_0_8px_rgba(37,99,235,0.4)]"></span>
              L'avenir de la formation en ligne
            </div>

            <!-- Main Title -->
            <h1 class="font-display text-5xl sm:text-7xl font-extrabold text-light leading-[1.05] tracking-tight">
              Apprenez avec les <br />
              <span class="text-transparent bg-clip-text bg-gradient-to-r from-primary via-sky-500 to-primary">Meilleurs Formateurs</span> <br />
              et Experts
            </h1>

            <!-- Subtitle -->
            <p class="text-light-muted text-lg sm:text-xl max-w-xl leading-relaxed">
              La plateforme de référence pour développer vos compétences. Formations professionnelles, cours certifiants, directs interactifs et entraide entre apprenants.
            </p>

            <!-- CTA Buttons -->
            <div class="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto pt-4">
              <a routerLink="/catalogue"
                 class="group relative w-full sm:w-auto px-10 py-5 bg-primary text-white font-bold text-lg rounded-2xl overflow-hidden transition-all hover:scale-105 hover:shadow-card-hover">
                <span class="relative z-10 flex items-center justify-center gap-3">
                  Explorer les cours
                  <svg class="w-6 h-6 group-hover:translate-x-1 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M13 7l5 5m0 0l-5 5m5-5H6" />
                  </svg>
                </span>
                <div class="absolute inset-0 bg-white/20 transform -skew-x-12 -translate-x-full group-hover:translate-x-full transition-transform duration-700 ease-out"></div>
              </a>
              
              <a routerLink="/auth/register"
                 class="group w-full sm:w-auto px-10 py-5 border-2 border-dark-border bg-white/80 backdrop-blur-md text-light font-bold text-lg rounded-2xl hover:bg-white hover:border-primary/40 transition-all flex items-center justify-center gap-2">
                Commencer maintenant
              </a>
            </div>

            <!-- Floating Stats (Mini) -->
            <div class="flex flex-wrap gap-8 pt-8">
              <div class="flex flex-col">
                <span class="text-3xl font-black text-light leading-none">5K+</span>
                <span class="text-sm font-bold text-primary uppercase tracking-widest mt-1">Étudiants</span>
              </div>
              <div class="w-px h-10 bg-dark-border hidden sm:block"></div>
              <div class="flex flex-col">
                <span class="text-3xl font-black text-light leading-none">120+</span>
                <span class="text-sm font-bold text-primary uppercase tracking-widest mt-1">Formations</span>
              </div>
            </div>
          </div>

          <!-- Right Content: Mockup -->
          <div class="relative flex justify-center items-center animate-slide-up">
            <!-- Decorative Background Element -->
            <div class="absolute w-[120%] h-[120%] bg-gradient-to-br from-primary/10 to-transparent rounded-full blur-[80px] -z-10"></div>
            
            <!-- Phone Image -->
            <div class="relative z-20 transform hover:scale-[1.02] transition-transform duration-500">
              <img loading="lazy" decoding="async" src="assets/anour-mockup.png" 
                   alt="Anour Mobile App" 
                   class="max-w-[320px] sm:max-w-[420px] h-auto drop-shadow-[0_25px_50px_rgba(0,0,0,0.15)] rounded-[48px]" />
              
              <!-- Floating Card 1 -->
              <div class="absolute -top-6 -right-12 sm:-right-16 bg-white/90 backdrop-blur-xl p-4 rounded-2xl shadow-xl border border-white/50 animate-bounce-slow hidden sm:block">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center text-emerald-600">
                    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-[10px] uppercase font-bold text-light-muted">Inscription</div>
                    <div class="text-sm font-bold text-light">+1 Nouveau participant</div>
                  </div>
                </div>
              </div>

              <!-- Floating Card 2 -->
              <div class="absolute bottom-12 -left-12 sm:-left-20 bg-white/90 backdrop-blur-xl p-4 rounded-2xl shadow-xl border border-white/50 animate-float hidden sm:block">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center text-primary">
                    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                  </div>
                  <div>
                    <div class="text-[10px] uppercase font-bold text-light-muted">Direct</div>
                    <div class="text-sm font-bold text-light">Session Live en cours</div>
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </div>
      
      <!-- Bottom fade -->
      <div class="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-dark-surface to-transparent"></div>
    </section>

    <!-- Categories Section -->
    <section class="py-32 px-4 bg-dark-surface relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col md:flex-row items-end justify-between mb-16 gap-6">
          <div class="max-w-2xl">
            <h2 class="font-display text-4xl sm:text-5xl font-extrabold text-light mb-4">Parcourez par catégorie</h2>
            <p class="text-light-muted text-lg">Trouvez la discipline qui vous passionne parmi nos programmes d'excellence.</p>
          </div>
          <a routerLink="/catalogue" class="text-primary font-bold flex items-center gap-2 group">
            Tout voir 
            <span class="group-hover:translate-x-1 transition-transform">→</span>
          </a>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-6">
          @for (cat of categories; track cat.name) {
            <a routerLink="/catalogue" [queryParams]="{category: cat.name}" 
               class="group flex flex-col items-center p-8 rounded-3xl border border-dark-border bg-white hover:border-primary/30 hover:shadow-card-hover transition-all duration-500">
              <div class="w-20 h-20 rounded-2xl bg-dark-surface2 group-hover:bg-primary/10 flex items-center justify-center text-primary mb-6 transition-all duration-500 group-hover:scale-110 group-hover:rotate-3">
                @switch (cat.name) {
                  @case ('Business') {
                    <svg class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                  }
                  @case ('Développement') {
                    <svg class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" /></svg>
                  }
                  @case ('Design') {
                    <svg class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" /></svg>
                  }
                  @case ('Langues') {
                    <svg class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 11.37 9.188 16.5 5 20.5" /></svg>
                  }
                  @case ('Marketing') {
                    <svg class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" /></svg>
                  }
                  @case ('Coaching') {
                    <svg class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" /></svg>
                  }
                }
              </div>
              <h3 class="font-bold text-light text-center group-hover:text-primary transition-colors">{{ cat.name }}</h3>
            </a>
          }
        </div>
      </div>
    </section>

    <!-- Features Section -->
    <section class="py-32 px-4 bg-dark border-y border-dark-border">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="text-center max-w-3xl mx-auto mb-20">
          <h2 class="font-display text-4xl sm:text-5xl font-extrabold text-light mb-6">Tout ce qu'il vous faut pour réussir</h2>
          <p class="text-light-muted text-lg">Une plateforme conçue pour les créateurs exigeants et les étudiants ambitieux.</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-10">
          @for (feature of features; track feature.title) {
            <div class="group p-10 rounded-[32px] border border-dark-border bg-white hover:border-primary/20 hover:shadow-card-hover transition-all duration-500">
              <div class="w-16 h-16 rounded-2xl bg-primary/5 flex items-center justify-center text-primary mb-8 group-hover:scale-110 group-hover:bg-primary/10 transition-all duration-500">
                @switch (feature.title) {
                  @case ('Design Premium') {
                    <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                  }
                  @case ('LiveKit Temps Réel') {
                    <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                  }
                  @case ('Monétisation') {
                    <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                  }
                  @case ('Vision PWA') {
                    <svg class="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 18h.01M8 21h8a2 2 0 002-2V5a2 2 0 00-2-2H8a2 2 0 00-2 2v14a2 2 0 002 2z" /></svg>
                  }
                }
              </div>
              <h3 class="font-display font-extrabold text-2xl text-light mb-4">{{ feature.title }}</h3>
              <p class="text-light-muted leading-relaxed">{{ feature.desc }}</p>
            </div>
          }
        </div>
      </div>
    </section>

    <!-- App Experience (New) -->
    <section class="py-32 px-4 bg-primary/5 relative overflow-hidden">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col lg:flex-row items-center gap-20">
          <div class="lg:w-1/2">
            <h2 class="font-display text-4xl sm:text-6xl font-extrabold text-light mb-8">Apprenez partout, <br /> à votre rythme.</h2>
            <p class="text-light-muted text-xl mb-12 leading-relaxed">
              Club des Formateurs est disponible sur tous vos appareils grâce à notre technologie PWA. Installez l'application en un clic et accédez à vos cours même hors connexion.
            </p>
            
            <div class="space-y-6">
              <div class="flex items-start gap-4">
                <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white shrink-0 mt-1">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" /></svg>
                </div>
                <div>
                  <h4 class="font-bold text-light text-lg">Streaming HD</h4>
                  <p class="text-light-muted">Qualité adaptative pour une fluidité parfaite sur mobile.</p>
                </div>
              </div>
              <div class="flex items-start gap-4">
                <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white shrink-0 mt-1">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" /></svg>
                </div>
                <div>
                  <h4 class="font-bold text-light text-lg">Notifications Live</h4>
                  <p class="text-light-muted">Soyez alerté dès qu'une session en direct commence.</p>
                </div>
              </div>
            </div>
          </div>
          
          <div class="lg:w-1/2 relative">
             <div class="absolute inset-0 bg-primary/20 rounded-full blur-[100px] animate-pulse"></div>
             <img loading="lazy" decoding="async" src="assets/anour-mockup.png" 
                   alt="App Interface" 
                   class="relative z-10 w-full max-w-[500px] mx-auto drop-shadow-[0_40px_80px_rgba(0,0,0,0.2)] rounded-[60px]" />
          </div>
        </div>
      </div>
    </section>

    <!-- Featured Courses -->
    <section class="py-32 px-4 bg-dark relative">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex flex-col sm:flex-row items-start sm:items-end justify-between mb-16 gap-6">
          <div>
            <h2 class="font-display text-4xl sm:text-5xl font-extrabold text-light mb-4">Formations à la une</h2>
            <p class="text-light-muted text-lg">Les programmes les plus plébiscités par notre communauté.</p>
          </div>
          <a routerLink="/catalogue" class="group flex items-center gap-3 text-primary font-bold hover:text-primary-600 transition-colors">
            Voir tout le catalogue
            <span class="group-hover:translate-x-1 transition-transform">→</span>
          </a>
        </div>

        @if (loading$ | async) {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">
            @for (i of [1,2,3]; track i) {
              <div class="bg-white border border-dark-border rounded-[32px] overflow-hidden animate-pulse shadow-sm">
                <div class="aspect-video bg-dark-surface2"></div>
                <div class="p-8 space-y-5">
                  <div class="h-4 bg-dark-surface2 rounded w-1/4"></div>
                  <div class="h-8 bg-dark-surface2 rounded w-4/5"></div>
                  <div class="h-4 bg-dark-surface2 rounded w-1/2"></div>
                </div>
              </div>
            }
          </div>
        } @else {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-10">
            @for (course of featured$ | async; track course.id) {
              <div class="transform hover:-translate-y-3 transition-transform duration-500">
                <app-course-card [course]="course" />
              </div>
            }
          </div>
        }
      </div>
    </section>

    <!-- Final CTA -->
    <section class="py-40 px-4 bg-dark relative overflow-hidden text-center">
      <div class="absolute inset-0 bg-primary/5"></div>
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[1000px] h-[1000px] bg-primary/5 rounded-full blur-[200px] pointer-events-none"></div>

      <div class="max-w-4xl mx-auto relative z-10 space-y-10">
        <h2 class="font-display text-5xl sm:text-7xl font-extrabold text-light mb-8 leading-tight">
          Prêt à commencer <br /> <span class="text-primary underline decoration-primary/20 underline-offset-8">votre voyage</span> ?
        </h2>
        <p class="text-light-muted text-xl sm:text-2xl mb-12 max-w-3xl mx-auto leading-relaxed font-medium">
          Rejoignez des milliers d'étudiants et de formateurs sur la plateforme de formation la plus innovante.
        </p>
        <div class="flex flex-col sm:flex-row items-center justify-center gap-6">
          <a routerLink="/auth/register"
             class="group inline-flex items-center gap-3 px-12 py-6 bg-primary text-white font-black text-xl rounded-[24px] hover:bg-primary-600 hover:scale-105 transition-all shadow-glow">
            Créer mon compte
            <svg class="w-6 h-6 group-hover:translate-x-2 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </a>
          <a routerLink="/catalogue"
             class="px-12 py-6 border-2 border-dark-border bg-white text-light font-black text-xl rounded-[24px] hover:border-primary/40 transition-all">
            Voir le catalogue
          </a>
        </div>
      </div>
    </section>
  `,
  styles: [`
    @keyframes bounceSlow {
      0%, 100% { transform: translateY(0); }
      50% { transform: translateY(-10px); }
    }
    @keyframes float {
      0%, 100% { transform: translateY(0) rotate(0); }
      33% { transform: translateY(-15px) rotate(2deg); }
      66% { transform: translateY(5px) rotate(-1deg); }
    }
    .animate-bounce-slow { animation: bounceSlow 4s ease-in-out infinite; }
    .animate-float { animation: float 6s ease-in-out infinite; }
  `],
})
export class HomeComponent implements OnInit {
  private store = inject(Store);
  private livekitService = inject(LivekitService);
  private titleService = inject(Title);
  private metaService = inject(Meta);

  activeLives = signal<LiveSession[]>([]);
  featured$ = this.store.select(selectFeaturedCourses);
  loading$ = this.store.select(selectCoursesLoading);

  stats = [
    { value: '5K+', label: 'Étudiants' },
    { value: '120+', label: 'Cours' },
    { value: '45+', label: 'Formateurs' },
    { value: '99.9%', label: 'Disponibilité' },
  ];

  categories = [
    { name: 'Business' },
    { name: 'Développement' },
    { name: 'Design' },
    { name: 'Langues' },
    { name: 'Marketing' },
    { name: 'Coaching' },
  ];

  features = [
    { title: 'Design Premium', desc: 'Interface moderne, rapide et adaptée aux écrans mobile, tablette et desktop.' },
    { title: 'LiveKit Temps Réel', desc: 'Classes live stables, interaction directe et expérience streaming professionnelle.' },
    { title: 'Monétisation', desc: 'Paiements Wave et Orange Money avec gestion native des accès et renouvellements.' },
    { title: 'Vision PWA', desc: 'Application installable, performante et prête pour une expérience quasi-native.' },
  ];

  ngOnInit(): void {
    this.titleService.setTitle('Club des Formateurs – Plateforme de Formation en Ligne & Cours en Direct');
    this.metaService.updateTag({ name: 'description', content: 'Club des Formateurs est la plateforme de référence pour se former en ligne, suivre des cours en direct et obtenir des certifications avec des formateurs experts.' });
    this.metaService.updateTag({ name: 'keywords', content: 'formation en ligne, cours en direct, club des formateurs, e-learning, certification, cours professionnels, webinaire' });
    
    this.store.dispatch(coursesActions.loadFeatured());

    this.livekitService.getActiveLiveSessions().subscribe(lives => {
      this.activeLives.set(lives);
    });
  }
}
