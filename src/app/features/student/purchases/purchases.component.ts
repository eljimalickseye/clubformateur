import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Store } from '@ngrx/store';
import { Observable, switchMap, of } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { PaymentService } from '../../../core/services/payment.service';
import { Payment } from '../../../core/models';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-purchases',
  standalone: true,
  imports: [CommonModule, BackButtonComponent],
  template: `
    <div class="max-w-7xl mx-auto px-3.5 sm:px-6 lg:px-8 py-4 sm:py-8 font-body space-y-6">
      <!-- Back Navigation -->
      <div>
        <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" />
      </div>

      <div class="rounded-2xl border border-dark-border bg-dark-surface p-5 sm:p-6">
        <p class="text-xs uppercase tracking-wider text-light-muted mb-1 font-semibold">Historique financier</p>
        <h1 class="font-display text-xl sm:text-2xl font-bold text-light">Historique des achats</h1>
        <p class="text-xs sm:text-sm text-light-muted mt-0.5">Consultez et suivez toutes vos transactions Wave et Orange Money.</p>
      </div>

      <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div class="card p-4">
          <p class="text-xs text-light-muted">Total des transactions</p>
          <p class="font-display text-2xl font-bold text-light mt-1">{{ payments().length }}</p>
        </div>
        <div class="card p-4">
          <p class="text-xs text-light-muted">Montant total investi</p>
          <p class="font-display text-2xl font-bold text-primary mt-1">{{ totalSpent() | number }} XOF</p>
        </div>
        <div class="card p-4">
          <p class="text-xs text-light-muted">Transactions réussies</p>
          <p class="font-display text-2xl font-bold text-emerald-500 mt-1">{{ successfulPayments() }}</p>
        </div>
        <div class="card p-4">
          <p class="text-xs text-light-muted">Dernier achat</p>
          <p class="font-display text-sm font-bold text-light mt-2">{{ lastPaymentDate() ? (lastPaymentDate() | date:'dd MMM yyyy') : 'Aucun' }}</p>
        </div>
      </div>

      <div class="card overflow-hidden">
        @if (loading()) {
          <div class="p-8 flex justify-center">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          </div>
        } @else if (payments().length > 0) {
          <div class="overflow-x-auto">
            <table class="w-full text-left text-sm text-light-muted">
              <thead class="text-xs uppercase bg-dark-surface2 text-light-muted">
                <tr>
                  <th scope="col" class="px-6 py-4">Date</th>
                  <th scope="col" class="px-6 py-4">Cours</th>
                  <th scope="col" class="px-6 py-4">ID Transaction</th>
                  <th scope="col" class="px-6 py-4">Moyen de paiement</th>
                  <th scope="col" class="px-6 py-4">Montant</th>
                  <th scope="col" class="px-6 py-4">Statut</th>
                </tr>
              </thead>
              <tbody>
                @for (payment of payments(); track payment.id) {
                  <tr class="border-b border-dark-border hover:bg-dark-surface2 transition-colors">
                    <td class="px-6 py-4 font-medium text-light whitespace-nowrap">
                      {{ payment.createdAt ? (payment.createdAt.toDate() | date:'dd/MM/yyyy HH:mm') : 'Récemment' }}
                    </td>
                    <td class="px-6 py-4">
                      <span class="text-light line-clamp-1">{{ payment.courseTitle }}</span>
                    </td>
                    <td class="px-6 py-4 font-mono text-xs">
                      {{ payment.transactionId || payment.id | slice:0:8 | uppercase }}
                    </td>
                    <td class="px-6 py-4 capitalize">
                      <div class="flex items-center gap-2">
                        @if (payment.method === 'wave') {
                          <span class="w-2 h-2 rounded-full bg-blue-500"></span> Wave
                        } @else if (payment.method === 'orange_money') {
                          <span class="w-2 h-2 rounded-full bg-orange-500"></span> Orange Money
                        } @else if (payment.method === 'free_money') {
                          <span class="w-2 h-2 rounded-full bg-red-500"></span> Free Money
                        } @else {
                          <span class="w-2 h-2 rounded-full bg-gray-500"></span> {{ payment.method }}
                        }
                      </div>
                    </td>
                    <td class="px-6 py-4 font-medium text-light">
                      {{ payment.amount | number }} XOF
                    </td>
                    <td class="px-6 py-4">
                      @if (payment.status === 'success') {
                        <span class="px-2.5 py-1 text-[10px] font-bold tracking-wider text-emerald-500 bg-emerald-500/10 rounded-full uppercase">Réussi</span>
                      } @else if (payment.status === 'pending') {
                        <span class="px-2.5 py-1 text-[10px] font-bold tracking-wider text-amber-500 bg-amber-500/10 rounded-full uppercase">En attente</span>
                      } @else if (payment.status === 'failed') {
                        <span class="px-2.5 py-1 text-[10px] font-bold tracking-wider text-red-500 bg-red-500/10 rounded-full uppercase">Échoué</span>
                      } @else {
                        <span class="px-2.5 py-1 text-[10px] font-bold tracking-wider text-gray-500 bg-gray-500/10 rounded-full uppercase">{{ payment.status }}</span>
                      }
                    </td>
                  </tr>
                }
              </tbody>
            </table>
          </div>
        } @else {
          <div class="text-center py-16">
            <div class="text-4xl mb-4">💳</div>
            <p class="text-light text-lg font-bold mb-1">Aucune transaction</p>
            <p class="text-light-muted text-sm">Vous n'avez pas encore effectué d'achat sur la plateforme.</p>
          </div>
        }
      </div>
    </div>
  `
})
export class PurchasesComponent implements OnInit {
  private store = inject(Store);
  private paymentService = inject(PaymentService);

  loading = signal(true);
  payments = signal<Payment[]>([]);
  totalSpent = signal(0);
  successfulPayments = signal(0);
  lastPaymentDate = signal<Date | null>(null);

  ngOnInit() {
    this.store.select(selectCurrentUser).pipe(
      switchMap(user => user ? this.paymentService.getUserPayments(user.uid) : of([]))
    ).subscribe(paymentsData => {
      this.payments.set(paymentsData);
      
      let spent = 0;
      let success = 0;
      
      paymentsData.forEach(p => {
        if (p.status === 'success') {
          spent += p.amount;
          success++;
        }
      });
      
      this.totalSpent.set(spent);
      this.successfulPayments.set(success);
      
      if (paymentsData.length > 0 && paymentsData[0].createdAt) {
        this.lastPaymentDate.set(paymentsData[0].createdAt.toDate());
      }
      
      this.loading.set(false);
    });
  }
}
