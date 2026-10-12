import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { AuthService } from '../../../core/services/auth.service';
import { User } from '../../../core/models';

@Component({
  selector: 'app-teacher-profile-edit',
  standalone: true,
  imports: [CommonModule, AsyncPipe, FormsModule, RouterLink],
  template: `
    <div class="max-w-5xl mx-auto px-4 py-8 sm:px-6 lg:px-8 space-y-8">
      
      <!-- Header -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 shadow-xs">
        <div>
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold uppercase tracking-wider mb-1">
            <span>●</span> Identité & Visibilité
          </div>
          <h1 class="font-display text-2xl sm:text-3xl font-black text-light tracking-tight">Mon Profil Professionnel</h1>
          <p class="text-xs sm:text-sm text-light-muted mt-1">
            Mettez en valeur votre expertise, vos diplômes et certifications auprès des étudiants et de l'administration.
          </p>
        </div>
        @if (user$ | async; as user) {
          <a [routerLink]="['/formateur', user.uid]" target="_blank"
             class="px-4 py-2.5 rounded-xl border border-dark-border bg-white hover:bg-dark-surface2 text-primary text-xs font-bold transition-all shadow-xs flex items-center gap-2 w-fit">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
            </svg>
            <span>Voir mon profil public</span>
          </a>
        }
      </div>

      <!-- Profile Completion Tracker Bar (Requirement 10) -->
      <div class="rounded-3xl border border-dark-border bg-white p-6 shadow-xs space-y-4">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 class="font-display text-base font-bold text-light">Complétion du Profil</h2>
            <p class="text-xs text-light-muted">Un profil complet inspire confiance et augmente vos inscriptions de +40%.</p>
          </div>
          <span [class]="completionPercent() >= 80 ? 'text-emerald-700 bg-emerald-50 border-emerald-200' : 'text-amber-700 bg-amber-50 border-amber-200'"
                class="px-3.5 py-1 rounded-full text-xs font-black border uppercase tracking-wider self-start sm:self-auto">
            Profil complété à {{ completionPercent() }}%
          </span>
        </div>

        <div class="w-full h-3 rounded-full bg-dark-surface2 overflow-hidden border border-dark-border/40">
          <div class="h-full rounded-full transition-all duration-500"
               [class.bg-emerald-500]="completionPercent() >= 80"
               [class.bg-amber-500]="completionPercent() < 80"
               [style.width.%]="completionPercent()"></div>
        </div>

        <!-- Checklist of elements -->
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2 text-xs">
          <div class="flex items-center gap-2" [class.text-emerald-600]="hasPhoto" [class.text-light-muted]="!hasPhoto">
            <span>{{ hasPhoto ? '✓' : '○' }}</span>
            <span>Photo de profil</span>
          </div>
          <div class="flex items-center gap-2" [class.text-emerald-600]="hasBio" [class.text-light-muted]="!hasBio">
            <span>{{ hasBio ? '✓' : '○' }}</span>
            <span>Présentation bio</span>
          </div>
          <div class="flex items-center gap-2" [class.text-emerald-600]="hasSpeciality" [class.text-light-muted]="!hasSpeciality">
            <span>{{ hasSpeciality ? '✓' : '○' }}</span>
            <span>Spécialité définie</span>
          </div>
          <div class="flex items-center gap-2" [class.text-emerald-600]="hasDiplomas" [class.text-light-muted]="!hasDiplomas">
            <span>{{ hasDiplomas ? '✓' : '○' }}</span>
            <span>Diplômes / Certifications</span>
          </div>
        </div>
      </div>

      <!-- Profile Form -->
      <form (ngSubmit)="saveProfile()" class="space-y-8">
        
        <!-- Section 1: Identité & Photo -->
        <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 shadow-xs space-y-6">
          <h2 class="font-display text-lg font-bold text-light border-b border-dark-border/60 pb-3">
            Informations Générales
          </h2>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div class="sm:col-span-2 flex items-center gap-6">
              <img loading="lazy" decoding="async" [src]="photoURL || getAvatarUrl(displayName)"
                   [alt]="displayName"
                   class="w-20 h-20 rounded-2xl object-cover border-2 border-primary shadow-md shrink-0">
              
              <div class="flex-1 max-w-md">
                <label class="block text-xs font-bold text-light mb-1">URL de votre photo de profil</label>
                <input type="text" [(ngModel)]="photoURL" name="photoURL" placeholder="https://..."
                       class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
              </div>
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Nom complet affiché *</label>
              <input type="text" [(ngModel)]="displayName" name="displayName" required
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Spécialité / Titre professionnel *</label>
              <input type="text" [(ngModel)]="speciality" name="speciality" placeholder="Ex: Formateur Expert Développement Web & Tech"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Niveau d'enseignement *</label>
              <input type="text" [(ngModel)]="teachingLevel" name="teachingLevel" placeholder="Ex: Licence 3 (ou Master, Doctorat, Tous niveaux...)"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div class="sm:col-span-2">
              <label class="block text-xs font-bold text-light mb-1">Biographie / Présentation détaillée *</label>
              <textarea [(ngModel)]="bio" name="bio" rows="4" placeholder="Présentez votre parcours, votre pédagogie et votre expérience..."
                        class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none resize-none"></textarea>
            </div>
          </div>
        </div>

        <!-- Section 2: Expérience & Certifications (Requirement 10) -->
        <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 shadow-xs space-y-6">
          <h2 class="font-display text-lg font-bold text-light border-b border-dark-border/60 pb-3">
            Expérience, Diplômes & Langues
          </h2>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div>
              <label class="block text-xs font-bold text-light mb-1">Années d'expérience pédagogique</label>
              <input type="text" [(ngModel)]="experience" name="experience" placeholder="Ex: Plus de 8 ans d'enseignement en institut"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Diplômes & Certifications (séparés par virgule)</label>
              <input type="text" [(ngModel)]="diplomasString" name="diplomasString" placeholder="Ex: Licence Université Al-Azhar, Ijaza Hafs"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div class="sm:col-span-2">
              <label class="block text-xs font-bold text-light mb-1">Langues d'enseignement (séparées par virgule)</label>
              <input type="text" [(ngModel)]="languagesString" name="languagesString" placeholder="Ex: Français, Arabe, Wolof"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>
          </div>
        </div>

        <!-- Section 3: Coordonnées & Réseaux Sociaux -->
        <div class="rounded-3xl border border-dark-border bg-white p-6 sm:p-8 shadow-xs space-y-6">
          <h2 class="font-display text-lg font-bold text-light border-b border-dark-border/60 pb-3">
            Coordonnées Professionnelles & Réseaux
          </h2>

          <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
            <div>
              <label class="block text-xs font-bold text-light mb-1">Numéro de téléphone professionnel</label>
              <input type="text" [(ngModel)]="phone" name="phone" placeholder="+221 77 000 00 00"
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Profil LinkedIn</label>
              <input type="text" [(ngModel)]="linkedin" name="linkedin" placeholder="https://linkedin.com/in/..."
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Chaîne YouTube</label>
              <input type="text" [(ngModel)]="youtube" name="youtube" placeholder="https://youtube.com/@..."
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>

            <div>
              <label class="block text-xs font-bold text-light mb-1">Twitter / X</label>
              <input type="text" [(ngModel)]="twitter" name="twitter" placeholder="https://twitter.com/..."
                     class="w-full px-4 py-2.5 bg-dark-surface2 border border-dark-border rounded-xl text-xs text-light focus:border-primary outline-none">
            </div>
          </div>
        </div>

        <!-- Submit Button -->
        <div class="flex justify-end gap-4">
          <a routerLink="/teacher/dashboard" class="px-6 py-3 rounded-xl border border-dark-border text-xs font-bold text-light hover:bg-dark-surface2 transition-all">
            Annuler
          </a>
          <button type="submit" [disabled]="saving()"
                  class="px-8 py-3 bg-primary hover:bg-primary-600 text-white text-xs font-bold rounded-xl shadow-md shadow-primary/25 transition-all disabled:opacity-50 active:scale-95">
            {{ saving() ? 'Enregistrement en cours...' : 'Enregistrer mon profil' }}
          </button>
        </div>

      </form>

    </div>
  `,
})
export class TeacherProfileEditComponent implements OnInit {
  private store = inject(Store);
  private authService = inject(AuthService);
  private toastr = inject(ToastrService);

  user$ = this.store.select(selectCurrentUser);
  userId = '';
  saving = signal(false);

  displayName = '';
  photoURL = '';
  speciality = '';
  teachingLevel = 'Licence 3';
  bio = '';
  experience = '';
  diplomasString = '';
  languagesString = '';
  phone = '';
  linkedin = '';
  youtube = '';
  twitter = '';

  get hasPhoto(): boolean { return !!this.photoURL && !this.photoURL.includes('ui-avatars'); }
  get hasBio(): boolean { return !!this.bio && this.bio.length > 20; }
  get hasSpeciality(): boolean { return !!this.speciality; }
  get hasDiplomas(): boolean { return !!this.diplomasString; }

  completionPercent = computed(() => {
    let score = 20;
    if (this.displayName) score += 15;
    if (this.hasPhoto) score += 15;
    if (this.hasBio) score += 20;
    if (this.hasSpeciality) score += 15;
    if (this.hasDiplomas) score += 15;
    return Math.min(score, 100);
  });

  ngOnInit(): void {
    this.user$.subscribe(user => {
      if (!user) return;
      this.userId = user.uid;
      this.displayName = user.displayName || '';
      this.photoURL = user.photoURL || '';
      this.speciality = user.speciality || '';
      this.teachingLevel = user.teachingLevel || user.taughtLevels || 'Licence 3';
      this.bio = user.bio || '';
      this.experience = user.experience || '';
      this.diplomasString = user.diplomas ? user.diplomas.join(', ') : '';
      this.languagesString = user.languages ? user.languages.join(', ') : '';
      this.phone = user.phone || '';
      this.linkedin = user.socialLinks?.linkedin || '';
      this.youtube = user.socialLinks?.youtube || '';
      this.twitter = user.socialLinks?.twitter || '';
    });
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'Formateur');
    return `https://ui-avatars.com/api/?name=${encoded}&background=2D5BE3&color=fff`;
  }

  async saveProfile(): Promise<void> {
    if (!this.userId) return;
    this.saving.set(true);

    const diplomas = this.diplomasString.split(',').map(s => s.trim()).filter(Boolean);
    const languages = this.languagesString.split(',').map(s => s.trim()).filter(Boolean);

    try {
      await this.authService.updateProfile(this.userId, {
        displayName: this.displayName,
        photoURL: this.photoURL,
        speciality: this.speciality,
        teachingLevel: this.teachingLevel,
        taughtLevels: this.teachingLevel,
        bio: this.bio,
        experience: this.experience,
        diplomas,
        languages,
        phone: this.phone,
        profileCompletedPercent: this.completionPercent(),
        socialLinks: {
          linkedin: this.linkedin,
          youtube: this.youtube,
          twitter: this.twitter,
        }
      });
      this.toastr.success('Profil professionnel mis à jour avec succès !');
    } catch (e) {
      console.error(e);
      this.toastr.error('Erreur lors de la mise à jour du profil.');
    } finally {
      this.saving.set(false);
    }
  }
}
