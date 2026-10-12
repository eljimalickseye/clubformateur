import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe, DatePipe } from '@angular/common';
import { RouterLink, Router } from '@angular/router';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { RequestService } from '../../../core/services/request.service';
import { ChatService } from '../../../core/services/chat.service';
import { EnrollmentRequest, EnrollmentRequestStatus } from '../../../core/models';

@Component({
  selector: 'app-teacher-requests',
  standalone: true,
  imports: [CommonModule, AsyncPipe, DatePipe, RouterLink],
  template: `
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 space-y-8">
      
      <!-- Header -->
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-light tracking-tight">
            Demandes d'inscription
          </h1>
          <p class="text-xs sm:text-sm text-light-muted mt-1">
            Gérez les candidatures d'étudiants souhaitant intégrer vos programmes de formation.
          </p>
        </div>

        <div class="flex items-center gap-3">
          <span class="px-3 py-1.5 rounded-xl bg-amber-50 text-amber-700 border border-amber-200 text-xs font-bold flex items-center gap-2">
            <span class="w-2 h-2 rounded-full bg-amber-500 animate-ping"></span>
            <span>{{ pendingCount() }} en attente de réponse</span>
          </span>
        </div>
      </div>

      <!-- Filter Tabs with Dynamic Counters (Requirement 7) -->
      <div class="flex items-center gap-2 overflow-x-auto pb-2 border-b border-dark-border/60">
        <button (click)="filterStatus.set('all')"
                [class.border-primary]="filterStatus() === 'all'"
                [class.text-primary]="filterStatus() === 'all'"
                [class.border-transparent]="filterStatus() !== 'all'"
                [class.text-light-muted]="filterStatus() !== 'all'"
                class="px-4 py-2 text-xs font-bold border-b-2 transition-all flex items-center gap-2 whitespace-nowrap">
          <span>Toutes les demandes</span>
          <span class="px-2 py-0.5 rounded-full bg-dark-surface2 text-[10px]">{{ allRequests().length }}</span>
        </button>

        <button (click)="filterStatus.set('pending')"
                [class.border-amber-500]="filterStatus() === 'pending'"
                [class.text-amber-600]="filterStatus() === 'pending'"
                [class.border-transparent]="filterStatus() !== 'pending'"
                [class.text-light-muted]="filterStatus() !== 'pending'"
                class="px-4 py-2 text-xs font-bold border-b-2 transition-all flex items-center gap-2 whitespace-nowrap">
          <span>En attente</span>
          <span class="px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 text-[10px] font-black">{{ pendingCount() }}</span>
        </button>

        <button (click)="filterStatus.set('accepted')"
                [class.border-emerald-500]="filterStatus() === 'accepted'"
                [class.text-emerald-600]="filterStatus() === 'accepted'"
                [class.border-transparent]="filterStatus() !== 'accepted'"
                [class.text-light-muted]="filterStatus() !== 'accepted'"
                class="px-4 py-2 text-xs font-bold border-b-2 transition-all flex items-center gap-2 whitespace-nowrap">
          <span>Acceptées</span>
          <span class="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px]">{{ acceptedCount() }}</span>
        </button>

        <button (click)="filterStatus.set('rejected')"
                [class.border-red-500]="filterStatus() === 'rejected'"
                [class.text-red-600]="filterStatus() === 'rejected'"
                [class.border-transparent]="filterStatus() !== 'rejected'"
                [class.text-light-muted]="filterStatus() !== 'rejected'"
                class="px-4 py-2 text-xs font-bold border-b-2 transition-all flex items-center gap-2 whitespace-nowrap">
          <span>Refusées</span>
          <span class="px-2 py-0.5 rounded-full bg-red-100 text-red-800 text-[10px]">{{ rejectedCount() }}</span>
        </button>
      </div>

      <!-- Requests Cards List -->
      <div class="space-y-4">
        @for (req of filteredRequests(); track req.id) {
          <div class="rounded-2xl border border-dark-border bg-white p-5 sm:p-6 shadow-xs hover:shadow-md transition-all flex flex-col md:flex-row md:items-center justify-between gap-6">
            
            <!-- Left: Student Info & Course -->
            <div class="flex items-start gap-4 min-w-0 flex-1">
              <img loading="lazy" decoding="async" [src]="req.studentPhotoURL || getAvatarUrl(req.studentName)"
                   [alt]="req.studentName"
                   class="w-12 h-12 rounded-2xl object-cover border border-dark-border shrink-0 shadow-sm">

              <div class="min-w-0 space-y-1">
                <div class="flex flex-wrap items-center gap-2">
                  <h3 class="font-bold text-light text-base truncate">{{ req.studentName }}</h3>
                  <span [class]="getStatusClass(req.status)"
                        class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border uppercase tracking-wider">
                    {{ getStatusLabel(req.status) }}
                  </span>
                </div>

                <p class="text-xs text-light-muted">
                  Cours demandé : <span class="font-bold text-primary">{{ req.courseTitle }}</span>
                </p>

                @if (req.message) {
                  <div class="mt-2 p-3 bg-dark-surface2/60 rounded-xl border border-dark-border/40 text-xs text-light/90 italic">
                    "{{ req.message }}"
                  </div>
                }

                <div class="flex items-center gap-4 text-[11px] text-light-muted pt-1">
                  <span>📅 Demandé le {{ req.createdAt ? (req.createdAt.toMillis() | date:'dd/MM/yyyy à HH:mm') : 'Récemment' }}</span>
                  <span>✉️ {{ req.studentEmail }}</span>
                </div>
              </div>
            </div>

            <!-- Right: Actions Buttons (Requirement 7) -->
            <div class="flex flex-wrap items-center gap-2.5 shrink-0 self-end md:self-center">
              
              <!-- Direct Message Button -->
              <button (click)="openChatWithStudent(req)"
                      title="Échanger avec l'étudiant"
                      class="p-2.5 rounded-xl border border-dark-border hover:bg-dark-surface2 text-light-muted hover:text-primary transition-all text-xs font-bold flex items-center gap-1.5">
                <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"/>
                </svg>
                <span class="hidden sm:inline">Message</span>
              </button>

              @if (req.status === 'pending') {
                <!-- Refuser Button -->
                <button (click)="reject(req)"
                        [disabled]="processingId() === req.id"
                        class="px-4 py-2 rounded-xl border border-red-200 bg-red-50 text-red-600 hover:bg-red-100 text-xs font-bold transition-all disabled:opacity-50">
                  Refuser
                </button>

                <!-- Accepter Button -->
                <button (click)="accept(req)"
                        [disabled]="processingId() === req.id"
                        class="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition-all shadow-sm flex items-center gap-1.5 disabled:opacity-50 active:scale-95">
                  @if (processingId() === req.id) {
                    <span class="animate-spin text-sm">⏳</span>
                  } @else {
                    <span>✓</span>
                  }
                  <span>Accepter l'étudiant</span>
                </button>
              } @else if (req.status === 'accepted') {
                <span class="text-xs font-bold text-emerald-600 bg-emerald-50 px-3 py-1.5 rounded-xl border border-emerald-200">
                  ✓ Étudiant inscrit
                </span>
              } @else {
                <span class="text-xs font-bold text-red-600 bg-red-50 px-3 py-1.5 rounded-xl border border-red-200">
                  ✕ Demande refusée
                </span>
              }

            </div>

          </div>
        } @empty {
          <div class="text-center py-16 bg-white border border-dashed border-dark-border rounded-3xl shadow-xs">
            <div class="text-4xl mb-3">📬</div>
            <h3 class="font-display text-base font-bold text-light">Aucune demande trouvée</h3>
            <p class="text-xs text-light-muted mt-1 max-w-sm mx-auto">
              Vous n'avez aucune candidature correspondant à ce filtre pour le moment.
            </p>
          </div>
        }
      </div>

    </div>
  `,
})
export class TeacherRequestsComponent implements OnInit {
  private store = inject(Store);
  private requestService = inject(RequestService);
  private chatService = inject(ChatService);
  private toastr = inject(ToastrService);
  private router = inject(Router);

  user$ = this.store.select(selectCurrentUser);
  allRequests = signal<EnrollmentRequest[]>([]);
  filterStatus = signal<string>('all');
  processingId = signal<string | null>(null);

  pendingCount = computed(() => this.allRequests().filter(r => r.status === 'pending').length);
  acceptedCount = computed(() => this.allRequests().filter(r => r.status === 'accepted').length);
  rejectedCount = computed(() => this.allRequests().filter(r => r.status === 'rejected').length);

  filteredRequests = computed(() => {
    const filter = this.filterStatus();
    const list = this.allRequests();
    if (filter === 'all') return list;
    return list.filter(r => r.status === filter);
  });

  ngOnInit(): void {
    this.user$.subscribe(user => {
      if (!user) return;
      this.requestService.getTeacherRequests(user.uid).subscribe(reqs => {
        this.allRequests.set(reqs);
      });
    });
  }

  async accept(req: EnrollmentRequest): Promise<void> {
    this.processingId.set(req.id);
    try {
      await this.requestService.acceptRequest(req);
      this.toastr.success(`L'étudiant ${req.studentName} a été inscrit avec succès !`);
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors de l\'acceptation de la demande.');
    } finally {
      this.processingId.set(null);
    }
  }

  async reject(req: EnrollmentRequest): Promise<void> {
    if (!confirm(`Voulez-vous vraiment refuser la demande de ${req.studentName} ?`)) return;
    this.processingId.set(req.id);
    try {
      await this.requestService.rejectRequest(req);
      this.toastr.info('La demande a été marquée comme refusée.');
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors du refus de la demande.');
    } finally {
      this.processingId.set(null);
    }
  }

  openChatWithStudent(req: EnrollmentRequest): void {
    this.router.navigate(['/teacher/chat'], {
      queryParams: { studentId: req.studentId, courseId: req.courseId }
    });
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Étudiant');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }

  getStatusLabel(status: EnrollmentRequestStatus): string {
    switch (status) {
      case 'pending': return 'En attente';
      case 'accepted': return 'Acceptée';
      case 'rejected': return 'Refusée';
      default: return 'En attente';
    }
  }

  getStatusClass(status: EnrollmentRequestStatus): string {
    switch (status) {
      case 'pending': return 'text-amber-700 bg-amber-50 border-amber-200';
      case 'accepted': return 'text-emerald-700 bg-emerald-50 border-emerald-200';
      case 'rejected': return 'text-red-700 bg-red-50 border-red-200';
      default: return 'text-amber-700 bg-amber-50 border-amber-200';
    }
  }
}
