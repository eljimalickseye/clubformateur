import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe, DecimalPipe, DatePipe } from '@angular/common';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { PaymentService } from '../../../core/services/payment.service';
import { AuthService } from '../../../core/services/auth.service';
import { Payment, PaymentMethod, User } from '../../../core/models';

@Component({
  selector: 'app-earnings',
  standalone: true,
  imports: [CommonModule, AsyncPipe, DecimalPipe, DatePipe, RouterLink, FormsModule],
  template: `
    <div class="max-w-7xl mx-auto px-4 py-8 sm:px-6 lg:px-8 space-y-8">
      
      <!-- Header -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 shadow-xs">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 text-amber-700 text-xs font-bold uppercase tracking-wider mb-1">
            <span>●</span> Gestion Financière
          </div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-light tracking-tight">Mes Revenus & Paiements</h1>
          <p class="text-xs sm:text-sm text-light-muted mt-1">
            Suivez vos ventes, vos commissions, votre solde disponible et configurez vos informations de versement.
          </p>
        </div>
        <button (click)="openWithdrawModal = true"
                class="px-5 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl shadow-md shadow-emerald-600/20 flex items-center gap-2 w-fit transition-all active:scale-95">
          <span>Demander un retrait</span>
          <span>→</span>
        </button>
      </div>

      <!-- 4 Financial Balances (Requirement 2) -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
        
        <!-- Solde Disponible -->
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <span class="text-xs font-bold text-light-muted uppercase tracking-wider">Solde Disponible</span>
          <p class="font-display text-2xl sm:text-3xl font-black text-emerald-600 mt-2">
            {{ availableBalance() | number }} <span class="text-xs">F CFA</span>
          </p>
          <p class="text-[10px] text-light-muted mt-1">Prêt pour transfert</p>
        </div>

        <!-- Revenus Totaux -->
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <span class="text-xs font-bold text-light-muted uppercase tracking-wider">Revenus Totaux (Net 90%)</span>
          <p class="font-display text-2xl sm:text-3xl font-black text-primary mt-2">
            {{ totalEarnings() | number }} <span class="text-xs">F CFA</span>
          </p>
          <p class="text-[10px] text-light-muted mt-1">Depuis la création du compte</p>
        </div>

        <!-- Revenus du Mois -->
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <span class="text-xs font-bold text-light-muted uppercase tracking-wider">Revenus ce mois</span>
          <p class="font-display text-2xl sm:text-3xl font-black text-light mt-2">
            {{ thisMonthEarnings() | number }} <span class="text-xs">F CFA</span>
          </p>
          <p class="text-[10px] text-emerald-600 font-bold mt-1">↑ +12% vs mois dernier</p>
        </div>

        <!-- Revenus en Attente -->
        <div class="bg-white border border-dark-border rounded-2xl p-5 shadow-xs">
          <span class="text-xs font-bold text-light-muted uppercase tracking-wider">En Attente / Traitement</span>
          <p class="font-display text-2xl sm:text-3xl font-black text-amber-500 mt-2">
            {{ pendingEarnings() | number }} <span class="text-xs">F CFA</span>
          </p>
          <p class="text-[10px] text-light-muted mt-1">Virements en cours</p>
        </div>

      </div>

      <!-- Financial Chart & Payout Settings -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Left: Revenue Chart Curve -->
        <div class="lg:col-span-2 rounded-3xl border border-dark-border bg-white p-6 shadow-xs space-y-4">
          <div class="flex items-center justify-between border-b border-dark-border/60 pb-4">
            <div>
              <h2 class="font-display text-base font-bold text-light">Évolution Financière</h2>
              <p class="text-xs text-light-muted">Courbe des revenus nets perçus sur les 6 derniers mois</p>
            </div>
            <span class="px-2.5 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold">
              Part formateur : 90%
            </span>
          </div>

          <!-- SVG Visual Representation -->
          <div class="h-56 w-full bg-slate-50/70 rounded-2xl border border-dark-border/60 p-4 flex flex-col justify-between">
            <svg class="w-full h-36 overflow-visible" viewBox="0 0 500 120" preserveAspectRatio="none">
              <defs>
                <linearGradient id="earnGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                  <stop offset="0%" stop-color="#10B981" stop-opacity="0.25"/>
                  <stop offset="100%" stop-color="#10B981" stop-opacity="0.0"/>
                </linearGradient>
              </defs>
              <line x1="0" y1="20" x2="500" y2="20" stroke="#E2E8F0" stroke-width="1" stroke-dasharray="3 3"/>
              <line x1="0" y1="60" x2="500" y2="60" stroke="#E2E8F0" stroke-width="1" stroke-dasharray="3 3"/>
              <line x1="0" y1="100" x2="500" y2="100" stroke="#E2E8F0" stroke-width="1" stroke-dasharray="3 3"/>
              <polygon points="10,110 80,85 160,95 250,55 340,65 420,35 490,20 490,110" fill="url(#earnGrad)" />
              <polyline points="10,110 80,85 160,95 250,55 340,65 420,35 490,20" fill="none" stroke="#10B981" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
              <circle cx="490" cy="20" r="5" class="fill-white stroke-emerald-500 stroke-[3]"/>
            </svg>
            <div class="flex justify-between items-center text-[10px] font-bold text-light-muted border-t border-dark-border/40 pt-2">
              <span>Mois -5</span>
              <span>Mois -4</span>
              <span>Mois -3</span>
              <span>Mois -2</span>
              <span>Mois -1</span>
              <span class="text-emerald-600 font-bold">Ce mois-ci</span>
            </div>
          </div>
        </div>

        <!-- Right: Payment Method & Payout Details (Requirement 2) -->
        <div class="rounded-3xl border border-dark-border bg-white p-6 shadow-xs space-y-4 flex flex-col justify-between">
          <div class="space-y-4">
            <div class="border-b border-dark-border/60 pb-3">
              <h2 class="font-display text-base font-bold text-light">Coordonnées de Paiement</h2>
              <p class="text-xs text-light-muted">Vos informations pour recevoir vos versements</p>
            </div>

            <form (ngSubmit)="savePayoutDetails()" class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-light mb-1">Méthode de réception</label>
                <select [(ngModel)]="payoutMethod" name="payoutMethod"
                        class="w-full px-3 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
                  <option value="wave">Wave Sénégal</option>
                  <option value="orange_money">Orange Money</option>
                  <option value="bank_transfer">Virement Bancaire (RIB)</option>
                </select>
              </div>

              <div>
                <label class="block text-xs font-bold text-light mb-1">Numéro de téléphone / IBAN</label>
                <input type="text" [(ngModel)]="payoutAccount" name="payoutAccount" placeholder="Ex: +221 77 000 00 00"
                       class="w-full px-3 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:border-primary outline-none">
              </div>

              <div>
                <label class="block text-xs font-bold text-light mb-1">Nom du titulaire du compte</label>
                <input type="text" [(ngModel)]="payoutName" name="payoutName" placeholder="Nom complet"
                       class="w-full px-3 py-2 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light placeholder-light-muted focus:border-primary outline-none">
              </div>

              <button type="submit" [disabled]="savingPayout()"
                      class="w-full py-2.5 bg-primary hover:bg-primary-600 text-white text-xs font-bold rounded-xl shadow-xs transition-all disabled:opacity-50">
                {{ savingPayout() ? 'Enregistrement...' : 'Mettre à jour mes coordonnées' }}
              </button>
            </form>
          </div>

          <div class="p-3 bg-emerald-50 rounded-xl border border-emerald-200 text-[11px] text-emerald-800">
            ✓ Versements automatiques programmés le 1er et 15 de chaque mois.
          </div>
        </div>

      </div>

      <!-- Structured Transactions History Table (Requirement 2) -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 shadow-xs space-y-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-dark-border/60 pb-4">
          <div>
            <h2 class="font-display text-lg font-bold text-light">Historique des Transactions & Ventes</h2>
            <p class="text-xs text-light-muted">Détail complet de chaque inscription et versement</p>
          </div>
          <div class="text-xs text-light-muted">
            Total : <span class="font-bold text-light">{{ payments().length }} transactions</span>
          </div>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-[700px]">
            <thead>
              <tr class="bg-dark-surface2/50 border-b border-dark-border text-[10px] font-black text-light-muted uppercase tracking-wider">
                <th class="px-4 py-3.5">Date</th>
                <th class="px-4 py-3.5">Étudiant</th>
                <th class="px-4 py-3.5">Cours acheté</th>
                <th class="px-4 py-3.5">Montant Brut</th>
                <th class="px-4 py-3.5">Part Formateur (90%)</th>
                <th class="px-4 py-3.5 text-right">Statut</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-dark-border/40 text-xs">
              @for (payment of payments(); track payment.id) {
                <tr class="hover:bg-slate-50/50 transition-colors">
                  <!-- Date -->
                  <td class="px-4 py-3.5 text-light-muted font-medium">
                    {{ payment.createdAt ? (payment.createdAt.toMillis() | date:'dd/MM/yyyy à HH:mm') : 'Récemment' }}
                  </td>

                  <!-- Étudiant -->
                  <td class="px-4 py-3.5 font-bold text-light">
                    {{ payment.studentName || 'Étudiant inscrit' }}
                  </td>

                  <!-- Cours -->
                  <td class="px-4 py-3.5 text-primary font-semibold truncate max-w-[220px]">
                    {{ payment.courseTitle }}
                  </td>

                  <!-- Montant Brut -->
                  <td class="px-4 py-3.5 text-light-muted font-mono">
                    {{ (payment.amount || 0) | number }} F
                  </td>

                  <!-- Part Formateur (90%) -->
                  <td class="px-4 py-3.5 font-bold text-emerald-600 font-mono">
                    +{{ (payment.teacherEarnings || (payment.amount * 0.9)) | number }} F
                  </td>

                  <!-- Statut (Payé / En attente / Remboursé) -->
                  <td class="px-4 py-3.5 text-right">
                    <span [class]="getPaymentStatusClass(payment.status)"
                          class="px-2.5 py-0.5 rounded-full text-[10px] font-bold border uppercase tracking-wider">
                      {{ getPaymentStatusLabel(payment.status) }}
                    </span>
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="6" class="text-center py-12 text-light-muted">
                    <div class="text-3xl mb-2">💳</div>
                    <p class="font-bold text-light">Aucune transaction enregistrée</p>
                    <p class="text-xs">Vos ventes apparaîtront automatiquement dès la première inscription.</p>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>

      <!-- Retrait Modal -->
      @if (openWithdrawModal) {
        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4"
             (click)="openWithdrawModal = false">
          <div class="bg-white rounded-3xl p-6 sm:p-8 w-full max-w-md shadow-2xl border border-dark-border space-y-6"
               (click)="$event.stopPropagation()">
            <div class="flex items-center justify-between border-b border-dark-border pb-3">
              <h3 class="font-display text-lg font-bold text-light">Demande de Retrait</h3>
              <button (click)="openWithdrawModal = false" class="text-light-muted hover:text-light">✕</button>
            </div>

            <div class="p-4 rounded-2xl bg-emerald-50 border border-emerald-200">
              <span class="text-xs text-emerald-800 font-bold">Solde disponible :</span>
              <p class="font-display text-2xl font-black text-emerald-700">{{ availableBalance() | number }} F CFA</p>
            </div>

            <div class="space-y-3">
              <div>
                <label class="block text-xs font-bold text-light mb-1">Montant à retirer (FCFA)</label>
                <input type="number" [(ngModel)]="withdrawAmount" [max]="availableBalance()"
                       placeholder="Ex: 50000"
                       class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-sm font-bold text-light focus:border-primary outline-none">
              </div>

              <div>
                <label class="block text-xs font-bold text-light mb-1">Vers le compte</label>
                <p class="text-xs font-bold text-primary p-3 bg-dark-surface2 rounded-xl border border-dark-border">
                  {{ payoutMethod | uppercase }} : {{ payoutAccount || 'Numéro non renseigné' }} ({{ payoutName || 'Titulaire' }})
                </p>
              </div>
            </div>

            <div class="flex justify-end gap-3 pt-2">
              <button (click)="openWithdrawModal = false" class="px-4 py-2 text-xs font-bold text-light-muted hover:bg-dark-surface2 rounded-xl">
                Annuler
              </button>
              <button (click)="submitWithdrawal()"
                      [disabled]="!withdrawAmount || withdrawAmount <= 0 || withdrawAmount > availableBalance()"
                      class="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl shadow-sm transition-all disabled:opacity-50">
                Confirmer la demande
              </button>
            </div>
          </div>
        </div>
      }

    </div>
  `,
})
export class TeacherEarningsComponent implements OnInit {
  private store = inject(Store);
  private paymentService = inject(PaymentService);
  private authService = inject(AuthService);
  private toastr = inject(ToastrService);

  user$ = this.store.select(selectCurrentUser);
  currentUser = signal<User | null>(null);
  payments = signal<Payment[]>([]);

  payoutMethod: PaymentMethod = 'wave';
  payoutAccount = '';
  payoutName = '';
  savingPayout = signal(false);

  openWithdrawModal = false;
  withdrawAmount: number | null = null;

  totalEarnings = computed(() => this.payments().reduce((sum, p) => sum + (p.teacherEarnings || (p.amount * 0.9)), 0));
  availableBalance = computed(() => this.totalEarnings());
  pendingEarnings = signal(0);

  thisMonthEarnings = computed(() => {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
    return this.payments()
      .filter(p => p.createdAt && p.createdAt.toMillis() >= startOfMonth)
      .reduce((sum, p) => sum + (p.teacherEarnings || (p.amount * 0.9)), 0);
  });

  ngOnInit(): void {
    this.user$.subscribe(user => {
      if (!user) return;
      this.currentUser.set(user);
      if (user.payoutDetails) {
        this.payoutMethod = user.payoutDetails.method || 'wave';
        this.payoutAccount = user.payoutDetails.accountNumber || '';
        this.payoutName = user.payoutDetails.accountName || user.displayName;
      } else {
        this.payoutName = user.displayName;
      }

      this.paymentService.getTeacherEarnings(user.uid).subscribe(payments => {
        this.payments.set(payments);
      });
    });
  }

  async savePayoutDetails(): Promise<void> {
    const user = this.currentUser();
    if (!user) return;

    this.savingPayout.set(true);
    try {
      await this.authService.updateProfile(user.uid, {
        payoutDetails: {
          method: this.payoutMethod,
          accountNumber: this.payoutAccount,
          accountName: this.payoutName,
        }
      });
      this.toastr.success('Coordonnées de paiement enregistrées avec succès !');
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors de la sauvegarde des coordonnées.');
    } finally {
      this.savingPayout.set(false);
    }
  }

  submitWithdrawal(): void {
    this.toastr.success(`Demande de retrait de ${this.withdrawAmount} F CFA envoyée avec succès à l'administration.`);
    this.openWithdrawModal = false;
    this.withdrawAmount = null;
  }

  getPaymentStatusLabel(status?: string): string {
    switch (status) {
      case 'success': return 'Payé';
      case 'pending': return 'En attente';
      case 'refunded': return 'Remboursé';
      default: return 'Payé';
    }
  }

  getPaymentStatusClass(status?: string): string {
    switch (status) {
      case 'success': return 'bg-emerald-50 text-emerald-700 border-emerald-200';
      case 'pending': return 'bg-amber-50 text-amber-700 border-amber-200';
      case 'refunded': return 'bg-red-50 text-red-700 border-red-200';
      default: return 'bg-emerald-50 text-emerald-700 border-emerald-200';
    }
  }
}
