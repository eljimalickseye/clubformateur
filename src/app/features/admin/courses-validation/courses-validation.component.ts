import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe, DecimalPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { AdminService } from '../../../core/services/admin.service';
import { Course, CoursePublicationStatus } from '../../../core/models';

@Component({
  selector: 'app-admin-courses-validation',
  standalone: true,
  imports: [CommonModule, AsyncPipe, DecimalPipe, DatePipe, FormsModule, RouterLink],
  template: `
    <div class="max-w-7xl mx-auto space-y-6">
      
      <!-- Top Banner -->
      <div class="rounded-3xl border border-slate-800 bg-slate-950 p-6 shadow-xl flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 class="font-display text-xl font-bold text-white">Modération & Validation des Formations</h1>
          <p class="text-xs text-slate-400 mt-0.5">Examinez les cours soumis par les professeurs avant leur mise en ligne sur le catalogue public.</p>
        </div>

        <div class="relative w-full sm:w-72">
          <input type="text" [(ngModel)]="searchQuery" placeholder="Rechercher une formation..."
                 class="w-full pl-9 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-red-500">
          <svg class="w-4 h-4 text-slate-500 absolute left-3 top-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>
      </div>

      <!-- Filter Tabs (Requirement 12) -->
      <div class="flex items-center gap-2 overflow-x-auto pb-1">
        <button (click)="statusFilter.set('all')"
                [class]="statusFilter() === 'all' ? 'bg-red-600 text-white font-bold' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap">
          Toutes ({{ courses().length }})
        </button>
        <button (click)="statusFilter.set('pending_approval')"
                [class]="statusFilter() === 'pending_approval' ? 'bg-amber-500 text-slate-950 font-black' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap flex items-center gap-1.5">
          <span>En attente de validation</span>
          <span class="px-1.5 py-0.2 rounded-full bg-black/20 text-[10px]">{{ pendingCount() }}</span>
        </button>
        <button (click)="statusFilter.set('published')"
                [class]="statusFilter() === 'published' ? 'bg-emerald-600 text-white font-bold' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap">
          Publiés ({{ publishedCount() }})
        </button>
        <button (click)="statusFilter.set('rejected')"
                [class]="statusFilter() === 'rejected' ? 'bg-red-800 text-white font-bold' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap">
          Refusés ({{ rejectedCount() }})
        </button>
      </div>

      <!-- Courses Grid (Requirement 12) -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        @for (course of filteredCourses(); track course.id) {
          <div class="rounded-3xl border border-slate-800 bg-slate-950 overflow-hidden shadow-xl flex flex-col justify-between group">
            
            <div>
              <!-- Cover Preview -->
              <div class="h-44 bg-slate-900 relative overflow-hidden border-b border-slate-800">
                @if (course.thumbnailUrl) {
                  <img loading="lazy" decoding="async" [src]="course.thumbnailUrl" [alt]="course.title" class="w-full h-full object-cover">
                } @else {
                  <div class="w-full h-full flex items-center justify-center text-4xl">📖</div>
                }

                <div class="absolute top-3 left-3">
                  <span [class]="getStatusClass(course)"
                        class="px-2.5 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border shadow-xs">
                    {{ getStatusLabel(course) }}
                  </span>
                </div>

                <div class="absolute top-3 right-3">
                  <span class="px-2.5 py-1 rounded-full text-xs font-black bg-slate-950/90 text-white border border-slate-700">
                    {{ course.isFree ? 'Gratuit' : ((course.price | number) + ' F') }}
                  </span>
                </div>
              </div>

              <!-- Info -->
              <div class="p-5 space-y-3">
                <div>
                  <span class="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                    {{ course.categoryName || 'Formation' }} • {{ course.level }}
                  </span>
                  <h3 class="font-display font-bold text-white text-base line-clamp-2 mt-0.5">
                    {{ course.title }}
                  </h3>
                </div>

                <div class="p-3 rounded-xl bg-slate-900 border border-slate-800/80 text-xs text-slate-300">
                  <p class="text-[10px] text-slate-400 font-bold uppercase">Formateur</p>
                  <p class="font-bold text-white truncate mt-0.5">{{ course.teacherName }}</p>
                </div>

                <p class="text-xs text-slate-400 line-clamp-2 leading-relaxed">
                  {{ course.shortDescription }}
                </p>

                @if (course.adminFeedback) {
                  <div class="p-3 rounded-xl bg-red-950/40 border border-red-900/60 text-xs text-red-300">
                    <span class="font-bold">Motif refus :</span> {{ course.adminFeedback }}
                  </div>
                }
              </div>
            </div>

            <!-- Moderation Actions (Requirement 12) -->
            <div class="p-5 pt-0 space-y-2">
              <div class="flex items-center gap-2">
                @if (course.publicationStatus === 'pending_approval' || !course.isPublished) {
                  <button (click)="approveCourse(course)"
                          class="flex-1 py-2 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold rounded-xl shadow-xs transition-all">
                    ✓ Valider & Publier
                  </button>
                  <button (click)="rejectCourse(course)"
                          class="flex-1 py-2 bg-red-950 hover:bg-red-900 text-red-300 border border-red-800 text-xs font-bold rounded-xl transition-all">
                    ✕ Refuser
                  </button>
                } @else {
                  <button (click)="unpublishCourse(course)"
                          class="flex-1 py-2 bg-slate-900 hover:bg-slate-800 border border-slate-800 text-slate-300 text-xs font-bold rounded-xl transition-all">
                    Retirer du catalogue
                  </button>
                }
              </div>

              <div class="flex items-center justify-between pt-2 border-t border-slate-900 text-xs">
                <a [routerLink]="['/course', course.id]" target="_blank"
                   class="text-slate-400 hover:text-white flex items-center gap-1 font-medium">
                  <span>Page publique</span>
                  <span>↗</span>
                </a>
                <button (click)="deleteCourse(course)" class="text-red-400 hover:text-red-300 font-bold">
                  Supprimer
                </button>
              </div>
            </div>

          </div>
        } @empty {
          <div class="col-span-full text-center py-20 bg-slate-950 border border-dashed border-slate-800 rounded-3xl">
            <p class="text-slate-500 font-bold">Aucun cours trouvé dans cette catégorie.</p>
          </div>
        }
      </div>

    </div>
  `,
})
export class AdminCoursesValidationComponent implements OnInit {
  private adminService = inject(AdminService);
  private toastr = inject(ToastrService);

  courses = signal<Course[]>([]);
  statusFilter = signal<string>('pending_approval');
  searchQuery = '';

  pendingCount = computed(() => this.courses().filter(c => c.publicationStatus === 'pending_approval').length);
  publishedCount = computed(() => this.courses().filter(c => c.isPublished || c.publicationStatus === 'published').length);
  rejectedCount = computed(() => this.courses().filter(c => c.publicationStatus === 'rejected').length);

  filteredCourses = computed(() => {
    let list = this.courses();
    const filter = this.statusFilter();
    if (filter === 'pending_approval') {
      list = list.filter(c => c.publicationStatus === 'pending_approval');
    } else if (filter === 'published') {
      list = list.filter(c => c.isPublished || c.publicationStatus === 'published');
    } else if (filter === 'rejected') {
      list = list.filter(c => c.publicationStatus === 'rejected');
    }

    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      list = list.filter(c =>
        c.title.toLowerCase().includes(q) ||
        (c.teacherName && c.teacherName.toLowerCase().includes(q))
      );
    }
    return list;
  });

  ngOnInit(): void {
    this.adminService.getAllCourses().subscribe(courses => {
      this.courses.set(courses);
    });
  }

  getStatusLabel(course: Course): string {
    if (course.publicationStatus === 'pending_approval') return 'En attente';
    if (course.publicationStatus === 'rejected') return 'Refusé';
    if (course.isPublished || course.publicationStatus === 'published') return 'Publié';
    return 'Brouillon';
  }

  getStatusClass(course: Course): string {
    if (course.publicationStatus === 'pending_approval') return 'bg-amber-500/20 text-amber-400 border-amber-500/30';
    if (course.publicationStatus === 'rejected') return 'bg-red-500/20 text-red-400 border-red-500/30';
    if (course.isPublished || course.publicationStatus === 'published') return 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
    return 'bg-slate-800 text-slate-400 border-slate-700';
  }

  async approveCourse(course: Course): Promise<void> {
    try {
      await this.adminService.approveCourse(course.id, course.teacherId, course.title);
      this.toastr.success(`Le cours "${course.title}" a été validé et mis en ligne.`);
    } catch (e) {
      this.toastr.error('Erreur lors de la validation.');
    }
  }

  async rejectCourse(course: Course): Promise<void> {
    const feedback = window.prompt('Motif du refus à transmettre au professeur :');
    if (feedback === null) return;

    try {
      await this.adminService.rejectCourse(course.id, feedback || 'Ajustements demandés', course.teacherId, course.title);
      this.toastr.info(`Le cours a été refusé et le professeur en a été notifié.`);
    } catch (e) {
      this.toastr.error('Erreur lors du rejet.');
    }
  }

  async unpublishCourse(course: Course): Promise<void> {
    try {
      await this.adminService.updateCourseStatus(course.id, 'draft', false);
      this.toastr.info(`Le cours a été dépublié.`);
    } catch (e) {
      this.toastr.error('Erreur lors de la dépublication.');
    }
  }

  async deleteCourse(course: Course): Promise<void> {
    if (!confirm(`Supprimer définitivement le cours "${course.title}" ?`)) return;
    try {
      await this.adminService.deleteCourse(course.id);
      this.toastr.success('Cours supprimé.');
    } catch (e) {
      this.toastr.error('Erreur lors de la suppression.');
    }
  }
}
