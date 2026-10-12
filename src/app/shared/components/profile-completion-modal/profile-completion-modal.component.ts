import { Component, inject, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { Subscription } from 'rxjs';
import { ToastrService } from 'ngx-toastr';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { AuthService } from '../../../core/services/auth.service';
import { User } from '../../../core/models';

@Component({
  selector: 'app-profile-completion-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    @if (isOpen() && user()) {
      <div class="fixed inset-0 z-[100] flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/80 backdrop-blur-md animate-fade-in">
        <div class="w-full h-full sm:h-auto sm:max-w-lg bg-white sm:rounded-3xl p-5 sm:p-8 shadow-2xl space-y-6 text-slate-800 border-0 sm:border sm:border-slate-100 overflow-y-auto max-sm:max-h-[100dvh]"
             style="padding-top: max(1.25rem, env(safe-area-inset-top, 1.25rem)); padding-bottom: max(1.5rem, env(safe-area-inset-bottom, 1.5rem));"
             (click)="$event.stopPropagation()">
          
          <!-- Header Banner -->
          <div class="text-center space-y-2">
            <div class="w-14 h-14 rounded-2xl bg-primary/10 border border-primary/20 text-primary flex items-center justify-center text-2xl mx-auto shadow-sm">
              ✨
            </div>
            <h2 class="font-display text-xl sm:text-2xl font-black text-slate-900 tracking-tight">
              Complétez votre profil
            </h2>
            <p class="text-xs text-slate-500 max-w-sm mx-auto">
              Bienvenue sur le Club des Formateurs ! Renseignez ces quelques informations pour personnaliser votre expérience.
            </p>
          </div>

          <!-- Form Fields -->
          <form (ngSubmit)="saveProfile()" class="space-y-4">
            
            <!-- Avatar Section -->
            <div class="flex items-center gap-4 p-3.5 rounded-2xl bg-slate-50 border border-slate-200/80">
              <img loading="lazy" decoding="async" [src]="editPhotoUrl || user()!.photoURL || defaultAvatar"
                   [alt]="user()!.displayName"
                   class="w-14 h-14 rounded-2xl object-cover border-2 border-primary/20 shrink-0 shadow-xs">
              <div class="flex-1 space-y-1">
                <label class="block text-[11px] font-bold text-slate-700">Photo de profil (URL ou avatar)</label>
                <input type="url" [(ngModel)]="editPhotoUrl" name="photoURL" placeholder="https://..."
                       class="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-xl text-xs text-slate-800 placeholder-slate-400 focus:outline-none focus:border-primary">
              </div>
            </div>

            <!-- Full Name -->
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">Nom et prénom *</label>
              <input type="text" [(ngModel)]="editDisplayName" name="displayName" required
                     class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 font-semibold focus:outline-none focus:bg-white focus:border-primary">
            </div>

            <!-- WhatsApp Phone -->
            <div>
              <label class="block text-xs font-bold text-slate-700 mb-1">
                Numéro WhatsApp (indispensable pour les alertes de cours & lives) *
              </label>
              <div class="relative">
                <input type="tel" [(ngModel)]="editPhone" name="phone" required placeholder="+221 77 123 45 67"
                       class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 font-mono focus:outline-none focus:bg-white focus:border-primary">
              </div>
              <p class="text-[11px] text-slate-400 mt-1">Vous recevrez des rappels avant le début des sessions en direct.</p>
            </div>

            <!-- Teacher Specific Fields -->
            @if (user()!.role === 'teacher') {
              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">
                  Matière principale / Domaine d'expertise *
                </label>
                <input type="text" [(ngModel)]="editSpeciality" name="speciality" required placeholder="Ex: Mathématiques, Développement Web, Droit..."
                       class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:bg-white focus:border-primary">
              </div>

              <div>
                <label class="block text-xs font-bold text-slate-700 mb-1">
                  Courte biographie professionnelle
                </label>
                <textarea [(ngModel)]="editBio" name="bio" rows="2" placeholder="Présentez vos diplômes, votre parcours ou votre méthode pédagogique..."
                          class="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:bg-white focus:border-primary resize-none"></textarea>
              </div>
            }

            <!-- Action Buttons -->
            <div class="pt-3 flex items-center justify-end gap-3 border-t border-slate-100">
              <button type="button" (click)="dismissModal()"
                      class="px-4 py-2.5 rounded-xl text-xs font-bold text-slate-500 hover:text-slate-800 hover:bg-slate-100 transition-all cursor-pointer">
                Plus tard
              </button>
              <button type="submit" [disabled]="isSaving()"
                      class="px-5 py-2.5 rounded-xl bg-primary hover:bg-primary-600 disabled:opacity-50 text-white text-xs font-bold transition-all shadow-md shadow-primary/20 flex items-center gap-2 cursor-pointer active:scale-95">
                @if (isSaving()) {
                  <span class="animate-spin">⏳</span>
                  <span>Enregistrement...</span>
                } @else {
                  <span>Enregistrer et continuer</span>
                  <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M14 5l7 7m0 0l-7 7m7-7H3"/>
                  </svg>
                }
              </button>
            </div>
          </form>

        </div>
      </div>
    }
  `
})
export class ProfileCompletionModalComponent implements OnInit, OnDestroy {
  private store = inject(Store);
  private authService = inject(AuthService);
  private toastr = inject(ToastrService);
  private sub = new Subscription();

  user = signal<User | null>(null);
  isOpen = signal(false);
  isSaving = signal(false);

  editDisplayName = '';
  editPhone = '';
  editPhotoUrl = '';
  editSpeciality = '';
  editBio = '';

  defaultAvatar = 'https://ui-avatars.com/api/?name=User&background=2D5BE3&color=fff';

  ngOnInit(): void {
    this.sub = this.store.select(selectCurrentUser).subscribe(currentUser => {
      if (currentUser) {
        this.user.set(currentUser);
        this.checkCompletion(currentUser);
      } else {
        this.isOpen.set(false);
      }
    });
  }

  ngOnDestroy(): void {
    this.sub.unsubscribe();
  }

  private checkCompletion(user: User): void {
    const isDismissed = sessionStorage.getItem(`profile_modal_dismissed_${user.uid}`);
    if (isDismissed) return;

    // Check if missing phone or (if teacher, missing speciality)
    const isMissingPhone = !user.phone || user.phone.trim() === '';
    const isMissingTeacherSpeciality = user.role === 'teacher' && (!user.speciality || user.speciality.trim() === '');

    if (isMissingPhone || isMissingTeacherSpeciality) {
      this.editDisplayName = user.displayName || '';
      this.editPhone = user.phone || '+221 ';
      this.editPhotoUrl = user.photoURL || '';
      this.editSpeciality = user.speciality || '';
      this.editBio = user.bio || '';
      this.isOpen.set(true);
    }
  }

  dismissModal(): void {
    if (this.user()) {
      sessionStorage.setItem(`profile_modal_dismissed_${this.user()!.uid}`, 'true');
    }
    this.isOpen.set(false);
  }

  async saveProfile(): Promise<void> {
    const currentUser = this.user();
    if (!currentUser) return;

    if (!this.editDisplayName.trim()) {
      this.toastr.warning('Veuillez renseigner votre nom complet.');
      return;
    }

    this.isSaving.set(true);
    try {
      const updateData: Partial<User> = {
        displayName: this.editDisplayName.trim(),
        phone: this.editPhone.trim(),
        photoURL: this.editPhotoUrl.trim() || currentUser.photoURL,
      };

      if (currentUser.role === 'teacher') {
        updateData.speciality = this.editSpeciality.trim();
        updateData.bio = this.editBio.trim();
      }

      await this.authService.updateProfile(currentUser.uid, updateData);
      this.toastr.success('Profil complété avec succès !');
      this.isOpen.set(false);
    } catch (err: any) {
      this.toastr.error('Erreur lors de la sauvegarde du profil.');
    } finally {
      this.isSaving.set(false);
    }
  }
}
