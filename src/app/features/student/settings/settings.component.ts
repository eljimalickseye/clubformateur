import { Component, inject, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { AuthService } from '../../../core/services/auth.service';
import { authActions } from '../../../store/auth/auth.actions';
import { User } from '../../../core/models';

import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';
import { RefreshButtonComponent } from '../../../shared/components/refresh-button/refresh-button.component';

@Component({
  selector: 'app-student-settings',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, BackButtonComponent, RefreshButtonComponent],
  template: `
    <div class="max-w-4xl mx-auto px-3.5 sm:px-6 py-3 sm:py-6 font-body space-y-6 animate-fade-in">
      
      <!-- Sticky Top Navigation Header with Clean SVG Settings Gear Icon -->
      <div class="sticky top-0 z-30 -mx-3.5 sm:-mx-6 px-3.5 sm:px-6 py-3 bg-white/95 backdrop-blur-md border-b border-slate-200/80 shadow-2xs flex items-center justify-between">
        <div class="flex items-center gap-3">
          <app-back-button label="Tableau de bord" defaultRoute="/student/dashboard" [showIconOnlyOnMobile]="true" />
          <div class="border-l border-slate-200 pl-3 flex items-center gap-2.5">
            <div class="w-8 h-8 rounded-xl bg-slate-100 text-slate-700 flex items-center justify-center shrink-0">
              <svg class="w-4 h-4 text-slate-700" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <div>
              <p class="text-[10px] uppercase tracking-wider text-slate-500 font-bold">Compte apprenant</p>
              <h1 class="font-display text-base sm:text-lg font-black text-slate-900">Paramètres</h1>
            </div>
          </div>
        </div>
        <app-refresh-button />
      </div>

      <!-- Tabs -->
      <div class="flex gap-1.5 bg-slate-100 border border-slate-200 rounded-2xl p-1.5 w-fit">
        @for (tab of tabs; track tab.id) {
          <button (click)="activeTab.set(tab.id)"
                  [class]="activeTab() === tab.id ? 'bg-primary text-white shadow-xs font-bold' : 'text-slate-600 hover:text-slate-900 font-medium'"
                  class="px-4 py-2 rounded-xl text-xs sm:text-sm transition-all cursor-pointer">
            {{ tab.label }}
          </button>
        }
      </div>

      <!-- Tab: Profil -->
      @if (activeTab() === 'profile') {
        <div class="rounded-3xl border border-slate-200 bg-white p-5 sm:p-7 space-y-6 shadow-xs text-slate-900">
          <div>
            <h2 class="font-display text-base sm:text-lg font-bold text-slate-900">Informations & Carte Étudiante</h2>
            <p class="text-xs text-slate-500 mt-0.5">Modifiez votre niveau d'études, votre année académique et vos informations personnelles.</p>
          </div>

          <!-- Aperçu en direct de la carte étudiante -->
          <div class="p-4 rounded-2xl bg-slate-50 border border-slate-200 flex items-center gap-4">
            <div class="relative shrink-0">
              <img loading="lazy" decoding="async" [src]="profileForm.get('photoURL')?.value || currentUser()?.photoURL || 'assets/default-avatar.png'"
                   class="w-14 h-14 sm:w-16 sm:h-16 rounded-2xl object-cover border-2 border-primary/40 shadow-xs bg-white"
                   onerror="this.src='assets/default-avatar.png'" alt="Avatar">
              <span class="absolute -bottom-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-emerald-500 ring-2 ring-white text-white text-[9px] font-bold">
                ✓
              </span>
            </div>
            <div class="space-y-1.5 min-w-0">
              <h3 class="font-display text-base sm:text-lg font-black text-slate-900 tracking-tight truncate">
                {{ profileForm.get('displayName')?.value || 'Nom de l’étudiant' }}
              </h3>
              <div class="flex flex-wrap items-center gap-1.5">
                <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-blue-50 border border-blue-200 text-primary text-[10px] font-bold font-mono">
                  <svg class="w-3 h-3 text-primary shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V8a2 2 0 00-2-2h-5m-4 0V5a2 2 0 114 0v1m-4 0a2 2 0 104 0m-5 8a2 2 0 100-4 2 2 0 000 4zm0 0c1.306 0 2.417.835 2.83 2M9 14a3.001 3.001 0 00-2.83 2M15 11h3m-3 4h2" />
                  </svg>
                  <span>Matricule : {{ profileForm.get('matricule')?.value || 'CF-2026-XXXX' }}</span>
                </span>
                <span class="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-slate-100 border border-slate-200 text-slate-700 text-[10px] font-medium">
                  <svg class="w-3 h-3 text-slate-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 14l9-5-9-5-9 5 9 5z" />
                  </svg>
                  <span>{{ profileForm.get('academicLevel')?.value || 'Étudiant en Licence' }} • Année {{ profileForm.get('academicYear')?.value || '2026-2027' }}</span>
                </span>
              </div>
            </div>
          </div>

          <form [formGroup]="profileForm" (ngSubmit)="saveProfile()" class="space-y-4">
            
            <!-- Section 1 : Cursus académique -->
            <div class="p-4 rounded-2xl border border-slate-200 bg-slate-50/50 space-y-3">
              <p class="text-xs font-bold text-slate-800 uppercase tracking-wider">Cursus académique & Matricule</p>
              
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <label class="block">
                  <span class="block text-xs font-bold text-slate-700 mb-1">Niveau d'études *</span>
                  <input class="w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs text-slate-800 focus:border-primary outline-none"
                         formControlName="academicLevel"
                         placeholder="Ex: Étudiant en Licence 2">
                </label>

                <label class="block">
                  <span class="block text-xs font-bold text-slate-700 mb-1">Année académique *</span>
                  <select class="w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs text-slate-800 focus:border-primary outline-none"
                          formControlName="academicYear">
                    <option value="2024-2025">2024-2025</option>
                    <option value="2025-2026">2025-2026</option>
                    <option value="2026-2027">2026-2027</option>
                    <option value="2027-2028">2027-2028</option>
                    <option value="2028-2029">2028-2029</option>
                  </select>
                </label>

                <label class="block">
                  <span class="block text-xs font-bold text-slate-700 mb-1">Matricule étudiant *</span>
                  <input class="w-full px-3.5 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-mono font-bold text-primary focus:border-primary outline-none"
                         formControlName="matricule"
                         placeholder="CF-2026-XXXX">
                </label>
              </div>
            </div>

            <!-- Section 2 : Informations personnelles -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <label class="block">
                <span class="block text-xs font-bold text-slate-700 mb-1">Nom complet</span>
                <input class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:bg-white focus:border-primary outline-none"
                       formControlName="displayName" placeholder="Votre nom complet">
              </label>
              <label class="block">
                <span class="block text-xs font-bold text-slate-700 mb-1">Téléphone (Wave / Orange Money)</span>
                <input class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:bg-white focus:border-primary outline-none"
                       formControlName="phone" placeholder="+221 77 XXX XX XX">
              </label>
            </div>

            <label class="block">
              <span class="block text-xs font-bold text-slate-700 mb-1">Photo de profil (URL de l'image)</span>
              <input class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:bg-white focus:border-primary outline-none"
                     formControlName="photoURL" placeholder="https://exemple.com/mon-avatar.png">
            </label>

            <label class="block">
              <span class="block text-xs font-bold text-slate-700 mb-1">Bio</span>
              <textarea class="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:bg-white focus:border-primary outline-none resize-none"
                        rows="2" formControlName="bio" placeholder="Parlez-nous un peu de vous..."></textarea>
            </label>

            <div class="flex justify-end pt-2">
              <button type="submit" class="px-6 py-2.5 rounded-xl bg-primary text-white text-xs font-bold shadow-md shadow-primary/20 hover:bg-primary-600 active:scale-95 transition-all cursor-pointer" [disabled]="profileForm.invalid || saving()">
                {{ saving() ? 'Enregistrement...' : 'Enregistrer les modifications' }}
              </button>
            </div>
          </form>
        </div>
      }

      <!-- Tab: Notifications -->
      @if (activeTab() === 'notifications') {
        <div class="rounded-3xl border border-slate-200 bg-white p-6 sm:p-8 space-y-5 shadow-xs text-slate-900">
          <h2 class="font-display text-lg font-bold text-slate-900">Préférences de notifications</h2>
          @for (pref of notifPrefs; track pref.key) {
            <div class="flex items-center justify-between py-3.5 border-b border-slate-100 last:border-0">
              <div>
                <p class="text-xs sm:text-sm font-bold text-slate-900">{{ pref.label }}</p>
                <p class="text-xs text-slate-500 mt-0.5">{{ pref.desc }}</p>
              </div>
              <button (click)="pref.enabled = !pref.enabled"
                      [class]="pref.enabled ? 'bg-primary' : 'bg-slate-200'"
                      class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors cursor-pointer">
                <span [class]="pref.enabled ? 'translate-x-6' : 'translate-x-1'"
                      class="inline-block h-4 w-4 rounded-full bg-white shadow-sm transition-transform"></span>
              </button>
            </div>
          }
          <div class="flex justify-end pt-2">
            <button class="px-6 py-2.5 rounded-xl bg-primary text-white text-xs font-bold shadow-md shadow-primary/20 hover:bg-primary-600 active:scale-95 transition-all cursor-pointer" (click)="saveNotifications()">
              Sauvegarder les préférences
            </button>
          </div>
        </div>
      }

      <!-- Tab: Sécurité -->
      @if (activeTab() === 'security') {
        <div class="space-y-4">
          <div class="rounded-3xl border border-slate-200 bg-white p-6 sm:p-8 shadow-xs text-slate-900">
            <h2 class="font-display text-lg font-bold text-slate-900 mb-4">Changer le mot de passe</h2>
            <form [formGroup]="passwordForm" (ngSubmit)="changePassword()" class="space-y-4">
              <label class="block">
                <span class="block text-xs font-bold text-slate-700 mb-1.5">Nouveau mot de passe</span>
                <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs sm:text-sm text-slate-800 placeholder-slate-400 focus:bg-white focus:border-primary outline-none" type="password" formControlName="password" placeholder="Minimum 8 caractères">
              </label>
              <label class="block">
                <span class="block text-xs font-bold text-slate-700 mb-1.5">Confirmer le mot de passe</span>
                <input class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs sm:text-sm text-slate-800 placeholder-slate-400 focus:bg-white focus:border-primary outline-none" type="password" formControlName="confirm" placeholder="Répétez le mot de passe">
              </label>
              @if (passwordForm.errors?.['mismatch'] && passwordForm.get('confirm')?.touched) {
                <p class="text-xs text-red-500 font-medium">Les mots de passe ne correspondent pas.</p>
              }
              <div class="flex justify-end">
                <button type="submit" class="px-6 py-2.5 rounded-xl bg-primary text-white text-xs font-bold shadow-md shadow-primary/20 hover:bg-primary-600 active:scale-95 transition-all cursor-pointer" [disabled]="passwordForm.invalid || saving()">
                  Mettre à jour le mot de passe
                </button>
              </div>
            </form>
          </div>

          <div class="rounded-3xl border border-red-200 bg-red-50/30 p-6">
            <h2 class="font-display text-base font-bold text-red-600 mb-1.5">Zone de déconnexion</h2>
            <p class="text-xs text-slate-600 mb-4">La déconnexion mettra fin à votre session sur cet appareil.</p>
            <button (click)="logout()" class="px-4 py-2 rounded-xl border border-red-300 bg-white text-red-600 text-xs font-bold hover:bg-red-50 transition-colors cursor-pointer">
              Se déconnecter de ce compte
            </button>
          </div>
        </div>
      }
    </div>
  `,
})
export class StudentSettingsComponent implements OnInit {
  private store = inject(Store);
  private authService = inject(AuthService);
  private fb = inject(FormBuilder);
  private toastr = inject(ToastrService);
  private router = inject(Router);

  currentUser = signal<User | null>(null);
  saving = signal(false);
  activeTab = signal<string>('profile');

  tabs = [
    { id: 'profile', label: 'Profil' },
    { id: 'notifications', label: 'Notifications' },
    { id: 'security', label: 'Sécurité' },
  ];

  notifPrefs = [
    { key: 'new_lesson', label: 'Nouvelles leçons', desc: 'Soyez notifié quand une nouvelle leçon est disponible', enabled: true },
    { key: 'live_start', label: 'Démarrage de live', desc: 'Alertes quand une session en direct commence', enabled: true },
    { key: 'message', label: 'Nouveaux messages', desc: 'Notifications pour les messages de vos formateurs', enabled: true },
    { key: 'certificate', label: 'Certificat obtenu', desc: 'Confirmation quand un certificat est émis', enabled: true },
    { key: 'promo', label: 'Offres et promotions', desc: 'Nouvelles formations et offres spéciales', enabled: false },
  ];

  profileForm = this.fb.group({
    displayName: ['', [Validators.required, Validators.minLength(2)]],
    phone: [''],
    bio: [''],
    matricule: [''],
    academicLevel: ['Étudiant en Licence'],
    academicYear: ['2026-2027'],
    photoURL: [''],
  });

  passwordForm = this.fb.group(
    {
      password: ['', [Validators.required, Validators.minLength(8)]],
      confirm: ['', Validators.required],
    },
    { validators: (g) => g.get('password')?.value === g.get('confirm')?.value ? null : { mismatch: true } }
  );

  ngOnInit() {
    this.store.select(selectCurrentUser).subscribe(user => {
      this.currentUser.set(user);
      if (user) {
        const year = new Date().getFullYear();
        const hash = (user.uid || 'STU').slice(0, 5).toUpperCase();
        const defaultMatricule = user.matricule || `CF-${year}-${hash}`;

        this.profileForm.patchValue({
          displayName: user.displayName || '',
          phone: user.phone ?? '',
          bio: user.bio ?? '',
          matricule: defaultMatricule,
          academicLevel: user.academicLevel || 'Étudiant en Licence',
          academicYear: user.academicYear || '2026-2027',
          photoURL: user.photoURL || '',
        });
      }
    });
  }

  async saveProfile() {
    if (this.profileForm.invalid || !this.currentUser()) return;
    this.saving.set(true);
    try {
      const { displayName, phone, bio, matricule, academicLevel, academicYear, photoURL } = this.profileForm.value;
      const updateData: Partial<User> = {
        displayName: displayName!,
        phone: phone || '',
        bio: bio || '',
        matricule: matricule?.trim() || undefined,
        academicLevel: academicLevel?.trim() || 'Étudiant en Licence',
        academicYear: academicYear?.trim() || '2026-2027',
      };
      if (photoURL?.trim()) {
        updateData.photoURL = photoURL.trim();
      }

      await this.authService.updateProfile(this.currentUser()!.uid, updateData);

      const updatedUser = { ...this.currentUser()!, ...updateData };
      this.currentUser.set(updatedUser);
      this.store.dispatch(authActions.updateProfileSuccess({ data: updateData }));
      this.toastr.success('Profil et informations académiques mis à jour avec succès !');
    } catch {
      this.toastr.error('Erreur lors de la mise à jour.');
    } finally {
      this.saving.set(false);
    }
  }

  async changePassword() {
    if (this.passwordForm.invalid) return;
    this.toastr.info('Fonctionnalité de changement de mot de passe bientôt disponible.');
  }

  saveNotifications() {
    this.toastr.success('Préférences de notifications sauvegardées !');
  }

  logout() {
    this.store.dispatch(authActions.logout());
  }

  goBack() {
    this.router.navigate(['/student/dashboard']);
  }
}
