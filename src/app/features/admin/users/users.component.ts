import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, AsyncPipe, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';
import { AdminService } from '../../../core/services/admin.service';
import { User, UserRole } from '../../../core/models';

@Component({
  selector: 'app-admin-users',
  standalone: true,
  imports: [CommonModule, AsyncPipe, DatePipe, FormsModule],
  template: `
    <div class="max-w-7xl mx-auto space-y-6 font-body">
      
      <!-- Top Search & Actions -->
      <div class="rounded-3xl border border-slate-800 bg-slate-950 p-6 shadow-xl flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
            <p class="text-xs uppercase font-black text-red-400 tracking-wider">Super Administration</p>
          </div>
          <h1 class="font-display text-xl sm:text-2xl font-bold text-white mt-1">Gestion des Utilisateurs & Formateurs</h1>
          <p class="text-xs text-slate-400 mt-0.5">Créez des formateurs, partagez leurs identifiants par WhatsApp et gérez les accès.</p>
        </div>

        <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
          <div class="relative w-full sm:w-72">
            <input type="text" [(ngModel)]="searchQuery" placeholder="Rechercher par nom, email..."
                   class="w-full pl-9 pr-4 py-2.5 bg-slate-900 border border-slate-800 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-red-500">
            <svg class="w-4 h-4 text-slate-500 absolute left-3 top-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
            </svg>
          </div>

          <!-- Add Teacher Button -->
          <button (click)="openAddTeacherModal()"
                  class="px-4 py-2.5 rounded-xl bg-primary hover:bg-primary-600 text-white text-xs font-bold transition-all shadow-lg shadow-primary/25 flex items-center justify-center gap-2 active:scale-95 cursor-pointer shrink-0">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
            </svg>
            <span>+ Ajouter un Formateur</span>
          </button>
        </div>
      </div>

      <!-- Filter Tabs -->
      <div class="flex items-center gap-2 overflow-x-auto pb-1">
        <button (click)="roleFilter.set('all')"
                [class]="roleFilter() === 'all' ? 'bg-red-600 text-white font-bold shadow-md' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap cursor-pointer">
          Tous ({{ users().length }})
        </button>
        <button (click)="roleFilter.set('student')"
                [class]="roleFilter() === 'student' ? 'bg-blue-600 text-white font-bold shadow-md' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap cursor-pointer">
          Étudiants ({{ studentCount() }})
        </button>
        <button (click)="roleFilter.set('teacher')"
                [class]="roleFilter() === 'teacher' ? 'bg-primary text-white font-bold shadow-md' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap cursor-pointer">
          Formateurs ({{ teacherCount() }})
        </button>
        <button (click)="roleFilter.set('admin')"
                [class]="roleFilter() === 'admin' ? 'bg-red-700 text-white font-bold shadow-md' : 'bg-slate-950 border border-slate-800 text-slate-400 hover:text-white'"
                class="px-4 py-2 rounded-xl text-xs transition-all whitespace-nowrap cursor-pointer">
          Administrateurs ({{ adminCount() }})
        </button>
      </div>

      <!-- Users Table -->
      <div class="rounded-3xl border border-slate-800 bg-slate-950 overflow-hidden shadow-xl">
        <div class="overflow-x-auto">
          <table class="w-full text-left border-collapse min-w-[760px]">
            <thead>
              <tr class="bg-slate-900/60 border-b border-slate-800 text-[10px] font-black text-slate-400 uppercase tracking-wider">
                <th class="px-5 py-4">Utilisateur</th>
                <th class="px-5 py-4">Email</th>
                <th class="px-5 py-4">Rôle Système</th>
                <th class="px-5 py-4">Statut Accès</th>
                <th class="px-5 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-900 text-xs">
              @for (user of filteredUsers(); track user.uid) {
                <tr class="hover:bg-slate-900/40 transition-colors">
                  <!-- User Avatar & Name -->
                  <td class="px-5 py-4">
                    <div class="flex items-center gap-3">
                      <img loading="lazy" decoding="async" [src]="user.photoURL || getAvatarUrl(user.displayName)"
                           [alt]="user.displayName"
                           class="w-10 h-10 rounded-xl object-cover border border-slate-800 shrink-0">
                      <div>
                        <p class="font-bold text-white">{{ user.displayName }}</p>
                        @if (user.phone) {
                          <p class="text-[11px] text-slate-400 font-mono">{{ user.phone }}</p>
                        }
                        @if (user.speciality) {
                          <p class="text-[10px] text-primary font-semibold">📚 {{ user.speciality }}</p>
                        }
                      </div>
                    </div>
                  </td>

                  <!-- Email -->
                  <td class="px-5 py-4 text-slate-300 font-mono">
                    {{ user.email }}
                  </td>

                  <!-- Role Selector -->
                  <td class="px-5 py-4">
                    <select [ngModel]="user.role" (ngModelChange)="changeRole(user, $event)"
                            class="bg-slate-900 border border-slate-800 rounded-xl text-xs text-white px-3 py-1.5 focus:outline-none focus:border-red-500">
                      <option value="student">Étudiant</option>
                      <option value="teacher">Professeur / Formateur</option>
                      <option value="admin">Administrateur</option>
                    </select>
                  </td>

                  <!-- Status Toggle (Active / Suspended) -->
                  <td class="px-5 py-4">
                    <button (click)="toggleActive(user)"
                            [class]="user.isActive !== false ? 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30' : 'text-red-400 bg-red-500/10 border-red-500/30'"
                            class="px-3 py-1 rounded-full text-[10px] font-bold border uppercase tracking-wider transition-all cursor-pointer">
                      {{ user.isActive !== false ? '● Actif' : '✕ Suspendu' }}
                    </button>
                  </td>

                  <!-- Actions -->
                  <td class="px-5 py-4 text-right">
                    <button (click)="deleteUser(user)"
                            class="p-2 rounded-xl text-red-400 hover:bg-red-950/60 transition-colors text-xs font-bold cursor-pointer"
                            title="Supprimer définitivement l'utilisateur">
                      Supprimer
                    </button>
                  </td>
                </tr>
              } @empty {
                <tr>
                  <td colspan="5" class="text-center py-16 text-slate-500">
                    <p class="font-bold">Aucun utilisateur trouvé.</p>
                  </td>
                </tr>
              }
            </tbody>
          </table>
        </div>
      </div>

    </div>

    <!-- ========================================================================= -->
    <!-- MODAL 1: AJOUTER UN FORMATEUR                                             -->
    <!-- ========================================================================= -->
    @if (isAddTeacherModalOpen()) {
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fade-in"
           (click)="closeAddTeacherModal()">
        <div class="w-full max-w-lg bg-slate-950 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-2xl space-y-6 text-white"
             (click)="$event.stopPropagation()">
          
          <div class="flex items-center justify-between border-b border-slate-800 pb-4">
            <div>
              <span class="text-xs font-black text-primary uppercase tracking-wider">Super Administration</span>
              <h2 class="font-display text-xl font-bold text-white mt-0.5">Ajouter un Formateur / Professeur</h2>
            </div>
            <button (click)="closeAddTeacherModal()" class="p-2 text-slate-400 hover:text-white rounded-xl hover:bg-slate-900 transition-colors cursor-pointer">
              <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <form (ngSubmit)="submitCreateTeacher()" class="space-y-4">
            <div>
              <label class="block text-xs font-bold text-slate-300 mb-1.5">Nom complet du professeur *</label>
              <input type="text" [(ngModel)]="newTeacher.displayName" name="displayName" required placeholder="Ex: Dr. Moussa Diop"
                     class="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-2xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-primary">
            </div>

            <div>
              <label class="block text-xs font-bold text-slate-300 mb-1.5">Adresse email professionnelle *</label>
              <input type="email" [(ngModel)]="newTeacher.email" name="email" required placeholder="moussa.diop@exemple.com"
                     class="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-2xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-primary font-mono">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-bold text-slate-300 mb-1.5">Numéro WhatsApp (avec indicatif) *</label>
                <input type="tel" [(ngModel)]="newTeacher.phone" name="phone" required placeholder="+221 77 123 45 67"
                       class="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-2xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-primary font-mono">
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-300 mb-1.5">Matière / Spécialité *</label>
                <input type="text" [(ngModel)]="newTeacher.speciality" name="speciality" required placeholder="Ex: Informatique & IA"
                       class="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-2xl text-xs text-white placeholder-slate-500 focus:outline-none focus:border-primary">
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between mb-1.5">
                <label class="block text-xs font-bold text-slate-300">Mot de passe temporaire *</label>
                <button type="button" (click)="regeneratePassword()" class="text-xs text-primary font-bold hover:underline cursor-pointer">
                  ⚡ Régénérer
                </button>
              </div>
              <div class="relative">
                <input type="text" [(ngModel)]="newTeacher.tempPassword" name="tempPassword" required
                       class="w-full px-4 py-3 bg-slate-900 border border-slate-800 rounded-2xl text-xs text-emerald-400 font-mono focus:outline-none focus:border-primary">
              </div>
              <p class="text-[11px] text-slate-500 mt-1">Le professeur pourra modifier ce mot de passe dès sa première connexion.</p>
            </div>

            <div class="pt-4 flex items-center justify-end gap-3 border-t border-slate-800">
              <button type="button" (click)="closeAddTeacherModal()"
                      class="px-4 py-2.5 rounded-xl border border-slate-800 text-slate-400 hover:text-white text-xs font-bold cursor-pointer">
                Annuler
              </button>
              <button type="submit" [disabled]="isSubmittingTeacher()"
                      class="px-5 py-2.5 rounded-xl bg-primary hover:bg-primary-600 disabled:opacity-50 text-white text-xs font-bold transition-all shadow-lg shadow-primary/25 cursor-pointer flex items-center gap-2">
                @if (isSubmittingTeacher()) {
                  <span class="animate-spin">⏳</span>
                  <span>Création en cours...</span>
                } @else {
                  <span>Créer et Générer les Accès</span>
                }
              </button>
            </div>
          </form>

        </div>
      </div>
    }

    <!-- ========================================================================= -->
    <!-- MODAL 2: CARTE DES IDENTIFIANTS & ENVOI WHATSAPP                          -->
    <!-- ========================================================================= -->
    @if (createdTeacherInfo()) {
      <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-sm animate-fade-in"
           (click)="createdTeacherInfo.set(null)">
        <div class="w-full max-w-lg bg-slate-950 border-2 border-emerald-500/40 rounded-3xl p-6 sm:p-8 shadow-2xl space-y-6 text-white"
             (click)="$event.stopPropagation()">
          
          <div class="text-center space-y-2">
            <div class="w-14 h-14 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 flex items-center justify-center text-2xl mx-auto shadow-lg">
              ✓
            </div>
            <h2 class="font-display text-2xl font-bold text-white">Compte Formateur Créé !</h2>
            <p class="text-xs text-slate-400">
              Le compte de <strong class="text-white">{{ createdTeacherInfo()!.user.displayName }}</strong> est actif et prêt à l'emploi.
            </p>
          </div>

          <!-- Credentials Box -->
          <div class="rounded-2xl bg-slate-900 border border-slate-800 p-4 space-y-3 font-mono text-xs">
            <div class="flex items-center justify-between">
              <span class="text-slate-500 font-sans">Identifiant Email :</span>
              <span class="text-white font-bold">{{ createdTeacherInfo()!.user.email }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-slate-500 font-sans">Mot de passe temporaire :</span>
              <span class="text-emerald-400 font-bold bg-slate-950 px-2 py-0.5 rounded border border-slate-800">
                {{ createdTeacherInfo()!.tempPassword }}
              </span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-slate-500 font-sans">Spécialité :</span>
              <span class="text-primary font-bold">{{ createdTeacherInfo()!.user.speciality }}</span>
            </div>
          </div>

          <!-- WhatsApp Direct Share -->
          <div class="space-y-3">
            <p class="text-xs font-bold text-slate-300">Envoyer directement au professeur :</p>
            
            <a [href]="createdTeacherInfo()!.whatsappUrl" target="_blank"
               class="w-full py-3.5 px-4 bg-emerald-600 hover:bg-emerald-500 text-white rounded-2xl text-xs font-bold shadow-lg shadow-emerald-600/30 flex items-center justify-center gap-2.5 transition-all active:scale-95 cursor-pointer">
              <!-- WhatsApp Icon SVG -->
              <svg class="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946.003-6.556 5.338-11.891 11.893-11.891 3.181.001 6.167 1.24 8.413 3.488 2.245 2.248 3.481 5.236 3.48 8.414-.003 6.557-5.338 11.892-11.893 11.892-1.99-.001-3.951-.5-5.688-1.448l-6.305 1.654zm6.597-3.807c1.676.995 3.276 1.591 5.392 1.592 5.448 0 9.886-4.434 9.889-9.885.002-5.462-4.415-9.89-9.881-9.892-5.452 0-9.887 4.434-9.889 9.884-.001 2.225.651 3.891 1.746 5.634l-.999 3.648 3.742-.981zm11.387-5.464c-.074-.124-.272-.198-.57-.347-.297-.149-1.758-.868-2.031-.967-.272-.099-.47-.149-.669.149-.198.297-.768.967-.941 1.165-.173.198-.347.223-.644.074-.297-.149-1.255-.462-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.297-.347.446-.521.151-.172.2-.296.3-.495.099-.198.05-.372-.025-.521-.075-.148-.669-1.611-.916-2.206-.242-.579-.487-.501-.669-.51l-.57-.01c-.198 0-.52.074-.792.372s-1.04 1.016-1.04 2.479 1.065 2.876 1.213 3.074c.149.198 2.095 3.2 5.076 4.487.709.306 1.263.489 1.694.626.712.226 1.36.194 1.872.118.571-.085 1.758-.719 2.006-1.413.248-.695.248-1.29.173-1.414z"/>
              </svg>
              <span>Envoyer les identifiants sur WhatsApp</span>
            </a>

            <div class="grid grid-cols-2 gap-3 pt-1">
              <button (click)="copyMessageToClipboard()"
                      class="py-2.5 px-3 bg-slate-900 hover:bg-slate-800 border border-slate-800 rounded-xl text-xs font-bold text-slate-300 hover:text-white transition-all flex items-center justify-center gap-2 cursor-pointer">
                <span>📋 Copier le message</span>
              </button>
              <button (click)="createdTeacherInfo.set(null)"
                      class="py-2.5 px-3 bg-slate-900 hover:bg-slate-800 border border-slate-800 rounded-xl text-xs font-bold text-slate-400 hover:text-white transition-all cursor-pointer">
                <span>Fermer</span>
              </button>
            </div>
          </div>

        </div>
      </div>
    }
  `,
})
export class AdminUsersComponent implements OnInit {
  private adminService = inject(AdminService);
  private toastr = inject(ToastrService);

  users = signal<User[]>([]);
  roleFilter = signal<string>('all');
  searchQuery = '';

  // Modals state
  isAddTeacherModalOpen = signal(false);
  isSubmittingTeacher = signal(false);
  createdTeacherInfo = signal<{ user: User; tempPassword: string; whatsappMessage: string; whatsappUrl: string } | null>(null);

  newTeacher = {
    displayName: '',
    email: '',
    phone: '',
    speciality: '',
    tempPassword: '',
  };

  studentCount = computed(() => this.users().filter(u => u.role === 'student').length);
  teacherCount = computed(() => this.users().filter(u => u.role === 'teacher').length);
  adminCount = computed(() => this.users().filter(u => u.role === 'admin').length);

  filteredUsers = computed(() => {
    let list = this.users();
    const filter = this.roleFilter();
    if (filter !== 'all') {
      list = list.filter(u => u.role === filter);
    }
    if (this.searchQuery.trim()) {
      const q = this.searchQuery.toLowerCase();
      list = list.filter(u =>
        u.displayName.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        (u.phone && u.phone.includes(q)) ||
        (u.speciality && u.speciality.toLowerCase().includes(q))
      );
    }
    return list;
  });

  ngOnInit(): void {
    this.adminService.getUsers().subscribe(users => {
      this.users.set(users);
    });
  }

  getAvatarUrl(name?: string): string {
    const encoded = encodeURIComponent(name || 'User');
    return `https://ui-avatars.com/api/?name=${encoded}&background=DC2626&color=fff`;
  }

  openAddTeacherModal(): void {
    this.newTeacher = {
      displayName: '',
      email: '',
      phone: '+221 ',
      speciality: '',
      tempPassword: this.adminService.generateSecurePassword(),
    };
    this.isAddTeacherModalOpen.set(true);
  }

  closeAddTeacherModal(): void {
    this.isAddTeacherModalOpen.set(false);
  }

  regeneratePassword(): void {
    this.newTeacher.tempPassword = this.adminService.generateSecurePassword();
  }

  async submitCreateTeacher(): Promise<void> {
    if (!this.newTeacher.displayName || !this.newTeacher.email || !this.newTeacher.phone) {
      this.toastr.warning('Veuillez remplir tous les champs obligatoires.');
      return;
    }

    this.isSubmittingTeacher.set(true);
    try {
      const result = await this.adminService.createTeacherAccount(this.newTeacher);
      this.isAddTeacherModalOpen.set(false);
      this.createdTeacherInfo.set(result);
      this.toastr.success(`Compte formateur créé pour ${result.user.displayName} !`);
    } catch (err: any) {
      this.toastr.error(err.message || 'Erreur lors de la création du compte formateur.');
    } finally {
      this.isSubmittingTeacher.set(false);
    }
  }

  copyMessageToClipboard(): void {
    if (!this.createdTeacherInfo()) return;
    navigator.clipboard.writeText(this.createdTeacherInfo()!.whatsappMessage);
    this.toastr.success('Message WhatsApp copié dans le presse-papier !');
  }

  async changeRole(user: User, newRole: UserRole): Promise<void> {
    try {
      await this.adminService.updateUserRole(user.uid, newRole);
      this.toastr.success(`Rôle de ${user.displayName} mis à jour : ${newRole}`);
    } catch (e) {
      this.toastr.error('Erreur lors du changement de rôle.');
    }
  }

  async toggleActive(user: User): Promise<void> {
    const nextStatus = !(user.isActive !== false);
    try {
      await this.adminService.toggleUserStatus(user.uid, nextStatus);
      this.toastr.info(`Compte de ${user.displayName} ${nextStatus ? 'activé' : 'suspendu'}.`);
    } catch (e) {
      this.toastr.error('Erreur lors du changement de statut.');
    }
  }

  async deleteUser(user: User): Promise<void> {
    if (!confirm(`Supprimer définitivement l'utilisateur ${user.displayName} (${user.email}) ?`)) return;
    try {
      await this.adminService.deleteUser(user.uid);
      this.toastr.success('Utilisateur supprimé.');
    } catch (e) {
      this.toastr.error('Erreur lors de la suppression.');
    }
  }
}
