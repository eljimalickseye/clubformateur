import { Component, inject, OnInit, signal } from '@angular/core';
import { Title, Meta } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { AsyncPipe } from '@angular/common';
import { CourseCardComponent } from '../../shared/components/course-card/course-card.component';
import { CourseService } from '../../core/services/course.service';
import { Firestore, collection, collectionData, orderBy, query } from '@angular/fire/firestore';
import { Course, Category } from '../../core/models';
import { Observable } from 'rxjs';
import { BackButtonComponent } from '../../shared/components/back-button/back-button.component';
import { RefreshButtonComponent } from '../../shared/components/refresh-button/refresh-button.component';
import { TeachersCarouselComponent } from '../../shared/components/teachers-carousel/teachers-carousel.component';

@Component({
  selector: 'app-catalogue',
  standalone: true,
  imports: [
    FormsModule,
    AsyncPipe,
    CourseCardComponent,
    BackButtonComponent,
    RefreshButtonComponent,
    TeachersCarouselComponent
  ],
  template: `
    <div class="relative overflow-hidden pt-4 pb-12 sm:pt-8 sm:pb-20 font-body">
      <!-- Hero Section / Header -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
        <!-- PWA / Mobile Back & Refresh Navigation -->
        <div class="mb-4 flex items-center justify-between">
          <app-back-button label="Retour" defaultRoute="/" variant="light" />
          <app-refresh-button label="Actualiser" variant="light" />
        </div>

        <div class="text-center mb-8 sm:mb-12 animate-in fade-in slide-in-from-bottom-8 duration-700">
          <p class="text-xs sm:text-sm font-bold text-primary uppercase tracking-[0.2em] mb-3">Club des Formateurs • Catalogue Officiel</p>
          <h1 class="font-display text-3xl sm:text-5xl lg:text-6xl font-black text-light mb-4 tracking-tight">
            Découvrez nos <span class="text-gradient">Formations & Professeurs</span>
          </h1>
          <p class="max-w-2xl mx-auto text-light-muted text-xs sm:text-base leading-relaxed mb-8">
            Apprenez avec les formateurs les plus réputés du réseau. Visionnez leurs capsules de présentation, consultez leurs disponibilités et accédez à leurs programmes d'excellence.
          </p>

          <!-- Integrated Search Bar -->
          <div class="max-w-xl mx-auto relative group">
            <div class="absolute inset-y-0 left-4 flex items-center pointer-events-none transition-transform duration-300 group-focus-within:scale-110">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" class="text-primary/60">
                <circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line>
              </svg>
            </div>
            <input type="text" [(ngModel)]="searchQuery" (ngModelChange)="applyFilters()"
                   placeholder="Rechercher un cours, un sujet ou un professeur..."
                   class="w-full pl-12 pr-4 py-3.5 sm:py-4 bg-dark-surface/50 backdrop-blur-xl border border-dark-border rounded-2xl
                          text-light placeholder-light-muted/60 text-xs sm:text-sm shadow-xl focus:ring-4 focus:ring-primary/10 transition-all outline-none">
          </div>
        </div>

        <!-- ────────────────────────────────────────────────────────── -->
        <!-- CARROUSEL DYNAMIQUE DES PROFESSEURS & EMPLOIS DU TEMPS     -->
        <!-- ────────────────────────────────────────────────────────── -->
        <div class="mb-10 sm:mb-14">
          <app-teachers-carousel (teacherSelected)="filterByTeacher($event)" />
        </div>

        <!-- Active Teacher Filter Badge (if any) -->
        @if (selectedTeacherName()) {
          <div class="mb-8 p-3.5 px-5 bg-primary/10 border border-primary/20 rounded-2xl flex flex-col sm:flex-row items-center justify-between gap-3 shadow-xs">
            <div class="flex items-center gap-2.5 text-xs sm:text-sm font-bold text-primary">
              <div class="w-7 h-7 rounded-lg bg-primary/20 flex items-center justify-center text-primary shrink-0">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
              </div>
              <span>Filtré par professeur : <strong>{{ selectedTeacherName() }}</strong> ({{ filteredCourses().length }} cours trouvé{{ filteredCourses().length > 1 ? 's' : '' }})</span>
            </div>
            <button (click)="clearTeacherFilter()"
                    class="text-xs font-bold text-red-600 hover:text-red-700 bg-white px-3 py-1.5 rounded-xl border border-red-200 shadow-2xs cursor-pointer transition-all active:scale-95 inline-flex items-center gap-1.5">
              <svg class="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
              <span>Afficher tous les formateurs</span>
            </button>
          </div>
        }

        <!-- Categories Pill Filter (Top of Grid) -->
        <div class="mb-8 sm:mb-12">
          <div class="flex items-center gap-3 overflow-x-auto pb-3 no-scrollbar">
            <button (click)="selectedCategory.set(''); applyFilters()"
                    [class]="!selectedCategory() ? 'bg-primary text-white shadow-lg shadow-primary/20 scale-105' : 'bg-dark-surface border border-dark-border text-light-muted hover:text-light hover:border-primary/40'"
                    class="px-5 py-2 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer">
              Toutes les catégories
            </button>
            @for (cat of categories(); track cat.id) {
              <button (click)="selectedCategory.set(cat.id); applyFilters()"
                      [class]="selectedCategory() === cat.id ? 'bg-primary text-white shadow-lg shadow-primary/20 scale-105' : 'bg-dark-surface border border-dark-border text-light-muted hover:text-light hover:border-primary/40'"
                      class="px-5 py-2 rounded-xl text-xs font-bold transition-all whitespace-nowrap cursor-pointer">
                {{ cat.name }}
              </button>
            }
          </div>
        </div>

        <div class="flex flex-col lg:flex-row gap-8">
          <!-- Sidebar Filters (Advanced) -->
          <aside class="w-full lg:w-72 flex-shrink-0">
            <div class="bg-dark-surface/40 backdrop-blur-md border border-dark-border rounded-2xl p-6 lg:sticky lg:top-28">
              <div class="flex items-center justify-between mb-6">
                <h2 class="font-display font-black text-light uppercase tracking-wider text-xs">Filtres de recherche</h2>
                <button (click)="resetFilters()" class="text-xs font-bold text-primary hover:underline uppercase tracking-tight cursor-pointer">Réinitialiser</button>
              </div>

              <!-- Level -->
              <div class="mb-8">
                <h3 class="text-xs font-black text-light-muted uppercase tracking-wider mb-4">Niveau de difficulté</h3>
                <div class="space-y-3">
                  @for (level of levels; track level.value) {
                    <label class="flex items-center gap-3 cursor-pointer group">
                      <div class="relative flex items-center justify-center">
                        <input type="radio" [value]="level.value" [(ngModel)]="selectedLevel"
                               (ngModelChange)="applyFilters()" name="level" class="peer appearance-none w-5 h-5 border-2 border-dark-border rounded-full checked:border-primary transition-all">
                        <div class="absolute w-2.5 h-2.5 bg-primary rounded-full scale-0 peer-checked:scale-100 transition-transform"></div>
                      </div>
                      <span class="text-xs font-semibold text-light-muted group-hover:text-light transition-colors">{{ level.label }}</span>
                    </label>
                  }
                </div>
              </div>

              <!-- Price -->
              <div>
                <h3 class="text-xs font-black text-light-muted uppercase tracking-wider mb-4">Tarification</h3>
                <label class="flex items-center gap-3 cursor-pointer group">
                  <div class="relative flex items-center justify-center">
                    <input type="checkbox" [(ngModel)]="freeOnly" (ngModelChange)="applyFilters()" 
                           class="peer appearance-none w-5 h-5 border-2 border-dark-border rounded-lg checked:border-primary checked:bg-primary/20 transition-all">
                    <svg class="absolute w-3.5 h-3.5 text-primary scale-0 peer-checked:scale-100 transition-transform" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="4">
                      <path d="M5 13l4 4L19 7"></path>
                    </svg>
                  </div>
                  <span class="text-xs font-semibold text-light-muted group-hover:text-light transition-colors">Cours gratuits uniquement</span>
                </label>
              </div>
            </div>
          </aside>

          <!-- Course Grid -->
          <div class="flex-1">
            @if (loading()) {
              <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-2 2xl:grid-cols-3 gap-6">
                @for (i of [1,2,3,4,5,6]; track i) {
                  <div class="bg-dark-surface/50 border border-dark-border rounded-2xl overflow-hidden animate-pulse">
                    <div class="aspect-[16/10] bg-dark-surface2"></div>
                    <div class="p-6 space-y-4">
                      <div class="h-4 bg-dark-surface2 rounded w-1/4"></div>
                      <div class="h-6 bg-dark-surface2 rounded w-full"></div>
                      <div class="h-4 bg-dark-surface2 rounded w-2/3"></div>
                    </div>
                  </div>
                }
              </div>
            } @else if (filteredCourses().length > 0) {
              <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-2 2xl:grid-cols-3 gap-6">
                @for (course of filteredCourses(); track course.id) {
                  <app-course-card [course]="course" (playVideo)="openVideoModal($event)" />
                }
              </div>
            } @else {
              <div class="flex flex-col items-center justify-center py-24 rounded-3xl border border-dashed border-dark-border bg-dark-surface/20">
                <div class="w-16 h-16 rounded-full bg-dark-surface flex items-center justify-center text-3xl mb-4 shadow-inner">🔍</div>
                <p class="text-light text-base font-bold mb-1">Aucun cours trouvé</p>
                <p class="text-light-muted text-xs mb-6">Aucune formation ne correspond à vos critères actuels.</p>
                <button (click)="resetFilters()" class="btn-primary text-xs">
                  Effacer tous les filtres
                </button>
              </div>
            }
          </div>
        </div>
      </div>

      <!-- Decorative backgrounds -->
      <div class="absolute top-0 right-0 -translate-y-1/2 translate-x-1/4 w-[600px] h-[600px] bg-primary/10 rounded-full blur-[120px] pointer-events-none"></div>
      <div class="absolute bottom-0 left-0 translate-y-1/2 -translate-x-1/4 w-[500px] h-[500px] bg-blue-500/5 rounded-full blur-[100px] pointer-events-none"></div>
    </div>

    <!-- Video Modal for Courses -->
    @if (selectedCourse()) {
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in duration-300" (click)="closeVideoModal()">
        <div class="relative w-full max-w-4xl bg-dark-surface rounded-2xl overflow-hidden shadow-2xl border border-dark-border" (click)="$event.stopPropagation()">
          <div class="absolute top-4 right-4 z-10">
            <button (click)="closeVideoModal()" class="w-8 h-8 flex items-center justify-center rounded-full bg-black/50 text-white hover:bg-black/70 transition-colors cursor-pointer">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            </button>
          </div>
          
          <div class="aspect-video bg-black flex items-center justify-center relative select-none"
               (contextmenu)="$event.preventDefault()">
            
            <!-- Video Title Overlay -->
            <div class="absolute top-4 left-4 z-20 pointer-events-none select-none max-w-[70%]">
              <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/60 backdrop-blur-md border border-white/15 text-white shadow-lg">
                <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
                <h4 class="text-xs font-bold truncate text-white">{{ selectedCourse()?.title }}</h4>
              </div>
            </div>

            <!-- Watermark Logo Club des Formateurs at Bottom -->
            <div class="absolute bottom-12 right-4 sm:bottom-14 sm:right-6 z-20 pointer-events-none select-none flex items-center gap-2 px-3 py-1.5 rounded-xl bg-black/55 backdrop-blur-md border border-white/15 shadow-lg">
              <svg width="22" height="22" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" class="shrink-0">
                <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
                <circle cx="20" cy="20" r="4" fill="white"/>
              </svg>
              <span class="font-display text-[11px] font-black text-white tracking-tight drop-shadow-sm">
                Club des Formateurs
              </span>
            </div>

            @if (selectedCourse()?.promoVideoUrl) {
              <video [src]="selectedCourse()!.promoVideoUrl"
                     controls
                     autoplay
                     controlsList="nodownload"
                     (contextmenu)="$event.preventDefault()"
                     class="w-full h-full object-contain"></video>
            } @else {
              <div class="text-center p-8">
                <div class="w-12 h-12 mx-auto mb-4 rounded-2xl bg-white/10 flex items-center justify-center text-slate-400">
                  <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                </div>
                <h3 class="text-xl font-bold text-light mb-2">Présentation du cours</h3>
                <p class="text-light-muted">La vidéo de présentation n'est pas encore disponible pour ce cours.</p>
              </div>
            }
          </div>
          <div class="p-5">
            <h3 class="font-display text-xl font-bold text-light mb-1">{{ selectedCourse()?.title }}</h3>
            <p class="text-sm text-light-muted flex items-center gap-2">
              <img loading="lazy" decoding="async" [src]="selectedCourse()?.teacherPhotoURL || 'assets/images/default-avatar.png'" alt="avatar" class="w-5 h-5 rounded-full object-cover">
              Présenté par <span class="text-light">{{ selectedCourse()?.teacherName }}</span>
            </p>
          </div>
        </div>
      </div>
    }
  `,
})
export class CatalogueComponent implements OnInit {
  private courseService = inject(CourseService);
  private firestore = inject(Firestore);
  private titleService = inject(Title);
  private metaService = inject(Meta);

  allCourses = signal<Course[]>([]);
  filteredCourses = signal<Course[]>([]);
  categories = signal<Category[]>([]);
  loading = signal(true);
  selectedCourse = signal<Course | null>(null);

  searchQuery = '';
  selectedCategory = signal('');
  selectedTeacherId = signal('');
  selectedTeacherName = signal('');
  selectedLevel = '';
  freeOnly = false;

  levels = [
    { label: 'Tous les niveaux', value: '' },
    { label: 'Débutant', value: 'débutant' },
    { label: 'Intermédiaire', value: 'intermédiaire' },
    { label: 'Avancé', value: 'avancé' },
  ];

  ngOnInit(): void {
    // Load categories
    const catQ = query(collection(this.firestore, 'categories'), orderBy('order', 'asc'));
    (collectionData(catQ, { idField: 'id' }) as Observable<Category[]>).subscribe(cats => {
      this.categories.set(cats);
    });

    // Load all courses
    this.courseService.getCourses({}, 50).subscribe(courses => {
      this.allCourses.set(courses);
      this.applyFilters();
      this.loading.set(false);
      this.updateMetadata();
    });
  }

  private updateMetadata(): void {
    const catName = this.categories().find(c => c.id === this.selectedCategory())?.name;
    const title = catName ? `Formations en ${catName} – Club des Formateurs` : 'Catalogue des Formations – Club des Formateurs';
    this.titleService.setTitle(title);
    
    this.metaService.updateTag({ name: 'description', content: `Découvrez nos formations certifiantes et cours en direct. ${this.allCourses().length} formations disponibles.` });
    this.metaService.updateTag({ property: 'og:title', content: title });
  }

  applyFilters(): void {
    let courses = this.allCourses();

    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      courses = courses.filter(c =>
        c.title.toLowerCase().includes(q) ||
        c.description.toLowerCase().includes(q) ||
        c.teacherName.toLowerCase().includes(q)
      );
    }

    if (this.selectedTeacherId()) {
      courses = courses.filter(c => c.teacherId === this.selectedTeacherId());
    }

    if (this.selectedCategory()) {
      courses = courses.filter(c => c.categoryId === this.selectedCategory());
    }

    if (this.selectedLevel) {
      courses = courses.filter(c => c.level === this.selectedLevel);
    }

    if (this.freeOnly) {
      courses = courses.filter(c => c.isFree);
    }

    this.filteredCourses.set(courses);
    this.updateMetadata();
  }

  filterByTeacher(event: { teacherId: string; teacherName: string }): void {
    this.selectedTeacherId.set(event.teacherId);
    this.selectedTeacherName.set(event.teacherName);
    this.applyFilters();
  }

  clearTeacherFilter(): void {
    this.selectedTeacherId.set('');
    this.selectedTeacherName.set('');
    this.applyFilters();
  }

  resetFilters(): void {
    this.searchQuery = '';
    this.selectedCategory.set('');
    this.selectedTeacherId.set('');
    this.selectedTeacherName.set('');
    this.selectedLevel = '';
    this.freeOnly = false;
    this.filteredCourses.set(this.allCourses());
  }

  openVideoModal(course: Course): void {
    this.selectedCourse.set(course);
  }

  closeVideoModal(): void {
    this.selectedCourse.set(null);
  }
}
