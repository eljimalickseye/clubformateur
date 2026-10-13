import { Component, inject, OnInit, signal } from '@angular/core';
import { Title, Meta } from '@angular/platform-browser';
import { Router, RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { AsyncPipe, CommonModule } from '@angular/common';
import { CourseCardComponent } from '../../shared/components/course-card/course-card.component';
import { TeachersCarouselComponent } from '../../shared/components/teachers-carousel/teachers-carousel.component';
import { coursesActions } from '../../store/courses/courses.actions';
import { selectFeaturedCourses, selectCoursesLoading } from '../../store/courses/courses.reducer';
import { LivekitService } from '../../core/services/livekit.service';
import { LiveSession } from '../../core/models';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterLink, AsyncPipe, FormsModule, CourseCardComponent, TeachersCarouselComponent],
  template: `
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- 1. HERO SECTION (Vert Sapin Immersion & Émeraude)              -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <section class="relative bg-gradient-to-br from-[#07343B] via-[#05272D] to-[#062C32] text-white pt-10 sm:pt-14 pb-24 sm:pb-32 overflow-hidden">
      <!-- Glow ambient background -->
      <div class="absolute -top-32 -right-32 w-[550px] h-[550px] bg-[#13C7A3]/12 rounded-full blur-[140px] pointer-events-none"></div>
      <div class="absolute -bottom-32 -left-32 w-[450px] h-[450px] bg-emerald-500/10 rounded-full blur-[120px] pointer-events-none"></div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">

        <!-- DYNAMIC LIVE BANNER (Si une session live est en cours) -->
        @if (activeLives().length > 0) {
          <div class="mb-8 p-4 sm:p-5 rounded-3xl bg-gradient-to-r from-red-600 via-rose-600 to-red-700 text-white shadow-2xl shadow-red-600/30 flex flex-col sm:flex-row items-center justify-between gap-4 border border-white/20">
            <div class="flex items-center gap-3.5">
              <span class="flex h-3.5 w-3.5 relative shrink-0">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-white opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3.5 w-3.5 bg-white"></span>
              </span>
              <div>
                <div class="flex items-center gap-2">
                  <span class="px-2 py-0.5 rounded-full bg-black/30 text-[10px] font-black uppercase tracking-wider">
                    🔴 MASTERCLASS EN DIRECT
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
              <span>Rejoindre le Direct</span>
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
              </svg>
            </a>
          </div>
        }

        <div class="grid lg:grid-cols-12 gap-12 lg:gap-8 items-center">

          <!-- COL GAUCHE : Textes & CTA -->
          <div class="lg:col-span-7 flex flex-col items-start text-left space-y-6">
            
            <!-- Badge Pill Néon -->
            <div class="inline-flex items-center gap-2.5 px-4 py-2 rounded-full bg-[#0D655B]/90 border border-[#13C7A3]/40 text-[#6DE0C4] text-xs font-extrabold tracking-wide shadow-sm">
              <span class="w-2 h-2 rounded-full bg-[#13C7A3] animate-pulse"></span>
              <span>✨ PLATEFORME PÉDAGOGIQUE D'EXCELLENCE</span>
            </div>

            <!-- Grand Titre -->
            <h1 class="font-display text-4xl sm:text-5xl lg:text-6xl font-black text-white leading-[1.08] tracking-tight">
              Apprenez avec les <br />
              <span class="text-transparent bg-clip-text bg-gradient-to-r from-[#13C7A3] via-[#35D3A3] to-[#6DE0C4]">
                Meilleurs Formateurs
              </span> <br />
              & Développez vos Talents
            </h1>

            <!-- Sous-titre -->
            <p class="text-slate-300 text-base sm:text-lg max-w-xl leading-relaxed font-normal">
              La plateforme d'excellence qui connecte les apprenants aux formateurs d'élite. Cours vidéo complets, masterclasses en direct, devoirs corrigés et certifications reconnues.
            </p>

            <!-- Boutons d'Action Principaux -->
            <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-4 w-full sm:w-auto pt-2">
              <a routerLink="/catalogue"
                 class="group px-8 py-4 bg-gradient-to-r from-[#13C7A3] to-[#12A57A] text-white font-extrabold text-sm sm:text-base rounded-2xl shadow-xl shadow-[#13C7A3]/30 hover:shadow-2xl hover:scale-105 active:scale-95 transition-all flex items-center justify-center gap-2.5">
                <span>Explorer les formations</span>
                <svg class="w-5 h-5 group-hover:translate-x-1 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6"/>
                </svg>
              </a>

              <a routerLink="/auth/register" [queryParams]="{role: 'teacher'}"
                 class="px-8 py-4 border-2 border-white/30 hover:border-white text-white font-extrabold text-sm sm:text-base rounded-2xl hover:bg-white/10 active:scale-95 transition-all text-center">
                Devenir formateur
              </a>
            </div>

            <!-- 3 Badges de Réassurance -->
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-4 w-full border-t border-emerald-900/60">
              <div class="flex items-center gap-2.5">
                <div class="w-9 h-9 rounded-xl bg-emerald-900/60 border border-emerald-600/40 flex items-center justify-center text-[#13C7A3] shrink-0">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z" />
                  </svg>
                </div>
                <div class="text-xs">
                  <p class="font-bold text-white leading-tight">Formations</p>
                  <p class="text-slate-400 text-[11px]">de haute qualité</p>
                </div>
              </div>

              <div class="flex items-center gap-2.5">
                <div class="w-9 h-9 rounded-xl bg-emerald-900/60 border border-emerald-600/40 flex items-center justify-center text-[#13C7A3] shrink-0">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                  </svg>
                </div>
                <div class="text-xs">
                  <p class="font-bold text-white leading-tight">Formateurs</p>
                  <p class="text-slate-400 text-[11px]">experts certifiés</p>
                </div>
              </div>

              <div class="flex items-center gap-2.5">
                <div class="w-9 h-9 rounded-xl bg-emerald-900/60 border border-emerald-600/40 flex items-center justify-center text-[#13C7A3] shrink-0">
                  <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                  </svg>
                </div>
                <div class="text-xs">
                  <p class="font-bold text-white leading-tight">Progression</p>
                  <p class="text-slate-400 text-[11px]">vers l'excellence</p>
                </div>
              </div>
            </div>

          </div>

          <!-- COL DROITE : Showcase Interactif Multi-Cartes -->
          <div class="lg:col-span-5 relative flex justify-center">
            <div class="relative w-full max-w-md">
              
              <!-- Carte Principale : Live & Formation en Direct -->
              <div class="bg-gradient-to-br from-[#06281F]/90 to-[#0A3D32]/90 backdrop-blur-2xl p-6 rounded-3xl border border-[#13C7A3]/30 shadow-2xl relative z-10 space-y-4">
                
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2">
                    <span class="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse"></span>
                    <span class="text-xs font-black tracking-wider uppercase text-red-300">Live Studio Actif</span>
                  </div>
                  <span class="px-2.5 py-1 rounded-full bg-[#13C7A3]/20 border border-[#13C7A3]/40 text-[#6DE0C4] text-[10px] font-extrabold uppercase">
                    Interactive
                  </span>
                </div>

                <!-- Aperçu Écran Studio -->
                <div class="relative aspect-video rounded-2xl bg-slate-900/80 border border-emerald-800/40 overflow-hidden flex items-center justify-center group cursor-pointer"
                     routerLink="/catalogue">
                  <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent z-10"></div>
                  <div class="w-14 h-14 rounded-full bg-[#13C7A3] text-white flex items-center justify-center shadow-xl group-hover:scale-110 transition-transform z-20">
                    <svg class="w-7 h-7 ml-1" fill="currentColor" viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
                  </div>
                  <div class="absolute bottom-3 left-3 right-3 z-20">
                    <p class="text-xs font-bold text-white truncate">Masterclass : Intelligence Artificielle & Automatisation</p>
                    <p class="text-[10px] text-emerald-300 font-medium">Session en direct • Questions/Réponses</p>
                  </div>
                </div>

                <!-- Formateur Info -->
                <div class="flex items-center justify-between pt-2">
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#13C7A3] to-emerald-400 flex items-center justify-center text-slate-900 font-black text-sm shadow-md">
                      CF
                    </div>
                    <div>
                      <p class="text-xs font-bold text-white leading-tight">Dr. Amadou Fall</p>
                      <p class="text-[10px] text-emerald-300">Professeur & Formateur Expert</p>
                    </div>
                  </div>
                  <div class="text-right">
                    <span class="text-xs font-extrabold text-amber-400">★ 4.9/5</span>
                    <p class="text-[10px] text-slate-400">98 avis</p>
                  </div>
                </div>

              </div>

              <!-- Badge Flottant 1 : Apprenants -->
              <div class="absolute -top-6 -left-6 sm:-left-8 bg-white/95 backdrop-blur-xl p-3.5 rounded-2xl shadow-2xl border border-slate-100 hidden sm:flex items-center gap-3 z-20 text-slate-900">
                <div class="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center font-black">
                  🎓
                </div>
                <div>
                  <p class="text-xs font-black leading-tight text-slate-900">+15 000 Apprenants</p>
                  <p class="text-[10px] font-semibold text-emerald-700">Communauté certifiée</p>
                </div>
              </div>

              <!-- Badge Flottant 2 : Paiement Wave & OM -->
              <div class="absolute -bottom-6 -right-4 sm:-right-6 bg-white/95 backdrop-blur-xl p-3.5 rounded-2xl shadow-2xl border border-slate-100 hidden sm:flex items-center gap-3 z-20 text-slate-900">
                <div class="w-10 h-10 rounded-xl bg-sky-100 text-sky-700 flex items-center justify-center font-black">
                  ⚡
                </div>
                <div>
                  <p class="text-xs font-black leading-tight text-slate-900">Wave & Orange Money</p>
                  <p class="text-[10px] font-semibold text-slate-500">Paiement instantané SN</p>
                </div>
              </div>

            </div>
          </div>

        </div>

      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- 2. BARRE DE RECHERCHE FLOTTANTE                                -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <div class="-mt-8 sm:-mt-10 max-w-5xl mx-auto px-4 relative z-30">
      <div class="bg-white rounded-3xl p-3 sm:p-5 shadow-2xl border border-slate-200/80 flex flex-col md:flex-row items-center gap-3">
        
        <!-- Input de Recherche -->
        <div class="flex-1 flex items-center gap-3 px-4 py-3 bg-slate-50 rounded-2xl border border-slate-200/60 w-full">
          <svg class="w-5 h-5 text-slate-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input type="text" [(ngModel)]="searchQuery" (keyup.enter)="onSearch()"
                 placeholder="Que souhaitez-vous apprendre ? (ex: Flutter, Marketing, IA...)"
                 class="w-full bg-transparent text-sm font-semibold text-slate-800 placeholder:text-slate-400 focus:outline-none">
        </div>

        <!-- Sélecteur Catégories -->
        <div class="w-full md:w-60 px-4 py-3 bg-slate-50 rounded-2xl border border-slate-200/60 flex items-center">
          <select [(ngModel)]="selectedCategory" (change)="onSearch()"
                  class="w-full bg-transparent text-xs font-bold text-slate-700 focus:outline-none cursor-pointer">
            <option value="">Toutes les catégories</option>
            <option value="Informatique & Tech">Informatique & Tech</option>
            <option value="Marketing & Digital">Marketing & Digital</option>
            <option value="Business & Gestion">Business & Gestion</option>
            <option value="Design & Multimédia">Design & Multimédia</option>
            <option value="Langues & Communication">Langues</option>
            <option value="Développement personnel">Développement personnel</option>
          </select>
        </div>

        <!-- Bouton Valider -->
        <button (click)="onSearch()"
                class="w-full md:w-auto px-8 py-3.5 bg-gradient-to-r from-[#13C7A3] to-[#12A57A] text-white font-extrabold text-xs sm:text-sm rounded-2xl hover:shadow-lg hover:shadow-emerald-500/25 transition-all active:scale-95 flex items-center justify-center gap-2 shrink-0 cursor-pointer">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <span>Rechercher</span>
        </button>

      </div>
    </div>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- 3. STATS BAND                                                  -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <section class="mt-14 py-10 sm:py-12 bg-gradient-to-r from-[#E8F7F1] via-[#F6FBF8] to-[#E8F7F1] border-y border-emerald-100/70">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-6 sm:gap-8 text-center">
          
          <div class="p-4 rounded-2xl bg-white/60 border border-emerald-100 shadow-sm">
            <p class="font-display text-3xl sm:text-4xl font-black text-[#0D6B4D]">+15 000</p>
            <p class="text-xs sm:text-sm font-extrabold text-slate-800 mt-1">Apprenants Inscrits</p>
            <p class="text-[11px] text-slate-500 mt-0.5">Communauté en croissance</p>
          </div>

          <div class="p-4 rounded-2xl bg-white/60 border border-emerald-100 shadow-sm">
            <p class="font-display text-3xl sm:text-4xl font-black text-[#0D6B4D]">98%</p>
            <p class="text-xs sm:text-sm font-extrabold text-slate-800 mt-1">Satisfaction Apprenants</p>
            <p class="text-[11px] text-slate-500 mt-0.5">Pédagogie d'excellence</p>
          </div>

          <div class="p-4 rounded-2xl bg-white/60 border border-emerald-100 shadow-sm">
            <p class="font-display text-3xl sm:text-4xl font-black text-[#0D6B4D]">+200</p>
            <p class="text-xs sm:text-sm font-extrabold text-slate-800 mt-1">Formations Certifiantes</p>
            <p class="text-[11px] text-slate-500 mt-0.5">Programmes pratiques</p>
          </div>

          <div class="p-4 rounded-2xl bg-white/60 border border-emerald-100 shadow-sm">
            <p class="font-display text-3xl sm:text-4xl font-black text-[#0D6B4D]">LiveKit Cloud</p>
            <p class="text-xs sm:text-sm font-extrabold text-slate-800 mt-1">Classes Directes & Replays</p>
            <p class="text-[11px] text-slate-500 mt-0.5">Interactif en temps réel</p>
          </div>

        </div>
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- 4. FORMATIONS DISPONIBLES                                      -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <section class="py-20 sm:py-28 px-4 bg-[#F8FAFC]">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="flex flex-col sm:flex-row items-start sm:items-end justify-between mb-12 gap-6">
          <div>
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-extrabold uppercase tracking-wider mb-2">
              COURS DES PROFESSEURS
            </div>
            <h2 class="font-display text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
              Formations disponibles
            </h2>
            <p class="text-sm sm:text-base text-slate-600 mt-1">
              Les cours conçus et encadrés par les formateurs de la plateforme Club des Formateurs
            </p>
          </div>

          <a routerLink="/catalogue"
             class="group inline-flex items-center gap-2 text-xs sm:text-sm font-extrabold text-[#0D6B4D] hover:text-[#12A57A] transition-colors">
            <span>Voir tout le catalogue</span>
            <span class="group-hover:translate-x-1 transition-transform">→</span>
          </a>
        </div>

        @if (loading$ | async) {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            @for (i of [1,2,3]; track i) {
              <div class="bg-white border border-slate-200 rounded-2xl overflow-hidden animate-pulse shadow-sm">
                <div class="aspect-video bg-slate-200"></div>
                <div class="p-6 space-y-4">
                  <div class="h-4 bg-slate-200 rounded w-1/4"></div>
                  <div class="h-6 bg-slate-200 rounded w-3/4"></div>
                  <div class="h-4 bg-slate-200 rounded w-1/2"></div>
                </div>
              </div>
            }
          </div>
        } @else {
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            @for (course of featured$ | async; track course.id) {
              <div class="transform hover:-translate-y-2 transition-transform duration-300">
                <app-course-card [course]="course" />
              </div>
            }
          </div>
        }

      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- 5. SECTION FORMATEURS EXPERTS (Dynamique Firestore)           -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <section class="py-20 sm:py-28 px-4 bg-white border-t border-slate-200/80">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <app-teachers-carousel />
      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- 6. CATEGORIES DE FORMATION                                     -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <section class="py-20 sm:py-28 px-4 bg-[#F8FAFC] border-t border-slate-200/80">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        <div class="text-center max-w-2xl mx-auto mb-14">
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-extrabold uppercase tracking-wider mb-2">
            CATÉGORIES
          </div>
          <h2 class="font-display text-3xl sm:text-4xl font-black text-slate-900 tracking-tight">
            Explorez par domaine d'expertise
          </h2>
          <p class="text-sm text-slate-600 mt-2">
            Choisissez la filière qui correspond à vos ambitions professionnelles.
          </p>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-5">
          @for (cat of categories; track cat.name) {
            <a routerLink="/catalogue" [queryParams]="{category: cat.name}"
               class="group flex flex-col items-center p-6 rounded-2xl bg-white border border-slate-200 hover:border-[#13C7A3] hover:shadow-xl hover:shadow-emerald-500/10 transition-all duration-300">
              <div class="w-16 h-16 rounded-2xl bg-emerald-50 text-[#0D6B4D] group-hover:bg-[#13C7A3] group-hover:text-white flex items-center justify-center mb-4 transition-all duration-300 group-hover:scale-110">
                <span class="text-2xl">{{ cat.icon }}</span>
              </div>
              <h3 class="font-extrabold text-xs sm:text-sm text-slate-800 text-center group-hover:text-[#0D6B4D] transition-colors">
                {{ cat.name }}
              </h3>
              <span class="text-[10px] font-semibold text-slate-400 mt-1">Explorer →</span>
            </a>
          }
        </div>

      </div>
    </section>

    <!-- ═══════════════════════════════════════════════════════════════ -->
    <!-- 7. DUAL CTA (Apprenant & Formateur)                            -->
    <!-- ═══════════════════════════════════════════════════════════════ -->
    <section class="py-24 sm:py-32 px-4 bg-gradient-to-br from-[#07343B] via-[#05272D] to-[#062C32] text-white relative overflow-hidden">
      <!-- Glow ambient -->
      <div class="absolute -top-24 -left-24 w-80 h-80 bg-emerald-400/15 rounded-full blur-[100px] pointer-events-none"></div>
      <div class="absolute -bottom-24 -right-24 w-80 h-80 bg-[#13C7A3]/15 rounded-full blur-[100px] pointer-events-none"></div>

      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        
        <div class="text-center max-w-2xl mx-auto mb-16">
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#0D655B] text-[#6DE0C4] text-xs font-extrabold uppercase tracking-wider mb-3">
            PRÊT À REJOINDRE L'AVENTURE ?
          </div>
          <h2 class="font-display text-3xl sm:text-5xl font-black text-white tracking-tight">
            Rejoignez dès aujourd'hui <br />
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-[#13C7A3] to-emerald-300">
              Club des Formateurs
            </span>
          </h2>
          <p class="text-slate-300 text-sm sm:text-base mt-3">
            Que vous souhaitiez apprendre ou transmettre votre savoir, notre plateforme est conçue pour votre réussite.
          </p>
        </div>

        <div class="grid md:grid-cols-2 gap-8">
          
          <!-- Carte 1 : Apprenant -->
          <div class="bg-white/10 backdrop-blur-xl border border-white/20 rounded-3xl p-8 sm:p-10 flex flex-col justify-between space-y-6 hover:border-[#13C7A3]/60 transition-all">
            <div class="space-y-4">
              <span class="px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-300 text-xs font-bold uppercase tracking-wider">
                ESPACE APPRENANT
              </span>
              <h3 class="font-display text-2xl sm:text-3xl font-black text-white">
                Vous souhaitez vous former ?
              </h3>
              <p class="text-slate-300 text-sm leading-relaxed">
                Accédez à des formations de qualité, participez aux sessions directes avec les formateurs, rendez vos devoirs et obtenez vos certificats d'excellence.
              </p>
            </div>

            <a routerLink="/auth/register" [queryParams]="{role: 'student'}"
               class="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 bg-[#13C7A3] hover:bg-[#12A57A] text-white font-extrabold text-sm rounded-2xl shadow-xl shadow-[#13C7A3]/25 transition-all">
              <span>Créer mon compte apprenant</span>
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
              </svg>
            </a>
          </div>

          <!-- Carte 2 : Formateur -->
          <div class="bg-white/10 backdrop-blur-xl border border-white/20 rounded-3xl p-8 sm:p-10 flex flex-col justify-between space-y-6 hover:border-[#13C7A3]/60 transition-all">
            <div class="space-y-4">
              <span class="px-3 py-1 rounded-full bg-amber-400/20 text-amber-300 text-xs font-bold uppercase tracking-wider">
                ESPACE FORMATEUR
              </span>
              <h3 class="font-display text-2xl sm:text-3xl font-black text-white">
                Vous êtes un expert ou enseignant ?
              </h3>
              <p class="text-slate-300 text-sm leading-relaxed">
                Partagez vos compétences, créez vos studios de cours en direct, évaluez vos étudiants et percevez vos revenus facilement par Wave SN et Orange Money.
              </p>
            </div>

            <a routerLink="/auth/register" [queryParams]="{role: 'teacher'}"
               class="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 bg-white hover:bg-slate-100 text-[#062C32] font-black text-sm rounded-2xl shadow-xl transition-all">
              <span>Devenir formateur certifié</span>
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
              </svg>
            </a>
          </div>

        </div>

      </div>
    </section>
  `,
})
export class HomeComponent implements OnInit {
  private store = inject(Store);
  private livekitService = inject(LivekitService);
  private router = inject(Router);
  private titleService = inject(Title);
  private metaService = inject(Meta);

  activeLives = signal<LiveSession[]>([]);
  featured$ = this.store.select(selectFeaturedCourses);
  loading$ = this.store.select(selectCoursesLoading);

  searchQuery = '';
  selectedCategory = '';

  categories = [
    { name: 'Informatique & Tech', icon: '💻' },
    { name: 'Marketing & Digital', icon: '📈' },
    { name: 'Business & Gestion', icon: '💼' },
    { name: 'Design & Multimédia', icon: '🎨' },
    { name: 'Langues & Éloquence', icon: '🌍' },
    { name: 'Développement personnel', icon: '🚀' },
  ];

  ngOnInit(): void {
    this.titleService.setTitle('Club des Formateurs – Apprenez avec les Meilleurs Formateurs');
    this.metaService.updateTag({
      name: 'description',
      content: 'Plateforme d\'excellence de formations en ligne, cours certifiants et masterclasses en direct avec des experts reconnus.'
    });
    
    this.store.dispatch(coursesActions.loadFeatured());

    this.livekitService.getActiveLiveSessions().subscribe(lives => {
      this.activeLives.set(lives);
    });
  }

  onSearch(): void {
    const query = this.searchQuery.trim();
    const category = this.selectedCategory;
    const queryParams: Record<string, string> = {};

    if (query) queryParams['q'] = query;
    if (category) queryParams['category'] = category;

    this.router.navigate(['/catalogue'], { queryParams });
  }
}
