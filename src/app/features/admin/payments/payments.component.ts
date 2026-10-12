import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DecimalPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { PaymentService } from '../../../core/services/payment.service';
import { Payment } from '../../../core/models';

@Component({
  selector: 'app-admin-payments',
  standalone: true,
  imports: [CommonModule, DecimalPipe, DatePipe, FormsModule],
  template: `
    <div class="max-w-7xl mx-auto space-y-6">
      
      <!-- Top Banner -->
      <div class="rounded-3xl border border-slate-800 bg-slate-950 p-6 shadow-xl flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 class="font-display text-xl font-bold text-white">Transactions & Revenus de la Plateforme</h1>
          <p class="text-xs text-slate-400 mt-0.5">Surveillance de l'ensemble des flux financiers, commissions de 10% et parts formateurs.</p>
        </div>

        <div class="relative w-full sm:w-72">
          <input type="text" [(ngModel)]="searchQuery" placeholder="Rechercher par référence, cours..."
                 class="w-full pl-9 pr-4 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-red-500">
          <svg class="w-4 h-4 text-slate-500 absolute left-3 top-2.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
        </div>
      </div>

      <!-- 4 Financial KPIs (Requirement 12) -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-5 shadow-xl">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">Volume Total (GMV)</p>
          <p class="font-display text-2xl font-black text-white mt-1">{{ totalGrossVolume() | number }} <span class="text-xs">F CFA</span></p>
          <p class="text-[10px] text-emerald-400 font-bold mt-1">Brut collecté</p>
        </div>
        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-5 shadow-xl">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">Commissions Plateforme (10%)</p>
          <p class="font-display text-2xl font-black text-primary mt-1">{{ totalPlatformFees() | number }} <span class="text-xs">F CFA</span></p>
          <p class="text-[10px] text-primary font-bold mt-1">Revenu net plateforme</p>
        </div>
        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-5 shadow-xl">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">Revenus Formateurs (90%)</p>
          <p class="font-display text-2xl font-black text-emerald-400 mt-1">{{ totalTeacherEarnings() | number }} <span class="text-xs">F CFA</span></p>
          <p class="text-[10px] text-slate-400 font-bold mt-1">Reversé aux profs</p>
        </div>
        <div class="bg-slate-950 border border-slate-800 rounded-2xl p-5 shadow-xl">
          <p class="text-xs font-bold text-slate-400 uppercase tracking-wider">Total Transactions</p>
          <p class="font-display text-2xl font-black text-white mt-1">{{ payments().length }}</p>
          <p class="text-[10px] text-emerald-400 font-bold mt-1">{{ successfulCount() }} réussies</p>
        </div>
      </div>

      <!-- Filter Tabs -->
      <div class="flex items-center gap-2 overflow-x-auto pb-1">
        <button (click)="statusFilter.set('all')"
                [class]="statusFilter() === 'all' ? 'bg-red-600 text-white font-bold' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap">
          Toutes ({{ payments().length }})
        </button>
        <button (click)="statusFilter.set('success')"
                [class]="statusFilter() === 'success' ? 'bg-emerald-600 text-white font-bold' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap">
          Payées ({{ successfulCount() }})
        </button>
        <button (click)="statusFilter.set('pending')"
                [class]="statusFilter() === 'pending' ? 'bg-amber-500 text-slate-950 font-bold' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap">
          En attente
        </button>
      </div>

      <!-- Transactions Table (Requirement 12) -->
      <div class="rounded-3xl border border-slate-800 bg-slate-950 overflow-hidden shadow-xl">
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-[840px]">
            <thead>
              <tr class="bg-slate-900/60 border-b border-slate-800 text-[10px] font-black text-slate-400 uppercase tracking-wider">
                <th class="px-5 py-4">Date</th>
                <th class="px-5 py-4">Référence</th>
                <th class="px-5 py-4">Étudiant</th>
                <th class="px-5 py-4">Cours</th>
                <th class="px-5 py-4">Montant Brut</th>
                <th class="px-5 py-4">Part Prof (90%)</th>
                <th class="px-5 py-4">Comm Anour (10%)</th>
                <th class="px-5 py-4 text-right">Statut</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-900 text-xs">
              @for (p of filteredPayments(); track p.id) {
                <tr class="hover:bg-slate-900/40 transition-colors">
                  <!-- Date -->
                  <td class="px-5 py-4 text-slate-400">
                    {{ p.createdAt ? (p.createdAt.toMillis() | date:'dd/MM/yyyy HH:mm') : 'Récemment' }}
                  </td>

                  <!-- Ref -->
                  <td class="px-5 py-4 font-mono text-slate-400 text-[11px]">
                    TRX-{{ p.id.slice(0, 8) | uppercase }}
                  </td>

                  <!-- Étudiant -->
                  <td class="px-5 py-4 font-bold text-white">
                    {{ p.studentName || 'Étudiant Anour' }}
                  </td>

                  <!-- Cours -->
                  <td class="px-5 py-4 text-primary font-semibold truncate max-w-[200px]">
                    {{ p.courseTitle }}
                  </td>

                  <!-- Montant Brut -->
                  <td class="px-5 py-4 font-bold text-white font-mono">
                    {{ p.amount | number }} F
                  </td>

                  <!-- Part Formateur (90%) -->
                  <td class="px-5 py-4 font-bold text-emerald-400 font-mono">
                    {{ (p.teacherEarnings || (p.amount * 0.9)) | number }} F
                  </td>

                  <!-- Comm Anour (10%) -->
                  <td class="px-5 py-4 font-bold text-primary font-mono">
                    {{ (p.platformFee || (p.amount * 0.1)) | number }} F
                  </td>

                  <!-- Statut -->
                  <td class="px-5 py-4 text-right">
                    <span [class]="p.status === 'success' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30' : 'bg-amber-500/10 text-amber-400 border border-amber-500/30'"
                          class="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider">
                      {{ p.status === 'success' ? 'Payé' : 'En attente' }}
                    </span>
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="8" class="text-center py-16 text-slate-500 font-bold">
                    Aucune transaction trouvée.
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>

    </div>
  `,
})
export class AdminPaymentsComponent implements OnInit {
  private paymentService = inject(PaymentService);

  payments = signal<Payment[]>([]);
  statusFilter = signal<string>('all');
  searchQuery = '';

  successfulCount = computed(() => this.payments().filter(p => p.status === 'success').length);
  totalGrossVolume = computed(() => this.payments().reduce((sum, p) => sum + (p.amount || 0), 0));
  totalPlatformFees = computed(() => this.payments().reduce((sum, p) => sum + (p.platformFee || (p.amount * 0.1)), 0));
  totalTeacherEarnings = computed(() => this.payments().reduce((sum, p) => sum + (p.teacherEarnings || (p.amount * 0.9)), 0));

  filteredPayments = computed(() => {
    let list = this.payments();
    const filter = this.statusFilter();
    if (filter !== 'all') {
      list = list.filter(p => p.status === filter);
    }
    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      list = list.filter(p =>
        p.id.toLowerCase().includes(q) ||
        p.courseTitle.toLowerCase().includes(q) ||
        (p.studentName && p.studentName.toLowerCase().includes(q))
      );
    }
    return list;
  });

  ngOnInit(): void {
    this.paymentService.getAllPayments().subscribe(payments => {
      this.payments.set(payments);
    });
  }
}
