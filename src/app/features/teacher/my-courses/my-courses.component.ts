import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { AsyncPipe, DecimalPipe, DatePipe, TitleCasePipe, CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { CourseService } from '../../../core/services/course.service';
import { Course, CoursePublicationStatus } from '../../../core/models';
import { switchMap, of } from 'rxjs';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-teacher-courses',
  standalone: true,
  imports: [RouterLink, AsyncPipe, DecimalPipe, DatePipe, TitleCasePipe, CommonModule, FormsModule],
  template: `
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 space-y-8">
      
      <!-- Header -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 shadow-xs">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider mb-1">
            <span>●</span> Gestion du Catalogue
          </div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-light tracking-tight">Mes Cours & Formations</h1>
          <p class="text-xs sm:text-sm text-light-muted mt-1">Gérez l'ensemble de votre catalogue, suivez le statut de validation et analysez les performances.</p>
        </div>
        <div class="flex items-center gap-3 shrink-0">
          <a routerLink="/teacher/course/new" class="px-5 py-2.5 bg-primary hover:bg-primary-600 text-white text-xs font-bold rounded-xl shadow-md shadow-primary/25 flex items-center gap-2 active:scale-95 transition-all">
            <span class="text-base font-bold leading-none">+</span>
            <span>Créer un cours</span>
          </a>
        </div>
      </div>

      <!-- Quick KPI Counters -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Total Formations</p>
          <div class="flex items-end gap-3 mt-2">
            <p class="font-display text-3xl font-black text-light">{{ courses().length }}</p>
            <p class="text-[11px] text-primary font-bold mb-1">créés</p>
          </div>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">En Ligne / Publiés</p>
          <div class="flex items-end gap-3 mt-2">
            <p class="font-display text-3xl font-black text-emerald-600">{{ publishedCount() }}</p>
            <p class="text-[11px] text-emerald-600 font-bold mb-1">au catalogue</p>
          </div>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">En Validation</p>
          <div class="flex items-end gap-3 mt-2">
            <p class="font-display text-3xl font-black text-amber-500">{{ pendingCount() }}</p>
            <p class="text-[11px] text-amber-600 font-bold mb-1">en attente</p>
          </div>
        </div>
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <p class="text-xs font-bold text-light-muted uppercase tracking-wider">Total Étudiants</p>
          <div class="flex items-end gap-3 mt-2">
            <p class="font-display text-3xl font-black text-light">{{ totalStudents() | number }}</p>
            <p class="text-[11px] text-primary font-bold mb-1">apprenants</p>
          </div>
        </div>
      </div>

      <!-- Filters & Search Bar -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-dark-border shadow-xs">
        <div class="flex items-center gap-2 overflow-x-auto pb-1 sm:pb-0">
          <button (click)="filterStatus.set('all')"
                  [class]="filterStatus() === 'all' ? 'bg-primary text-white font-bold' : 'bg-dark-surface2 text-light-muted hover:text-light'"
                  class="px-3.5 py-1.5 rounded-xl text-xs transition-all whitespace-nowrap">
            Tous ({{ courses().length }})
          </button>
          <button (click)="filterStatus.set('published')"
                  [class]="filterStatus() === 'published' ? 'bg-emerald-600 text-white font-bold' : 'bg-dark-surface2 text-light-muted hover:text-light'"
                  class="px-3.5 py-1.5 rounded-xl text-xs transition-all whitespace-nowrap">
            Publiés ({{ publishedCount() }})
          </button>
          <button (click)="filterStatus.set('pending_approval')"
                  [class]="filterStatus() === 'pending_approval' ? 'bg-amber-500 text-white font-bold' : 'bg-dark-surface2 text-light-muted hover:text-light'"
                  class="px-3.5 py-1.5 rounded-xl text-xs transition-all whitespace-nowrap">
            En validation ({{ pendingCount() }})
          </button>
          <button (click)="filterStatus.set('draft')"
                  [class]="filterStatus() === 'draft' ? 'bg-slate-700 text-white font-bold' : 'bg-dark-surface2 text-light-muted hover:text-light'"
                  class="px-3.5 py-1.5 rounded-xl text-xs transition-all whitespace-nowrap">
            Brouillons ({{ draftCount() }})
          </button>
        </div>

        <div class="relative min-w-[240px]">
          <input type="text" [(ngModel)]="searchQuery" placeholder="Rechercher une formation..."
                 class="w-full pl-9 pr-4 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:outline-none focus:border-primary">
          <svg class="w-4 h-4 text-light-muted absolute left-3 top-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>
      </div>

      <!-- Cards Grid (Requirement 6) -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        @for (course of filteredCourses(); track course.id) {
          <div class="rounded-3xl border border-dark-border bg-white overflow-hidden shadow-xs hover:shadow-xl transition-all duration-300 flex flex-col group">
            
            <!-- Cover & Badges -->
            <div class="relative h-48 bg-dark-surface2 overflow-hidden border-b border-dark-border/60">
              @if (course.thumbnailUrl) {
                <img loading="lazy" decoding="async" [src]="course.thumbnailUrl" [alt]="course.title" class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500">
              } @else {
                <div class="w-full h-full flex items-center justify-center text-4xl bg-gradient-to-br from-primary/15 to-blue-500/10">
                  📖
                </div>
              }

              <!-- Status Badge -->
              <div class="absolute top-3 left-3">
                <span [class]="getStatusClass(course)"
                      class="px-3 py-1 rounded-full text-[10px] font-black tracking-wider uppercase shadow-xs border">
                  {{ getStatusLabel(course) }}
                </span>
              </div>

              <!-- Price Badge -->
              <div class="absolute top-3 right-3">
                <span class="px-3 py-1 rounded-full text-xs font-black bg-white/95 text-light shadow-md backdrop-blur-sm border border-dark-border">
                  {{ course.isFree ? 'Gratuit' : ((course.price | number) + ' F') }}
                </span>
              </div>
            </div>

            <!-- Content Area -->
            <div class="p-5 flex-1 flex flex-col justify-between space-y-4">
              <div>
                <div class="flex items-center gap-2 text-[10px] font-bold text-light-muted uppercase tracking-wider mb-1">
                  <span>{{ course.categoryName || 'Formation' }}</span>
                  <span>•</span>
                  <span>{{ course.level | titlecase }}</span>
                </div>
                <h3 class="font-display font-bold text-light text-base line-clamp-2 group-hover:text-primary transition-colors">
                  {{ course.title }}
                </h3>
              </div>

              <!-- 4 Metrics per Card (Requirement 6) -->
              <div class="grid grid-cols-3 gap-2 py-3 border-y border-dark-border/60 bg-dark-surface2/30 rounded-2xl px-3 text-center">
                <div>
                  <p class="text-[10px] text-light-muted font-medium">Étudiants</p>
                  <p class="text-xs font-black text-light mt-0.5 inline-flex items-center justify-center gap-1">
                    <svg class="w-3.5 h-3.5 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
                    </svg>
                    <span>{{ course.enrolledCount | number }}</span>
                  </p>
                </div>
                <div>
                  <p class="text-[10px] text-light-muted font-medium">Vues</p>
                  <p class="text-xs font-black text-light mt-0.5 inline-flex items-center justify-center gap-1">
                    <svg class="w-3.5 h-3.5 text-cyan-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                    </svg>
                    <span>{{ (course.viewsCount || 0) | number }}</span>
                  </p>
                </div>
                <div>
                  <p class="text-[10px] text-light-muted font-medium">Note</p>
                  <p class="text-xs font-black text-amber-500 mt-0.5 inline-flex items-center justify-center gap-1">
                    <svg class="w-3.5 h-3.5 fill-amber-400 stroke-amber-400" viewBox="0 0 24 24">
                      <path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/>
                    </svg>
                    <span>{{ course.rating || '5.0' }}</span>
                  </p>
                </div>
              </div>

              <!-- Card Actions (Requirement 6) -->
              <div class="flex items-center justify-between gap-2 pt-2">
                <div class="flex items-center gap-1">
                  <!-- Edit -->
                  <a [routerLink]="['/teacher/course/edit', course.id]"
                     title="Modifier le cours"
                     class="p-2 rounded-xl border border-dark-border hover:bg-dark-surface2 text-light-muted hover:text-primary transition-all">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
                    </svg>
                  </a>

                  <!-- Public preview -->
                  <a [routerLink]="['/course', course.id]"
                     target="_blank"
                     title="Voir la page publique"
                     class="p-2 rounded-xl border border-dark-border hover:bg-dark-surface2 text-light-muted hover:text-emerald-600 transition-all">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
                    </svg>
                  </a>

                  <!-- Duplicate -->
                  <button (click)="duplicateCourse(course.id)"
                          title="Dupliquer le cours"
                          class="p-2 rounded-xl border border-dark-border hover:bg-dark-surface2 text-light-muted hover:text-blue-600 transition-all">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2"/>
                    </svg>
                  </button>

                  <!-- Stats modal trigger -->
                  <button (click)="openStatsModal(course)"
                          title="Statistiques détaillées"
                          class="p-2 rounded-xl border border-dark-border hover:bg-dark-surface2 text-light-muted hover:text-purple-600 transition-all">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                    </svg>
                  </button>

                  <!-- Delete -->
                  <button (click)="deleteCourse(course.id)"
                          title="Supprimer"
                          class="p-2 rounded-xl border border-dark-border hover:bg-red-50 text-light-muted hover:text-red-600 transition-all">
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                    </svg>
                  </button>
                </div>

                <!-- Publish / Submit Button -->
                <div>
                  @if (!course.isPublished && course.publicationStatus !== 'pending_approval') {
                    <button (click)="submitForApproval(course)"
                            class="px-3 py-1.5 rounded-xl bg-primary hover:bg-primary-600 text-white text-[11px] font-bold shadow-xs transition-all">
                      Soumettre
                    </button>
                  } @else if (course.isPublished) {
                    <button (click)="unpublishCourse(course)"
                            class="px-3 py-1.5 rounded-xl border border-dark-border hover:bg-dark-surface2 text-light text-[11px] font-bold transition-all">
                      Dépublier
                    </button>
                  }
                </div>
              </div>

            </div>
          </div>
        } @empty {
          <div class="col-span-full text-center py-20 bg-white border border-dashed border-dark-border rounded-3xl shadow-xs">
            <div class="text-4xl mb-3">📚</div>
            <h3 class="font-display text-base font-bold text-light">Aucun cours correspondant</h3>
            <p class="text-xs text-light-muted mt-1 mb-6">Commencez dès maintenant à partager vos compétences.</p>
            <a routerLink="/teacher/course/new" class="px-5 py-2.5 bg-primary text-white text-xs font-bold rounded-xl shadow-md shadow-primary/25 inline-block">
              Créer mon premier cours
            </a>
          </div>
        }
      </div>

      <!-- Quick Stats Modal -->
      @if (selectedCourseStats()) {
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200"
             (click)="selectedCourseStats.set(null)">
          <div class="relative w-full max-w-lg bg-white rounded-3xl p-6 sm:p-8 shadow-2xl border border-dark-border space-y-6"
               (click)="$event.stopPropagation()">
            
            <div class="flex items-center justify-between border-b border-dark-border pb-4">
              <div>
                <span class="text-[10px] font-bold text-primary uppercase tracking-wider">Statistiques de formation</span>
                <h2 class="font-display text-lg font-bold text-light truncate max-w-xs">{{ selectedCourseStats()?.title }}</h2>
              </div>
              <button (click)="selectedCourseStats.set(null)" class="text-light-muted hover:text-light p-2 rounded-xl hover:bg-dark-surface2">
                ✕
              </button>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="p-4 rounded-2xl bg-dark-surface2/60 border border-dark-border/40">
                <p class="text-xs text-light-muted">Inscriptions</p>
                <p class="font-display text-2xl font-black text-light mt-1">{{ selectedCourseStats()?.enrolledCount | number }}</p>
              </div>
              <div class="p-4 rounded-2xl bg-dark-surface2/60 border border-dark-border/40">
                <p class="text-xs text-light-muted">Vues de la page</p>
                <p class="font-display text-2xl font-black text-light mt-1">{{ (selectedCourseStats()?.viewsCount || 0) | number }}</p>
              </div>
              <div class="p-4 rounded-2xl bg-dark-surface2/60 border border-dark-border/40">
                <p class="text-xs text-light-muted">Prix unitaire</p>
                <p class="font-display text-2xl font-black text-primary mt-1">{{ selectedCourseStats()?.price | number }} F</p>
              </div>
              <div class="p-4 rounded-2xl bg-dark-surface2/60 border border-dark-border/40">
                <p class="text-xs text-light-muted">Note globale</p>
                <p class="font-display text-2xl font-black text-amber-500 mt-1">⭐ {{ selectedCourseStats()?.rating || '—' }}</p>
              </div>
            </div>

            <div class="text-right pt-2">
              <button (click)="selectedCourseStats.set(null)" class="px-5 py-2 rounded-xl bg-dark-surface2 text-xs font-bold text-light hover:bg-dark-border">
                Fermer
              </button>
            </div>
          </div>
        </div>
      }

    </div>
  `,
})
export class TeacherMyCoursesComponent implements OnInit {
  private store = inject(Store);
  private courseService = inject(CourseService);
  private toastr = inject(ToastrService);

  user$ = this.store.select(selectCurrentUser);
  courses = signal<Course[]>([]);
  filterStatus = signal<string>('all');
  searchQuery = '';
  selectedCourseStats = signal<Course | null>(null);

  publishedCount = computed(() => this.courses().filter(c => c.isPublished || c.publicationStatus === 'published').length);
  pendingCount = computed(() => this.courses().filter(c => c.publicationStatus === 'pending_approval').length);
  draftCount = computed(() => this.courses().filter(c => !c.isPublished && c.publicationStatus !== 'pending_approval').length);
  totalStudents = computed(() => this.courses().reduce((sum, c) => sum + (c.enrolledCount || 0), 0));

  filteredCourses = computed(() => {
    let list = this.courses();
    const filter = this.filterStatus();
    if (filter === 'published') {
      list = list.filter(c => c.isPublished || c.publicationStatus === 'published');
    } else if (filter === 'pending_approval') {
      list = list.filter(c => c.publicationStatus === 'pending_approval');
    } else if (filter === 'draft') {
      list = list.filter(c => !c.isPublished && c.publicationStatus !== 'pending_approval');
    }

    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      list = list.filter(c => c.title.toLowerCase().includes(q) || (c.categoryName && c.categoryName.toLowerCase().includes(q)));
    }

    return list;
  });

  ngOnInit(): void {
    this.loadCourses();
  }

  loadCourses(): void {
    this.user$.pipe(
      switchMap(user => user ? this.courseService.getTeacherCourses(user.uid) : of([]))
    ).subscribe(courses => {
      this.courses.set(courses);
    });
  }

  getStatusLabel(course: Course): string {
    if (course.publicationStatus === 'pending_approval') return 'En validation';
    if (course.publicationStatus === 'rejected') return 'Refusé';
    if (course.publicationStatus === 'archived') return 'Archivé';
    if (course.isPublished || course.publicationStatus === 'published') return 'Publié';
    return 'Brouillon';
  }

  getStatusClass(course: Course): string {
    if (course.publicationStatus === 'pending_approval') return 'bg-amber-50 text-amber-700 border-amber-200';
    if (course.publicationStatus === 'rejected') return 'bg-red-50 text-red-700 border-red-200';
    if (course.publicationStatus === 'archived') return 'bg-slate-100 text-slate-700 border-slate-200';
    if (course.isPublished || course.publicationStatus === 'published') return 'bg-emerald-50 text-emerald-700 border-emerald-200';
    return 'bg-slate-100 text-slate-600 border-slate-200';
  }

  async duplicateCourse(courseId: string): Promise<void> {
    try {
      this.toastr.info('Duplication en cours...');
      this.user$.subscribe(async user => {
        if (!user) return;
        await this.courseService.duplicateCourse(courseId, user.uid);
        this.toastr.success('Copie du cours créée avec succès !');
        this.loadCourses();
      });
    } catch (e) {
      this.toastr.error('Erreur lors de la duplication.');
    }
  }

  async submitForApproval(course: Course): Promise<void> {
    try {
      await this.courseService.submitForReview(course.id);
      this.toastr.success('Cours soumis à la validation de l\'administration !');
      this.loadCourses();
    } catch (e) {
      this.toastr.error('Erreur lors de la soumission.');
    }
  }

  async unpublishCourse(course: Course): Promise<void> {
    try {
      await this.courseService.updateCourse(course.id, { isPublished: false, publicationStatus: 'draft' });
      this.toastr.info('Le cours a été remis en brouillon.');
      this.loadCourses();
    } catch (e) {
      this.toastr.error('Erreur lors de la modification.');
    }
  }

  openStatsModal(course: Course): void {
    this.selectedCourseStats.set(course);
  }

  async deleteCourse(id: string): Promise<void> {
    if (!confirm('Êtes-vous sûr de vouloir supprimer définitivement ce cours ? Cette action est irréversible.')) {
      return;
    }

    try {
      this.toastr.info('Suppression en cours...');
      await this.courseService.deleteCourse(id);
      this.courses.update(list => list.filter(c => c.id !== id));
      this.toastr.success('Le cours a été supprimé avec succès !');
    } catch (err: any) {
      console.error('Erreur suppression cours:', err);
      this.toastr.error(err?.message || 'Erreur lors de la suppression du cours.');
    }
  }
}
