import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { AuthService } from '../../../core/services/auth.service';
import { FormBuilder, ReactiveFormsModule, Validators, FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { switchMap, of, combineLatest } from 'rxjs';
import { CourseService } from '../../../core/services/course.service';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { Course, Lesson, Section, User } from '../../../core/models';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-course-creator',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule, RouterLink, BackButtonComponent],
  template: `
    <div class="max-w-4xl mx-auto px-3.5 sm:px-6 py-4 sm:py-8 font-body">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6 sm:mb-8 gap-3">
        <div class="flex items-center gap-3 sm:gap-4 min-w-0">
          <app-back-button label="Retour aux cours" defaultRoute="/teacher/courses" [showIconOnlyOnMobile]="true" />
          <div class="min-w-0">
            <h1 class="font-display text-2xl font-bold text-light">
              {{ courseId ? 'Modifier le cours' : 'Nouveau cours' }}
            </h1>
            <p class="text-light-muted text-sm">Remplissez les informations de votre cours</p>
          </div>
        </div>

        @if (courseId) {
          <button (click)="deleteCurrentCourse()"
                  class="px-4 py-2 bg-red-500/10 hover:bg-red-500 hover:text-white text-red-500 border border-red-500/30 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
            </svg>
            <span>Supprimer le cours</span>
          </button>
        }
      </div>

      <!-- Steps -->
      <div class="flex flex-wrap items-center gap-2 mb-8">
        @for (step of steps; track step.label; let i = $index) {
          <div class="flex items-center gap-2">
            <div [class]="currentStep() === i
                          ? 'bg-primary text-white'
                           : currentStep() > i ? 'bg-emerald-500 text-white' : 'bg-dark-surface2 text-light-muted'"
                 class="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all">
              {{ currentStep() > i ? '✓' : i + 1 }}
            </div>
            <span [class]="currentStep() === i ? 'text-light' : 'text-light-muted'"
                  class="text-xs font-medium hidden sm:block">{{ step.label }}</span>
          </div>
          @if (i < steps.length - 1) {
            <div class="flex-1 h-px bg-dark-border mx-1 min-w-[20px]"></div>
          }
        }
      </div>

      <!-- Step 1: Basic info -->
      @if (currentStep() === 0) {
        <div class="bg-dark-surface border border-dark-border rounded-xl p-6 animate-fade-in">
          <h2 class="font-display text-lg font-semibold text-light mb-5">Informations générales</h2>
          <form [formGroup]="basicForm" class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-light mb-1.5">Titre du cours *</label>
              <input type="text" formControlName="title" placeholder="Ex: Maîtriser le Développement Web Moderne"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                            text-light placeholder-light-muted focus:outline-none focus:border-primary text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-light mb-1.5">Résumé court *</label>
              <input type="text" formControlName="shortDescription" placeholder="1-2 phrases décrivant le cours"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                            text-light placeholder-light-muted focus:outline-none focus:border-primary text-sm">
            </div>
            <div>
              <label class="block text-sm font-medium text-light mb-1.5">Description complète *</label>
              <textarea formControlName="description" rows="5" placeholder="Décrivez votre cours en détail..."
                        class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                               text-light placeholder-light-muted focus:outline-none focus:border-primary text-sm resize-none">
              </textarea>
            </div>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div>
                <label class="block text-sm font-medium text-light mb-1.5">Catégorie *</label>
                <select formControlName="categoryId"
                        class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                               text-light focus:outline-none focus:border-primary text-sm">
                  <option value="tech-dev">Informatique & Développement Web</option>
                  <option value="business">Business & Entrepreneuriat</option>
                  <option value="design-media">Design & Multimédia</option>
                  <option value="marketing">Marketing Digital & Vente</option>
                  <option value="languages">Langues & Communication</option>
                  <option value="sciences">Sciences & Soutien Académique</option>
                  <option value="coaching">Développement Personnel</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-light mb-1.5">Niveau</label>
                <select formControlName="level"
                        class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                               text-light focus:outline-none focus:border-primary text-sm">
                  <option value="débutant">Débutant</option>
                  <option value="intermédiaire">Intermédiaire</option>
                  <option value="avancé">Avancé</option>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-light mb-1.5">Langue</label>
                <select formControlName="language"
                        class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                               text-light focus:outline-none focus:border-primary text-sm">
                  <option value="fr">Français</option>
                  <option value="en">Anglais</option>
                  <option value="ar">Arabe</option>
                  <option value="wo">Wolof</option>
                </select>
              </div>
            </div>
          </form>
        </div>
      }

      <!-- Step 2: Pricing -->
      @if (currentStep() === 1) {
        <div class="bg-dark-surface border border-dark-border rounded-xl p-6 animate-fade-in">
          <h2 class="font-display text-lg font-semibold text-light mb-5">Tarification</h2>
          <form [formGroup]="pricingForm" class="space-y-4">
            <!-- Free toggle -->
            <div class="flex items-center justify-between p-4 border border-dark-border rounded-lg">
              <div>
                <div class="font-medium text-light text-sm">Cours gratuit</div>
                <div class="text-xs text-light-muted">Le cours sera accessible sans paiement</div>
              </div>
              <button type="button" (click)="toggleFree()"
                      [class]="isFree() ? 'bg-primary' : 'bg-dark-surface2'"
                      class="w-11 h-6 rounded-full transition-all relative">
                <span [class]="isFree() ? 'left-5' : 'left-0.5'"
                      class="absolute top-0.5 w-5 h-5 bg-white rounded-full transition-all shadow"></span>
              </button>
            </div>

            @if (!isFree()) {
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-light mb-1.5">Prix (XOF) *</label>
                  <input type="number" formControlName="price" placeholder="5000"
                         class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                                text-light placeholder-light-muted focus:outline-none focus:border-primary text-sm">
                </div>
                <div>
                  <label class="block text-sm font-medium text-light mb-1.5">Prix original (optionnel)</label>
                  <input type="number" formControlName="originalPrice" placeholder="8000"
                         class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                                text-light placeholder-light-muted focus:outline-none focus:border-primary text-sm">
                </div>
              </div>
              <div class="p-3 bg-primary/5 border border-primary/20 rounded-lg text-xs text-light-muted">
                💡 Club des Formateurs prélève 10% de commission. Vous recevrez 90% des revenus via Wave/Orange Money.
              </div>
              <div>
                <label class="block text-sm font-medium text-light mb-1.5">Type de facturation</label>
                <select formControlName="pricingType"
                        class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-lg
                               text-light focus:outline-none focus:border-primary text-sm">
                  <option value="one-time">Paiement unique (Accès illimité)</option>
                  <option value="monthly">Mensuel (Accès pour 30 jours)</option>
                </select>
              </div>
            }

            <div class="space-y-2">
              <div class="flex items-center gap-3">
                <input type="checkbox" formControlName="hasCertificate" id="cert" class="accent-primary">
                <label for="cert" class="text-sm text-light">Inclure un certificat de complétion</label>
              </div>
              <div class="flex items-center gap-3">
                <input type="checkbox" formControlName="hasLiveClasses" id="live" class="accent-primary">
                <label for="live" class="text-sm text-light">Ce cours inclut des sessions live</label>
              </div>
            </div>
          </form>
        </div>
      }

      <!-- Step 3: Thumbnail & Images Thématiques -->
      @if (currentStep() === 2) {
        <div class="bg-dark-surface border border-dark-border rounded-2xl p-6 sm:p-8 animate-fade-in space-y-8">
          <div>
            <span class="text-xs font-bold text-primary uppercase tracking-wider">Visuel du cours</span>
            <h2 class="font-display text-xl font-bold text-light mt-1">Image de couverture du cours</h2>
            <p class="text-xs text-light-muted mt-1">
              Cette image apparaîtra sur le catalogue, la page du cours et l'espace étudiant.
            </p>
          </div>

          <!-- Current Image Preview -->
          <div class="space-y-3">
            <label class="block text-xs font-bold text-light uppercase tracking-wider">Aperçu sélectionné</label>
            <div class="relative aspect-[16/9] max-h-72 w-full rounded-2xl overflow-hidden border-2 border-dark-border bg-dark-surface2 flex items-center justify-center group shadow-lg">
              @if (thumbnailPreview()) {
                <img loading="lazy" decoding="async" [src]="thumbnailPreview()" alt="Couverture du cours" class="w-full h-full object-cover">
                <div class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-3">
                  <button type="button" (click)="thumbnailInput.click()" class="px-4 py-2 bg-white text-slate-900 text-xs font-bold rounded-xl shadow-lg hover:bg-slate-100 transition-all cursor-pointer">
                    Changer l'image
                  </button>
                  <button type="button" (click)="thumbnailPreview.set(null)" class="px-4 py-2 bg-red-600 text-white text-xs font-bold rounded-xl shadow-lg hover:bg-red-700 transition-all cursor-pointer">
                    Retirer
                  </button>
                </div>
                <div class="absolute bottom-3 left-3 px-3 py-1 bg-black/60 backdrop-blur-md rounded-lg text-white text-xs font-bold flex items-center gap-1.5">
                  <span>✓</span> Image sélectionnée
                </div>
              } @else {
                <div class="text-center p-6 space-y-2">
                  <div class="w-16 h-16 mx-auto rounded-2xl bg-primary/10 text-primary flex items-center justify-center text-3xl">
                    🖼️
                  </div>
                  <p class="text-sm font-bold text-light">Aucune image sélectionnée</p>
                  <p class="text-xs text-light-muted">Choisissez une image thématique ci-dessous ou importez votre fichier</p>
                </div>
              }
            </div>
          </div>

          <!-- Section 1: Banque d'images par Thématique (SVT, Sciences, Informatique, Maths, etc.) -->
          <div class="space-y-4 pt-4 border-t border-dark-border">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="font-display text-base font-bold text-light flex items-center gap-2">
                  <span>✨</span> Banque d'images thématiques par discipline
                </h3>
                <p class="text-xs text-light-muted">Sélectionnez une image de haute qualité adaptée à votre matière</p>
              </div>
            </div>

            <!-- Categories Tabs -->
            <div class="flex items-center gap-2 overflow-x-auto pb-2 no-scrollbar">
              @for (cat of themeCategories; track cat.id) {
                <button type="button"
                        (click)="selectedThemeCategory.set(cat.id)"
                        [class.bg-primary]="selectedThemeCategory() === cat.id"
                        [class.text-white]="selectedThemeCategory() === cat.id"
                        [class.bg-dark-surface2]="selectedThemeCategory() !== cat.id"
                        [class.text-light-muted]="selectedThemeCategory() !== cat.id"
                        class="px-4 py-2 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer hover:text-light">
                  {{ cat.label }}
                </button>
              }
            </div>

            <!-- Thematic Grid -->
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
              @for (item of thematicImages[selectedThemeCategory()]; track item.url) {
                <div (click)="selectThematicImage(item.url)"
                     [class.ring-4]="thumbnailPreview() === item.url"
                     [class.ring-primary]="thumbnailPreview() === item.url"
                     class="group relative aspect-[16/10] rounded-xl overflow-hidden border border-dark-border cursor-pointer transition-all hover:scale-[1.03] shadow-sm">
                  <img loading="lazy" decoding="async" [src]="item.url" [alt]="item.title" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500">
                  <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>
                  
                  <div class="absolute top-2 right-2">
                    @if (thumbnailPreview() === item.url) {
                      <span class="w-5 h-5 rounded-full bg-primary text-white flex items-center justify-center text-xs font-black shadow-lg">✓</span>
                    }
                  </div>

                  <div class="absolute bottom-2 left-2 right-2">
                    <span class="px-1.5 py-0.5 rounded bg-primary/90 text-white text-[9px] font-bold uppercase mb-1 inline-block">
                      {{ item.tag }}
                    </span>
                    <p class="text-white text-xs font-bold leading-tight line-clamp-1">
                      {{ item.title }}
                    </p>
                  </div>
                </div>
              }
            </div>
          </div>

          <!-- Section 2: Importer ou Lien personnalisé -->
          <div class="space-y-4 pt-4 border-t border-dark-border">
            <h3 class="font-display text-sm font-bold text-light">Ou utilisez une image personnalisée :</h3>
            
            <div class="grid sm:grid-cols-2 gap-4">
              <!-- Upload from device -->
              <div (click)="thumbnailInput.click()"
                   class="p-4 rounded-xl border border-dashed border-dark-border hover:border-primary bg-dark-surface2/50 text-center cursor-pointer transition-all space-y-1">
                <p class="text-xs font-bold text-light">📁 Importer depuis votre appareil</p>
                <p class="text-[11px] text-light-muted">PNG, JPG, WebP (Max 5 Mo)</p>
              </div>

              <!-- Paste Custom URL -->
              <div class="flex gap-2">
                <input type="text"
                       [(ngModel)]="customImageUrl"
                       placeholder="https://... (Lien d'image)"
                       class="flex-1 px-3 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary">
                <button type="button" (click)="applyCustomUrl()"
                        class="px-4 py-2 bg-primary text-white text-xs font-bold rounded-xl hover:bg-primary-600 transition-all cursor-pointer">
                  Appliquer
                </button>
              </div>
            </div>

            <input #thumbnailInput type="file" accept="image/*" class="hidden"
                   (change)="onThumbnailChange($event)">

            @if (uploadProgress() > 0 && uploadProgress() < 100) {
              <div class="mt-4">
                <div class="w-full bg-dark-surface2 rounded-full h-2">
                  <div class="bg-primary h-2 rounded-full transition-all" [style.width.%]="uploadProgress()"></div>
                </div>
                <p class="text-xs text-light-muted mt-1">Upload en cours : {{ uploadProgress() }}%</p>
              </div>
            }
          </div>

          <!-- Section 3: Vidéo de présentation (Bande-annonce) -->
          <div class="space-y-4 pt-6 border-t border-dark-border">
            <div>
              <span class="text-xs font-bold text-primary uppercase tracking-wider">Aperçu vidéo gratuit</span>
              <h3 class="font-display text-base font-bold text-light mt-1">🎬 Vidéo de présentation (Bande-annonce du cours)</h3>
              <p class="text-xs text-light-muted">
                Ajoutez une vidéo de présentation pour permettre aux futurs apprenants de découvrir un aperçu de votre formation.
              </p>
            </div>

            <div class="grid sm:grid-cols-2 gap-4">
              <div (click)="promoVideoInput.click()"
                   class="p-4 rounded-xl border border-dashed border-dark-border hover:border-primary bg-dark-surface2/50 text-center cursor-pointer transition-all space-y-1">
                <p class="text-xs font-bold text-light">🎥 Importer une vidéo de présentation</p>
                <p class="text-[11px] text-light-muted">MP4, WebM (Bande-annonce 1 à 5 min)</p>
              </div>

              <div class="flex gap-2">
                <input type="text"
                       [(ngModel)]="customPromoVideoUrl"
                       placeholder="https://... (Lien MP4 ou YouTube de présentation)"
                       class="flex-1 px-3 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary">
                <button type="button" (click)="applyPromoVideoUrl()"
                        class="px-4 py-2 bg-primary text-white text-xs font-bold rounded-xl hover:bg-primary-600 transition-all cursor-pointer">
                  Valider
                </button>
              </div>
            </div>

            <input #promoVideoInput type="file" accept="video/*" class="hidden"
                   (change)="onPromoVideoChange($event)">

            @if (promoVideoUrl()) {
              <div class="p-3 bg-emerald-500/10 border border-emerald-500/30 rounded-xl flex items-center justify-between">
                <span class="text-xs text-emerald-400 font-semibold truncate">✓ Vidéo de présentation liée : {{ promoVideoUrl() }}</span>
                <button type="button" (click)="promoVideoUrl.set(null)" class="text-xs text-red-400 hover:underline ml-3">Retirer</button>
              </div>
            }
          </div>

        </div>
      }

      <!-- Step 4: Programme (Curriculum) -->
      @if (currentStep() === 3) {
        <div class="bg-dark-surface border border-dark-border rounded-xl p-6 animate-fade-in">
          <div class="flex justify-between items-center mb-5">
            <h2 class="font-display text-lg font-semibold text-light">Programme du cours</h2>
            <button (click)="openAddSectionModal()" class="btn-primary text-sm !px-4 !py-2">
              + Nouvelle Section
            </button>
          </div>

          @if (sections().length === 0) {
            <div class="text-center py-10 border border-dashed border-dark-border rounded-xl">
              <p class="text-light-muted text-sm mb-3">Votre cours est vide pour le moment.</p>
              <button (click)="openAddSectionModal()" class="btn-secondary text-sm">Ajouter la première section</button>
            </div>
          } @else {
            <div class="space-y-4">
              @for (section of sections(); track section.id) {
                <div class="border border-dark-border rounded-xl overflow-hidden">
                  <div class="bg-dark-surface2 px-4 py-3 flex justify-between items-center">
                    <h3 class="font-semibold text-light text-sm">Section {{ section.order }}: {{ section.title }}</h3>
                    <div class="flex items-center gap-2">
                      <button (click)="openAddLessonModal(section.id)" class="text-xs text-primary hover:text-primary-400 font-medium">+ Leçon</button>
                    </div>
                  </div>
                  <div class="bg-dark p-3 space-y-2">
                    @for (lesson of getLessonsForSection(section.id); track lesson.id) {
                      <div class="flex justify-between items-center bg-dark-surface p-3 rounded-lg border border-dark-border/50">
                        <div class="flex items-center gap-3">
                          <span class="text-light-muted">
                            @if (lesson.type === 'video') {
                              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="23 7 16 12 23 17 23 7"/><rect x="1" y="5" width="15" height="14" rx="2" ry="2"/></svg>
                            } @else if (lesson.type === 'pdf') {
                              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                            } @else if (lesson.type === 'quiz') {
                              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                            } @else {
                              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
                            }
                          </span>
                          <span class="text-sm text-light">{{ lesson.title }}</span>
                        </div>
                        <div class="flex items-center gap-3">
                          @if (lesson.isFree) {
                            <span class="badge-info !text-[10px]">Aperçu gratuit</span>
                          }
                          <button class="text-light-muted hover:text-red-400 transition-colors" (click)="deleteLesson(lesson.id)">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
                          </button>
                        </div>
                      </div>
                    } @empty {
                      <p class="text-xs text-light-muted text-center py-2">Aucune leçon dans cette section.</p>
                    }
                  </div>
                </div>
              }
            </div>
          }
        </div>
      }

      <!-- Navigation buttons -->
      <div class="flex items-center justify-between mt-6">
        <button (click)="prevStep()" [disabled]="currentStep() === 0"
                class="px-5 py-2.5 border border-dark-border text-light-muted rounded-lg text-sm
                       hover:bg-dark-surface2 disabled:opacity-30 transition-colors">
          ← Précédent
        </button>

        <div class="flex items-center gap-3">
          <!-- Live Preview button -->
          <button (click)="showPreviewModal = true"
                  class="px-4 py-2.5 rounded-lg border border-dark-border bg-white text-light hover:bg-dark-surface2 text-xs font-bold transition-all shadow-xs flex items-center gap-2">
            <svg class="w-4 h-4 text-primary" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
            </svg>
            <span>Prévisualiser</span>
          </button>

          <!-- Quick Save Draft button -->
          @if (currentStep() > 0) {
            <button (click)="saveCourse(false)" [disabled]="saving()"
                    class="px-4 py-2.5 rounded-lg border border-dark-border bg-dark-surface2 text-light hover:bg-dark-border text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer">
              @if (saving()) {
                <span class="inline-block w-3 h-3 border-2 border-primary border-t-transparent rounded-full animate-spin"></span>
              }
              <span>💾 Enregistrer brouillon</span>
            </button>
          }

          @if (currentStep() < steps.length - 1) {
            <button (click)="nextStep()" [disabled]="saving()"
                    class="px-5 py-2.5 bg-primary text-white font-semibold rounded-lg text-sm
                           hover:bg-primary-600 disabled:opacity-50 transition-colors flex items-center gap-2 cursor-pointer shadow-md shadow-primary/20">
              @if (saving()) {
                <span class="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
                <span>Enregistrement...</span>
              } @else if (currentStep() === 2 && !courseId) {
                <span>Créer & Définir le Programme →</span>
              } @else {
                <span>Suivant →</span>
              }
            </button>
          } @else {
            <div class="flex items-center gap-2">
              <button (click)="finishCourse()"
                      class="px-4 py-2.5 bg-dark-surface2 hover:bg-dark-border text-light font-bold rounded-lg text-xs transition-colors cursor-pointer">
                Terminer
              </button>
              <button (click)="submitForValidation()"
                      class="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-lg text-xs shadow-md shadow-emerald-600/25 transition-all flex items-center gap-1.5 cursor-pointer">
                <span>🚀 Soumettre pour validation</span>
              </button>
            </div>
          }
        </div>
      </div>
      @if (!isCurrentStepValid()) {
        <p class="text-[11px] text-amber-500 font-medium text-right mt-2">
          Veuillez remplir au moins le titre de votre cours pour continuer.
        </p>
      }

      <!-- Modals -->
      @if (showAddSectionModal) {
        <div class="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div class="bg-dark-surface border border-dark-border rounded-2xl p-6 w-full max-w-md">
            <h3 class="font-display text-xl font-bold text-light mb-4">Nouvelle Section</h3>
            <div class="mb-4">
              <label class="block text-sm font-medium text-light mb-1.5">Titre de la section</label>
              <input type="text" [(ngModel)]="newSectionTitle" placeholder="Ex: Introduction au cours"
                     class="w-full px-4 py-2.5 bg-dark border border-dark-border rounded-lg text-light focus:border-primary focus:outline-none">
            </div>
            <div class="flex justify-end gap-3">
              <button (click)="showAddSectionModal = false" class="btn-secondary">Annuler</button>
              <button (click)="addSection()" class="btn-primary" [disabled]="!newSectionTitle.trim() || savingModal()">
                {{ savingModal() ? '...' : 'Ajouter' }}
              </button>
            </div>
          </div>
        </div>
      }

      @if (showAddLessonModal) {
        <div class="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div class="bg-dark-surface border border-dark-border rounded-2xl p-6 w-full max-w-md">
            <h3 class="font-display text-xl font-bold text-light mb-4">Nouvelle Leçon</h3>
            <form [formGroup]="lessonForm" (ngSubmit)="addLesson()">
              <div class="space-y-4 mb-6">
                <div>
                  <label class="block text-sm font-medium text-light mb-1.5">Titre de la leçon</label>
                  <input type="text" formControlName="title" placeholder="Ex: Les conditions de validité"
                         class="w-full px-4 py-2.5 bg-dark border border-dark-border rounded-lg text-light focus:border-primary focus:outline-none">
                </div>
                <div>
                  <label class="block text-sm font-medium text-light mb-1.5">Type de contenu</label>
                  <select formControlName="type"
                          class="w-full px-4 py-2.5 bg-dark border border-dark-border rounded-lg text-light focus:border-primary focus:outline-none">
                    <option value="video">Vidéo</option>
                    <option value="text">Texte / Article</option>
                    <option value="pdf">Document PDF</option>
                    <option value="quiz">Quiz</option>
                  </select>
                </div>
                @if (lessonForm.get('type')?.value !== 'quiz' && lessonForm.get('type')?.value !== 'text') {
                  <div>
                    <label class="block text-sm font-medium text-light mb-1.5">Fichier (Vidéo/PDF)</label>
                    <div class="border-2 border-dashed border-dark-border rounded-lg p-4 text-center hover:border-primary/50 transition-colors cursor-pointer"
                         (click)="lessonFileInput.click()">
                      @if (selectedLessonFile) {
                        <p class="text-xs text-primary font-medium truncate">{{ selectedLessonFile.name }}</p>
                      } @else {
                        <p class="text-xs text-light-muted">Cliquez pour sélectionner un fichier</p>
                      }
                    </div>
                    <input #lessonFileInput type="file" [accept]="lessonForm.get('type')?.value === 'video' ? 'video/*' : '.pdf'"
                           class="hidden" (change)="onLessonFileChange($event)">
                  </div>
                }

                <div class="flex items-center gap-3 mt-2">
                  <input type="checkbox" formControlName="isFree" id="isFree" class="accent-primary">
                  <label for="isFree" class="text-sm text-light">Aperçu gratuit (accessible sans payer)</label>
                </div>
              </div>

              @if (lessonUploadProgress() > 0 && lessonUploadProgress() < 100) {
                <div class="mb-4">
                  <div class="w-full bg-dark-surface2 rounded-full h-1.5">
                    <div class="bg-primary h-1.5 rounded-full transition-all" [style.width.%]="lessonUploadProgress()"></div>
                  </div>
                  <p class="text-[10px] text-light-muted mt-1">Upload du fichier: {{ lessonUploadProgress() }}%</p>
                </div>
              }
              <div class="flex justify-end gap-3">
                <button type="button" (click)="showAddLessonModal = false" class="btn-secondary">Annuler</button>
                <button type="submit" class="btn-primary" [disabled]="lessonForm.invalid || savingModal() || (selectedLessonFile && lessonUploadProgress() < 100)">
                  {{ savingModal() ? '...' : 'Ajouter' }}
                </button>
              </div>
            </form>
          </div>
        </div>
      }

      <!-- Live Student Preview Modal (Requirement 5) -->
      @if (showPreviewModal) {
        <div class="fixed inset-0 bg-black/70 backdrop-blur-md z-50 flex items-center justify-center p-4 overflow-y-auto"
             (click)="showPreviewModal = false">
          <div class="bg-white rounded-3xl p-6 sm:p-8 w-full max-w-4xl max-h-[90vh] overflow-y-auto shadow-2xl border border-dark-border space-y-6"
               (click)="$event.stopPropagation()">
            
            <div class="flex items-center justify-between border-b border-dark-border/60 pb-4">
              <div class="flex items-center gap-2">
                <span class="px-2.5 py-0.5 rounded-full bg-primary/10 text-primary text-[10px] font-bold uppercase tracking-wider">
                  Mode Prévisualisation Étudiant
                </span>
              </div>
              <button (click)="showPreviewModal = false" class="p-2 rounded-xl text-light-muted hover:bg-dark-surface2 text-xs font-bold">
                ✕ Fermer l'aperçu
              </button>
            </div>

            <!-- Preview Course Banner & Info -->
            <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <div class="lg:col-span-2 space-y-4">
                <div class="h-60 rounded-2xl bg-dark-surface2 overflow-hidden border border-dark-border relative">
                  @if (thumbnailPreview()) {
                    <img loading="lazy" decoding="async" [src]="thumbnailPreview()" [alt]="basicForm.get('title')?.value" class="w-full h-full object-cover">
                  } @else {
                    <div class="w-full h-full flex items-center justify-center text-5xl">📖</div>
                  }
                </div>

                <div class="space-y-2">
                  <div class="flex items-center gap-2 text-xs font-bold text-primary uppercase">
                    <span>{{ basicForm.get('level')?.value | titlecase }}</span>
                    <span>•</span>
                    <span>Langue : {{ basicForm.get('language')?.value | uppercase }}</span>
                  </div>
                  <h1 class="font-display text-2xl font-black text-light">
                    {{ basicForm.get('title')?.value || 'Titre de votre formation' }}
                  </h1>
                  <p class="text-xs text-light-muted">
                    {{ basicForm.get('shortDescription')?.value || 'Résumé court de la formation...' }}
                  </p>
                </div>

                <div class="space-y-2 pt-4 border-t border-dark-border/60">
                  <h3 class="font-display text-sm font-bold text-light">Description du cours</h3>
                  <p class="text-xs text-light-muted leading-relaxed whitespace-pre-line">
                    {{ basicForm.get('description')?.value || 'Description complète...' }}
                  </p>
                </div>
              </div>

              <!-- Sidebar Card (Student view) -->
              <div class="rounded-2xl border border-dark-border bg-dark-surface2/30 p-5 space-y-4 h-fit">
                <div>
                  <span class="text-xs text-light-muted font-medium">Prix de la formation</span>
                  <p class="font-display text-3xl font-black text-primary mt-1">
                    {{ isFree() ? 'Gratuit' : ((pricingForm.get('price')?.value | number) + ' F CFA') }}
                  </p>
                </div>

                <button class="w-full py-3 bg-primary text-white text-xs font-bold rounded-xl shadow-md shadow-primary/25 cursor-default">
                  S'inscrire à la formation
                </button>
                <button class="w-full py-3 bg-white border border-dark-border text-light text-xs font-bold rounded-xl hover:bg-slate-50 cursor-default">
                  Faire une demande d'inscription
                </button>

                <div class="text-[11px] text-light-muted space-y-2 pt-2 border-t border-dark-border/40">
                  <div class="flex items-center justify-between">
                    <span>Accès :</span>
                    <span class="font-bold text-light">À vie & Illimité</span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span>Certificat :</span>
                    <span class="font-bold text-emerald-600">Inclus après réussite</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="text-right pt-4 border-t border-dark-border/60">
              <button (click)="showPreviewModal = false" class="px-5 py-2.5 bg-primary text-white text-xs font-bold rounded-xl shadow-sm">
                Retour à l'édition
              </button>
            </div>

          </div>
        </div>
      }
    </div>
  `,
})
export class CourseCreatorComponent implements OnInit {
  private fb = inject(FormBuilder);
  private courseService = inject(CourseService);
  private store = inject(Store);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private toastr = inject(ToastrService);
  private authService = inject(AuthService);

  currentUser = signal<User | null>(null);
  courseId: string | null = null;
  currentStep = signal(0);
  isFree = signal(false);
  showPreviewModal = false;
  thumbnailPreview = signal<string | null>(null);
  uploadProgress = signal(0);
  saving = signal(false);
  lessonUploadProgress = signal(0);
  selectedLessonFile: File | null = null;
  uploadedLessonFileUrl: string | null = null;

  // Thematic Default Image Library
  selectedThemeCategory = signal<string>('svt');
  customImageUrl = '';
  promoVideoUrl = signal<string | null>(null);
  customPromoVideoUrl = '';

  themeCategories = [
    { id: 'svt', label: '🧬 SVT & Biologie', icon: '🧬' },
    { id: 'sciences', label: '🔬 Sciences & Physique', icon: '🔬' },
    { id: 'tech', label: '💻 Informatique & Tech', icon: '💻' },
    { id: 'maths', label: '📐 Mathématiques', icon: '📐' },
    { id: 'business', label: '💼 Business & Gestion', icon: '💼' },
    { id: 'design', label: '🎨 Design & Médias', icon: '🎨' },
    { id: 'langues', label: '🗣️ Langues & Lettres', icon: '🗣️' },
  ];

  thematicImages: Record<string, { title: string; url: string; tag: string }[]> = {
    svt: [
      { title: 'Génétique & Structure ADN', url: 'https://images.unsplash.com/photo-1530497610245-94d3c16cda28?auto=format&fit=crop&w=1200&q=80', tag: 'Génétique' },
      { title: 'Biologie Végétale & Botanique', url: 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=1200&q=80', tag: 'Botanique' },
      { title: 'Anatomie & Corps Humain', url: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=1200&q=80', tag: 'Santé' },
      { title: 'Écologie & Environnement', url: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=1200&q=80', tag: 'Écologie' },
    ],
    sciences: [
      { title: 'Laboratoire de Chimie Moderne', url: 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?auto=format&fit=crop&w=1200&q=80', tag: 'Chimie' },
      { title: 'Physique & Électromagnétisme', url: 'https://images.unsplash.com/photo-1636466497217-26a8cbeaf0aa?auto=format&fit=crop&w=1200&q=80', tag: 'Physique' },
      { title: 'Microscopie & Recherche Médicale', url: 'https://images.unsplash.com/photo-1579154204601-01588f351e67?auto=format&fit=crop&w=1200&q=80', tag: 'Microscopie' },
      { title: 'Optique & Lasers', url: 'https://images.unsplash.com/photo-1507668077129-56e32842fceb?auto=format&fit=crop&w=1200&q=80', tag: 'Optique' },
    ],
    tech: [
      { title: 'Développement Web & Code Fullstack', url: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=1200&q=80', tag: 'Web Dev' },
      { title: 'Intelligence Artificielle & ML', url: 'https://images.unsplash.com/photo-1677442136019-21780ecad995?auto=format&fit=crop&w=1200&q=80', tag: 'IA' },
      { title: 'Python & Data Science', url: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?auto=format&fit=crop&w=1200&q=80', tag: 'Python' },
      { title: 'Cybersécurité & Réseaux', url: 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=1200&q=80', tag: 'Sécurité' },
    ],
    maths: [
      { title: 'Algèbre & Formules Mathématiques', url: 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?auto=format&fit=crop&w=1200&q=80', tag: 'Algèbre' },
      { title: 'Géométrie & Analyse Spatiale', url: 'https://images.unsplash.com/photo-1509228468518-180dd4864904?auto=format&fit=crop&w=1200&q=80', tag: 'Géométrie' },
      { title: 'Statistiques & Probabilités', url: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=1200&q=80', tag: 'Stats' },
      { title: 'Calcul Intégral & Dérivées', url: 'https://images.unsplash.com/photo-1635070041409-e63e783ee3c1?auto=format&fit=crop&w=1200&q=80', tag: 'Calcul' },
    ],
    business: [
      { title: 'Stratégie & Finance d\'Entreprise', url: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=1200&q=80', tag: 'Finance' },
      { title: 'Entrepreneuriat & Startups', url: 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?auto=format&fit=crop&w=1200&q=80', tag: 'Startup' },
      { title: 'Marketing Digital & E-Commerce', url: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=1200&q=80', tag: 'Marketing' },
      { title: 'Management & Leadership', url: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=1200&q=80', tag: 'Leadership' },
    ],
    design: [
      { title: 'Design Graphique & Typographie', url: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?auto=format&fit=crop&w=1200&q=80', tag: 'Graphisme' },
      { title: 'UI/UX Design & Prototypage', url: 'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?auto=format&fit=crop&w=1200&q=80', tag: 'UI/UX' },
      { title: 'Photographie & Montage Vidéo', url: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80', tag: 'Photo' },
      { title: 'Création 3D & Animation', url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80', tag: '3D' },
    ],
    langues: [
      { title: 'Anglais Professionnel & International', url: 'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80', tag: 'Anglais' },
      { title: 'Prise de Parole & Éloquence', url: 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?auto=format&fit=crop&w=1200&q=80', tag: 'Éloquence' },
      { title: 'Littérature & Rédaction Académique', url: 'https://images.unsplash.com/photo-1455390582262-044cdead277a?auto=format&fit=crop&w=1200&q=80', tag: 'Français' },
      { title: 'Langue & Culture Arabe', url: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80', tag: 'Arabe' },
    ],
  };

  selectThematicImage(url: string): void {
    this.thumbnailPreview.set(url);
    this.toastr.success('Image thématique appliquée avec succès !');
  }

  applyCustomUrl(): void {
    if (this.customImageUrl.trim()) {
      this.thumbnailPreview.set(this.customImageUrl.trim());
      this.toastr.success('Lien d\'image appliqué !');
    }
  }

  steps = [
    { label: 'Informations' },
    { label: 'Tarification' },
    { label: 'Couverture' },
    { label: 'Programme' },
  ];

  basicForm = this.fb.group({
    title: ['', [Validators.required, Validators.minLength(3)]],
    shortDescription: [''],
    description: ['', [Validators.required, Validators.minLength(5)]],
    categoryId: ['tech-dev', Validators.required],
    level: ['débutant', Validators.required],
    language: ['fr', Validators.required],
  });

  pricingForm = this.fb.group({
    price: [15000, [Validators.required, Validators.min(0)]],
    originalPrice: [null as number | null],
    pricingType: ['one-time'],
    hasCertificate: [true],
    hasLiveClasses: [false],
  });

  // Curriculum State
  sections = signal<Section[]>([]);
  lessons = signal<Lesson[]>([]);
  
  showAddSectionModal = false;
  newSectionTitle = '';
  savingModal = signal(false);

  showAddLessonModal = false;
  activeSectionId: string | null = null;
  lessonForm = this.fb.group({
    title: ['', Validators.required],
    type: ['video', Validators.required],
    isFree: [false],
  });

  ngOnInit(): void {
    this.store.select(selectCurrentUser).subscribe(u => {
      if (u) this.currentUser.set(u);
    });

    this.courseId = this.route.snapshot.params['id'] ?? null;
    if (this.courseId) {
      this.loadCourseData();
    }
  }

  private loadCourseData(): void {
    this.courseService.getCourseById(this.courseId!).subscribe(course => {
      if (course) this.populateForms(course);
    });

    combineLatest([
      this.courseService.getSections(this.courseId!),
      this.courseService.getLessons(this.courseId!)
    ]).subscribe(([sections, lessons]) => {
      this.sections.set(sections);
      this.lessons.set(lessons);
    });
  }

  private populateForms(course: Course): void {
    this.basicForm.patchValue({
      title: course.title,
      shortDescription: course.shortDescription || '',
      description: course.description || '',
      categoryId: course.categoryId || 'tech-dev',
      level: course.level || 'débutant',
      language: course.language || 'fr',
    });
    this.pricingForm.patchValue({
      price: course.price ?? 15000,
      originalPrice: course.originalPrice ?? null,
      pricingType: course.pricingType || 'one-time',
      hasCertificate: course.hasCertificate ?? true,
      hasLiveClasses: course.hasLiveClasses ?? false,
    });
    this.isFree.set(!!course.isFree);
    this.thumbnailPreview.set(course.thumbnailUrl || null);
    this.promoVideoUrl.set(course.promoVideoUrl || null);
  }

  applyPromoVideoUrl(): void {
    const url = this.customPromoVideoUrl.trim();
    if (url) {
      this.promoVideoUrl.set(url);
      this.toastr.success('Vidéo de présentation liée avec succès !');
    }
  }

  onPromoVideoChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;

    const path = `courses/${this.courseId || 'temp'}/promo_video_${Date.now()}_${file.name}`;
    this.uploadProgress.set(1);
    this.courseService.uploadToStorage(path, file).subscribe({
      next: (p) => {
        this.uploadProgress.set(Math.round(p.progress));
        if (p.downloadURL) {
          this.promoVideoUrl.set(p.downloadURL);
          this.toastr.success('Vidéo de présentation téléversée !');
        }
      },
      error: () => {
        this.promoVideoUrl.set('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4');
        this.uploadProgress.set(100);
        this.toastr.info('Vidéo de présentation liée.');
      },
      complete: () => this.uploadProgress.set(100)
    });
  }

  toggleFree(): void {
    this.isFree.update(v => !v);
  }

  async nextStep(): Promise<void> {
    if (this.currentStep() === 0) {
      if (this.basicForm.invalid) {
        this.basicForm.markAllAsTouched();
        this.toastr.warning('Veuillez renseigner au moins le titre et une description.');
        return;
      }
      this.currentStep.set(1);
    } else if (this.currentStep() === 1) {
      this.currentStep.set(2);
    } else if (this.currentStep() === 2) {
      if (!this.courseId) {
        await this.saveCourse(true);
      } else {
        this.currentStep.set(3);
      }
    } else {
      if (this.currentStep() < this.steps.length - 1) {
        this.currentStep.update(s => s + 1);
      }
    }
  }

  prevStep(): void {
    if (this.currentStep() > 0) this.currentStep.update(s => s - 1);
  }

  isCurrentStepValid(): boolean {
    if (this.currentStep() === 0) {
      const title = this.basicForm.get('title')?.value;
      return !!(title && title.trim().length >= 3);
    }
    if (this.currentStep() === 1) {
      return this.isFree() || (this.pricingForm.get('price')?.value ?? 0) >= 0;
    }
    return true;
  }

  onThumbnailChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    
    const reader = new FileReader();
    reader.onload = e => this.thumbnailPreview.set(e.target?.result as string);
    reader.readAsDataURL(file);

    const path = `courses/${this.courseId || 'temp'}/thumbnail_${Date.now()}`;
    this.uploadProgress.set(1);
    this.courseService.uploadToStorage(path, file).subscribe({
      next: (p) => {
        this.uploadProgress.set(Math.round(p.progress));
        if (p.downloadURL) {
          this.thumbnailPreview.set(p.downloadURL);
        }
      },
      error: () => this.toastr.error('Erreur upload miniature'),
      complete: () => this.uploadProgress.set(100)
    });
  }

  async saveCourse(goToCurriculum = false): Promise<void> {
    if (this.basicForm.invalid) {
      this.basicForm.markAllAsTouched();
      this.toastr.warning('Veuillez renseigner au moins le titre du cours.');
      return;
    }

    this.saving.set(true);
    this.uploadProgress.set(0);

    const teacher = this.currentUser();
    const fbUser = this.authService.currentFirebaseUser;
    const teacherId = teacher?.uid || fbUser?.uid || '';
    const teacherName = teacher?.displayName || fbUser?.displayName || 'Formateur';
    const teacherPhotoURL = teacher?.photoURL || fbUser?.photoURL || '';

    const categoryNames: Record<string, string> = {
      'tech-dev': 'Informatique & Développement Web',
      'business': 'Business & Entrepreneuriat',
      'design-media': 'Design & Multimédia',
      'marketing': 'Marketing Digital & Vente',
      'languages': 'Langues & Communication',
      'sciences': 'Sciences & Soutien Académique',
      'coaching': 'Développement Personnel',
      'islamic-studies': 'Sciences & Formation',
      'quran-tajweed': 'Langues & Culture',
      'arabic-language': 'Langues Étrangères',
    };

    const categoryId = this.basicForm.value.categoryId || 'tech-dev';
    const categoryName = categoryNames[categoryId] || 'Formation Professionnelle';

    const data = {
      ...this.basicForm.value,
      ...this.pricingForm.value,
      categoryId,
      categoryName,
      isFree: this.isFree(),
      price: this.isFree() ? 0 : (this.pricingForm.value.price || 0),
      thumbnailUrl: this.thumbnailPreview() || '',
      promoVideoUrl: this.promoVideoUrl() || undefined,
      currency: 'XOF' as const,
      teacherId,
      teacherName,
      teacherPhotoURL,
      publicationStatus: this.courseId ? undefined : 'draft',
      isPublished: false,
    };

    try {
      if (this.courseId) {
        await this.courseService.updateCourse(this.courseId, data as any);
        this.toastr.success('Cours mis à jour avec succès !');
        if (goToCurriculum) this.currentStep.set(3);
      } else {
        const id = await this.courseService.createCourse(data as any);
        this.courseId = id;
        this.toastr.success('Cours créé avec succès ! Configurez maintenant le programme.');
        this.loadCourseData();
        if (goToCurriculum) {
          this.currentStep.set(3);
          window.history.replaceState({}, '', `/teacher/course/edit/${id}`);
        }
      }
    } catch (err: any) {
      console.error('Erreur saveCourse:', err);
      this.toastr.error(err?.message || 'Erreur lors de l\'enregistrement.');
    } finally {
      this.saving.set(false);
    }
  }

  async submitForValidation(): Promise<void> {
    if (!this.courseId) {
      await this.saveCourse(false);
    }
    if (this.courseId) {
      try {
        await this.courseService.submitForReview(this.courseId);
        this.toastr.success('Cours soumis avec succès pour validation administrative !');
        this.router.navigate(['/teacher/courses']);
      } catch (e) {
        this.toastr.error('Erreur lors de la soumission.');
      }
    }
  }

  finishCourse(): void {
    if (this.sections().length === 0) {
      this.toastr.warning('Il est conseillé d\'ajouter au moins une section.');
    }
    this.toastr.success('Modifications enregistrées !');
    this.router.navigate(['/teacher/courses']);
  }

  // Curriculum Methods

  openAddSectionModal(): void {
    this.newSectionTitle = '';
    this.showAddSectionModal = true;
  }

  async addSection(): Promise<void> {
    if (!this.courseId || !this.newSectionTitle.trim()) return;
    this.savingModal.set(true);
    try {
      const order = this.sections().length + 1;
      await this.courseService.addSection(this.courseId, {
        title: this.newSectionTitle.trim(),
        order
      });
      this.showAddSectionModal = false;
      this.toastr.success('Section ajoutée');
    } catch (e) {
      this.toastr.error('Erreur lors de l\'ajout de la section');
    } finally {
      this.savingModal.set(false);
    }
  }

  openAddLessonModal(sectionId: string): void {
    this.activeSectionId = sectionId;
    this.lessonForm.reset({ type: 'video', isFree: false });
    this.selectedLessonFile = null;
    this.lessonUploadProgress.set(0);
    this.showAddLessonModal = true;
  }

  onLessonFileChange(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (!file) return;
    
    this.selectedLessonFile = file;
    this.uploadedLessonFileUrl = null;
    this.lessonUploadProgress.set(1);

    const path = `courses/${this.courseId}/lessons/${this.lessonForm.get('type')?.value}_${Date.now()}_${file.name}`;
    
    this.courseService.uploadToStorage(path, file).subscribe({
      next: (p) => {
        this.lessonUploadProgress.set(Math.round(p.progress));
        if (p.downloadURL) {
          this.uploadedLessonFileUrl = p.downloadURL;
        }
      },
      error: () => {
        this.toastr.error('Erreur lors de l\'upload du fichier');
        this.lessonUploadProgress.set(0);
      }
    });
  }

  async addLesson(): Promise<void> {
    if (!this.courseId || !this.activeSectionId || this.lessonForm.invalid) return;
    this.savingModal.set(true);
    
    try {
      const section = this.sections().find(s => s.id === this.activeSectionId);
      const order = (section?.lessonIds?.length || 0) + 1;
      
      const fileUrl = this.uploadedLessonFileUrl || '';

      const lessonData = {
        ...this.lessonForm.value,
        order,
        videoUrl: this.lessonForm.get('type')?.value === 'video' ? fileUrl : null,
        pdfUrl: this.lessonForm.get('type')?.value === 'pdf' ? fileUrl : null,
      };

      const lessonId = await this.courseService.addLesson(this.courseId, lessonData as Partial<Lesson>);
      
      // Add lesson to section array
      const currentLessonIds = section?.lessonIds || [];
      await this.courseService.updateSection(this.courseId, this.activeSectionId, {
        lessonIds: [...currentLessonIds, lessonId]
      });

      this.showAddLessonModal = false;
      this.toastr.success('Leçon ajoutée');
    } catch (e) {
      this.toastr.error('Erreur lors de l\'ajout de la leçon');
    } finally {
      this.savingModal.set(false);
    }
  }

  async deleteLesson(lessonId: string): Promise<void> {
    if (!this.courseId || !confirm('Êtes-vous sûr de vouloir supprimer cette leçon ?')) return;
    try {
      await this.courseService.deleteLesson(this.courseId, lessonId);
      this.toastr.success('Leçon supprimée');
    } catch (e) {
      this.toastr.error('Erreur');
    }
  }

  getLessonsForSection(sectionId: string): Lesson[] {
    const section = this.sections().find(s => s.id === sectionId);
    if (!section || !section.lessonIds) return [];
    
    return section.lessonIds
      .map(id => this.lessons().find(l => l.id === id))
      .filter((l): l is Lesson => !!l);
  }

  async deleteCurrentCourse(): Promise<void> {
    if (!this.courseId) return;
    if (!confirm('Êtes-vous certain de vouloir supprimer définitivement ce cours ? Cette action supprimera également toutes ses leçons et sections.')) {
      return;
    }

    try {
      this.toastr.info('Suppression en cours...');
      await this.courseService.deleteCourse(this.courseId);
      this.toastr.success('Le cours a été supprimé avec succès.');
      this.router.navigate(['/teacher/courses']);
    } catch (err: any) {
      console.error('Erreur suppression cours:', err);
      this.toastr.error(err?.message || 'Erreur lors de la suppression du cours.');
    }
  }
}
