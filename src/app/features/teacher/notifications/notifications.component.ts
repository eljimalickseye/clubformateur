import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe, DatePipe, NgClass } from '@angular/common';
import { RouterLink, Router } from '@angular/router';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { NotificationService } from '../../../core/services/notification.service';
import { Notification, NotificationType } from '../../../core/models';

@Component({
  selector: 'app-teacher-notifications',
  standalone: true,
  imports: [CommonModule, AsyncPipe, DatePipe, RouterLink, NgClass],
  template: `
    <div class="max-w-5xl mx-auto px-4 py-8 sm:px-6 lg:px-8 space-y-8">
      
      <!-- Header -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 shadow-xs">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider mb-1">
            <span>●</span> Centre d'Alertes
          </div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-light tracking-tight">Notifications</h1>
          <p class="text-xs sm:text-sm text-light-muted mt-1">
            Restez informé en direct des inscriptions, des paiements, des messages et des validations de cours.
          </p>
        </div>

        @if (unreadCount() > 0) {
          <button (click)="markAllAsRead()"
                  class="px-4 py-2.5 bg-dark-surface2 hover:bg-dark-border text-light text-xs font-bold rounded-xl transition-all shadow-xs w-fit">
            Tout marquer comme lu
          </button>
        }
      </div>

      <!-- Filter Tabs -->
      <div class="flex items-center gap-2 border-b border-dark-border/60 pb-2">
        <button (click)="filterMode.set('all')"
                [class.border-primary]="filterMode() === 'all'"
                [class.text-primary]="filterMode() === 'all'"
                [class.border-transparent]="filterMode() !== 'all'"
                [class.text-light-muted]="filterMode() !== 'all'"
                class="px-4 py-2 text-xs font-bold border-b-2 transition-all">
          Toutes ({{ notifications().length }})
        </button>
        <button (click)="filterMode.set('unread')"
                [class.border-primary]="filterMode() === 'unread'"
                [class.text-primary]="filterMode() === 'unread'"
                [class.border-transparent]="filterMode() !== 'unread'"
                [class.text-light-muted]="filterMode() !== 'unread'"
                class="px-4 py-2 text-xs font-bold border-b-2 transition-all">
          Non lues ({{ unreadCount() }})
        </button>
      </div>

      <!-- Notifications List (Requirement 9) -->
      <div class="space-y-3">
        @for (item of filteredNotifications(); track item.id) {
          <div (click)="handleNotificationClick(item)"
               class="p-5 rounded-2xl border transition-all cursor-pointer flex items-start justify-between gap-4"
               [ngClass]="item.isRead ? 'bg-white border-dark-border' : 'bg-primary/5 border-primary/40 shadow-xs'">
            
            <div class="flex items-start gap-4 min-w-0">
              <div class="w-11 h-11 rounded-2xl flex items-center justify-center text-xl shrink-0"
                   [ngClass]="getBadgeClass(item.type)">
                {{ getNotificationIcon(item.type) }}
              </div>

              <div class="min-w-0 space-y-1">
                <div class="flex items-center gap-2">
                  <h3 class="font-bold text-light text-sm">{{ item.title }}</h3>
                  @if (!item.isRead) {
                    <span class="w-2 h-2 rounded-full bg-primary inline-block"></span>
                  }
                </div>
                <p class="text-xs text-light-muted leading-relaxed">{{ item.body }}</p>
                <p class="text-[10px] text-light-muted/70 pt-1">
                  {{ item.createdAt ? (item.createdAt.toMillis() | date:'dd/MM/yyyy à HH:mm') : 'Récemment' }}
                </p>
              </div>
            </div>

            @if (!item.isRead) {
              <button (click)="markAsRead(item, $event)"
                      title="Marquer comme lu"
                      class="text-xs text-primary font-bold hover:underline shrink-0 p-1">
                ✓ Lu
              </button>
            }
          </div>
        }
        @if (filteredNotifications().length === 0) {
          <div class="text-center py-16 bg-white border border-dashed border-dark-border rounded-3xl shadow-xs">
            <div class="text-4xl mb-3">🔔</div>
            <h3 class="font-display text-base font-bold text-light">Aucune notification</h3>
            <p class="text-xs text-light-muted mt-1">Vous êtes parfaitement à jour.</p>
          </div>
        }
      </div>

    </div>
  `,
})
export class TeacherNotificationsComponent implements OnInit {
  private store = inject(Store);
  private notificationService = inject(NotificationService);
  private toastr = inject(ToastrService);
  private router = inject(Router);

  user$ = this.store.select(selectCurrentUser);
  userId = '';
  notifications = signal<Notification[]>([]);
  filterMode = signal<'all' | 'unread'>('all');

  unreadCount = computed(() => this.notifications().filter(n => !n.isRead).length);

  filteredNotifications = computed(() => {
    if (this.filterMode() === 'unread') {
      return this.notifications().filter(n => !n.isRead);
    }
    return this.notifications();
  });

  ngOnInit(): void {
    this.user$.subscribe(user => {
      if (!user) return;
      this.userId = user.uid;
      this.notificationService.getNotifications(user.uid).subscribe((notifs: Notification[]) => {
        this.notifications.set(notifs);
      });
    });
  }

  getBadgeClass(type: NotificationType): string {
    switch (type) {
      case 'payment':
      case 'request_accepted':
      case 'course_approved':
        return 'bg-emerald-50 text-emerald-700';
      case 'enrollment_request':
      case 'enrollment':
        return 'bg-amber-50 text-amber-700';
      case 'message':
        return 'bg-blue-50 text-blue-700';
      case 'request_rejected':
      case 'course_rejected':
        return 'bg-red-50 text-red-700';
      default:
        return 'bg-slate-50 text-slate-700';
    }
  }

  getNotificationIcon(type: NotificationType): string {
    switch (type) {
      case 'payment': return '💰';
      case 'enrollment_request': return '📩';
      case 'enrollment': return '🎓';
      case 'request_accepted': return '🎉';
      case 'request_rejected': return '⚠️';
      case 'course_approved': return '✅';
      case 'course_rejected': return '❌';
      case 'message': return '💬';
      case 'review': return '⭐';
      default: return '🔔';
    }
  }

  async markAsRead(item: Notification, event: Event): Promise<void> {
    event.stopPropagation();
    if (!this.userId) return;
    await this.notificationService.markAsRead(this.userId, item.id);
  }

  async markAllAsRead(): Promise<void> {
    if (!this.userId) return;
    await this.notificationService.markAllAsRead(this.userId);
    this.toastr.success('Toutes les notifications ont été marquées comme lues.');
  }

  handleNotificationClick(item: Notification): void {
    if (!item.isRead && this.userId) {
      this.notificationService.markAsRead(this.userId, item.id);
    }

    if (item.type === 'enrollment_request') {
      this.router.navigate(['/teacher/requests']);
    } else if (item.type === 'message') {
      this.router.navigate(['/teacher/chat']);
    } else if (item.type === 'payment') {
      this.router.navigate(['/teacher/earnings']);
    } else if (item.type === 'course_approved' || item.type === 'course_rejected') {
      this.router.navigate(['/teacher/courses']);
    }
  }
}
