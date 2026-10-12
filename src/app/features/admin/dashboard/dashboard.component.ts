import { Component, inject, OnInit, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { AsyncPipe, DecimalPipe, DatePipe, TitleCasePipe, CommonModule } from '@angular/common';
import { AdminService, PlatformKPIs } from '../../../core/services/admin.service';
import { PaymentService } from '../../../core/services/payment.service';
import { Course, Payment, User } from '../../../core/models';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [RouterLink, AsyncPipe, DecimalPipe, DatePipe, TitleCasePipe, CommonModule],
  template: `
    <div class="max-w-7xl mx-auto space-y-8">
      
      <!-- Top Overview Banner -->
      <div class="rounded-3xl border border-slate-800 bg-slate-950 p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 shadow-xl">
        <div>
          <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-red-500/10 text-red-400 text-xs font-bold uppercase tracking-wider mb-2">
            ● Supervision Centrale
          </span>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-white tracking-tight">Tableau de Bord Administrateur</h1>
          <p class="text-xs sm:text-sm text-slate-400 mt-1">Supervisez l'activité, modérez les formations et contrôlez les transactions financières.</p>
        </div>
        <div class="flex items-center gap-3">
          <a routerLink="/admin/courses"
             class="px-4 py-2.5 bg-amber-500 hover:bg-amber-600 text-slate-950 text-xs font-bold rounded-xl shadow-md shadow-amber-500/20 flex items-center gap-2 transition-all">
            <span>{{ pendingCourses().length }} cours en attente</span>
            <span>→</span>
          </a>
        </div>
      </div>

      <!-- 6 Global Platform KPIs (Requirement 12) -->
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        
        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-4 shadow-lg">
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Total Étudiants</p>
          <p class="font-display text-2xl font-black text-white mt-1">{{ kpis().totalStudents | number }}</p>
          <p class="text-[10px] text-emerald-400 font-bold mt-1">👥 Apprenants</p>
        </div>

        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-4 shadow-lg">
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Total Formateurs</p>
          <p class="font-display text-2xl font-black text-white mt-1">{{ kpis().totalTeachers | number }}</p>
          <p class="text-[10px] text-primary font-bold mt-1">👨‍🏫 Enseignants</p>
        </div>

        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-4 shadow-lg">
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Cours Publiés</p>
          <p class="font-display text-2xl font-black text-emerald-400 mt-1">{{ kpis().publishedCourses | number }}</p>
          <p class="text-[10px] text-slate-400 font-bold mt-1">/ {{ kpis().totalCourses }} créés</p>
        </div>

        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-4 shadow-lg">
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">À Valider</p>
          <p class="font-display text-2xl font-black text-amber-400 mt-1">{{ pendingCourses().length }}</p>
          <p class="text-[10px] text-amber-400 font-bold mt-1">⏳ File d'attente</p>
        </div>

        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-4 shadow-lg">
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Volume GMV</p>
          <p class="font-display text-xl font-black text-white mt-1">{{ kpis().totalVolume | number }} <span class="text-xs">F</span></p>
          <p class="text-[10px] text-emerald-400 font-bold mt-1">Ventes totales</p>
        </div>

        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-4 shadow-lg">
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Commissions (10%)</p>
          <p class="font-display text-xl font-black text-primary mt-1">{{ kpis().platformCommissions | number }} <span class="text-xs">F</span></p>
          <p class="text-[10px] text-primary font-bold mt-1">Revenu plateforme</p>
        </div>

      </div>

      <!-- Pending Course Approval Queue (Requirement 12) -->
      @if (pendingCourses().length > 0) {
        <div class="rounded-3xl border border-amber-500/30 bg-amber-500/5 p-6 space-y-4">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <span class="w-3 h-3 rounded-full bg-amber-500 animate-ping"></span>
              <h2 class="font-display text-lg font-bold text-white">Cours en attente de modération</h2>
            </div>
            <a routerLink="/admin/courses" class="text-xs text-amber-400 font-bold hover:underline">Gérer tout →</a>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            @for (course of pendingCourses(); track course.id) {
              <div class="p-4 rounded-2xl bg-slate-950 border border-slate-800 space-y-3 flex flex-col justify-between">
                <div>
                  <span class="text-[10px] font-bold text-slate-400 uppercase">{{ course.categoryName || 'Formation' }}</span>
                  <h3 class="font-bold text-white text-sm truncate mt-0.5">{{ course.title }}</h3>
                  <p class="text-xs text-slate-400 mt-1">Par : <span class="text-white">{{ course.teacherName }}</span></p>
                  <p class="text-xs font-mono text-primary font-bold mt-1">{{ course.price | number }} F CFA</p>
                </div>

                <div class="flex items-center gap-2 pt-2 border-t border-slate-800">
                  <button (click)="approveCourse(course)"
                          class="flex-1 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold transition-all shadow-xs">
                    ✓ Valider
                  </button>
                  <button (click)="rejectCourse(course)"
                          class="flex-1 py-1.5 rounded-xl bg-red-950 hover:bg-red-900 text-red-300 border border-red-800 text-xs font-bold transition-all">
                    ✕ Refuser
                  </button>
                </div>
              </div>
            }
          </div>
        </div>
      }

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        <!-- Recent Payments -->
        <div class="bg-slate-950 border border-slate-800 rounded-3xl p-6 shadow-xl space-y-4">
          <div class="flex items-center justify-between border-b border-slate-800 pb-3">
            <h2 class="font-display font-bold text-white text-base">Transactions Récentes</h2>
            <a routerLink="/admin/payments" class="text-primary text-xs font-bold hover:underline">Voir tout →</a>
          </div>

          <div class="space-y-3">
            @for (p of recentPayments(); track p.id) {
              <div class="flex items-center justify-between py-2 border-b border-slate-900 last:border-0 text-xs">
                <div class="min-w-0 flex-1">
                  <p class="font-bold text-white truncate">{{ p.courseTitle }}</p>
                  <p class="text-[11px] text-slate-400">{{ p.studentName || 'Étudiant' }} • {{ p.createdAt ? (p.createdAt.toMillis() | date:'dd/MM HH:mm') : 'Récemment' }}</p>
                </div>
                <div class="text-right shrink-0">
                  <p class="font-bold text-emerald-400 font-mono">{{ p.amount | number }} F</p>
                  <span class="text-[10px] text-primary font-bold">Com: {{ p.platformFee || (p.amount * 0.1) | number }} F</span>
                </div>
              </div>
            } @empty {
              <p class="text-xs text-slate-500 py-6 text-center">Aucune transaction enregistrée.</p>
            }
          </div>
        </div>

        <!-- Recent Users -->
        <div class="bg-slate-950 border border-slate-800 rounded-3xl p-6 shadow-xl space-y-4">
          <div class="flex items-center justify-between border-b border-slate-800 pb-3">
            <h2 class="font-display font-bold text-white text-base">Nouveaux Utilisateurs</h2>
            <a routerLink="/admin/users" class="text-primary text-xs font-bold hover:underline">Gérer →</a>
          </div>

          <div class="space-y-3">
            @for (u of recentUsers(); track u.uid) {
              <div class="flex items-center gap-3 py-2 border-b border-slate-900 last:border-0 text-xs">
                <img loading="lazy" decoding="async" [src]="u.photoURL || getAvatarUrl(u.displayName)"
                     [alt]="u.displayName"
                     class="w-9 h-9 rounded-xl object-cover border border-slate-800 shrink-0">
                <div class="flex-1 min-w-0">
                  <p class="font-bold text-white truncate">{{ u.displayName }}</p>
                  <p class="text-[11px] text-slate-400 truncate">{{ u.email }}</p>
                </div>
                <span [class]="getUserRoleBadge(u.role)"
                      class="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase">
                  {{ u.role }}
                </span>
              </div>
            } @empty {
              <p class="text-xs text-slate-500 py-6 text-center">Aucun utilisateur.</p>
            }
          </div>
        </div>

      </div>

    </div>
  `,
})
export class AdminDashboardComponent implements OnInit {
  private adminService = inject(AdminService);
  private paymentService = inject(PaymentService);
  private toastr = inject(ToastrService);

  kpis = signal<PlatformKPIs>({
    totalStudents: 0,
    totalTeachers: 0,
    totalCourses: 0,
    publishedCourses: 0,
    pendingCourses: 0,
    totalVolume: 0,
    platformCommissions: 0,
    totalTransactions: 0,
  });

  pendingCourses = signal<Course[]>([]);
  recentPayments = signal<Payment[]>([]);
  recentUsers = signal<User[]>([]);

  ngOnInit(): void {
    this.adminService.getGlobalKPIs().then(k => this.kpis.set(k));

    this.adminService.getAllCourses('pending_approval').subscribe(courses => {
      this.pendingCourses.set(courses);
    });

    this.paymentService.getAllPayments().subscribe(payments => {
      this.recentPayments.set(payments.slice(0, 5));
    });

    this.adminService.getUsers().subscribe(users => {
      this.recentUsers.set(users.slice(0, 5));
    });
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'User');
    return `https://ui-avatars.com/api/?name=${encoded}&background=DC2626&color=fff`;
  }

  getUserRoleBadge(role: string): string {
    switch (role) {
      case 'admin': return 'bg-red-500/20 text-red-400 border border-red-500/30';
      case 'teacher': return 'bg-primary/20 text-primary border border-primary/30';
      default: return 'bg-blue-500/20 text-blue-400 border border-blue-500/30';
    }
  }

  async approveCourse(course: Course): Promise<void> {
    try {
      await this.adminService.approveCourse(course.id, course.teacherId, course.title);
      this.toastr.success(`Le cours "${course.title}" a été validé et publié au catalogue !`);
    } catch (e) {
      this.toastr.error('Erreur lors de la validation du cours.');
    }
  }

  async rejectCourse(course: Course): Promise<void> {
    const reason = window.prompt('Motif du refus ou ajustements demandés au professeur :');
    if (reason === null) return;

    try {
      await this.adminService.rejectCourse(course.id, reason || 'Ajustements nécessaires', course.teacherId, course.title);
      this.toastr.info(`Le cours a été refusé et renvoyé au professeur.`);
    } catch (e) {
      this.toastr.error('Erreur lors du rejet du cours.');
    }
  }
}
