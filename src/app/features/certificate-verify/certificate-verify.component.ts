import { Component, inject, OnInit, signal } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { Firestore, collection, query, where, getDocs } from '@angular/fire/firestore';
import { Certificate } from '../../core/models';
import { BackButtonComponent } from '../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-certificate-verify',
  standalone: true,
  imports: [RouterLink, BackButtonComponent],
  template: `
    <div class="min-h-screen bg-[#F8FAFC] flex items-center justify-center px-4 py-8 font-body">
      <div class="w-full max-w-lg text-center space-y-6">
        <div class="flex items-center justify-between">
          <app-back-button label="Accueil" defaultRoute="/" />
          <a routerLink="/" class="inline-flex items-center gap-2">
            <svg width="32" height="32" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M20 2L35.5885 11V29L20 38L4.41154 29V11L20 2Z" fill="#2D5BE3"/>
              <circle cx="20" cy="20" r="4" fill="white"/>
            </svg>
            <span class="font-display text-lg font-bold text-slate-900">Club des Formateurs</span>
          </a>
        </div>

        @if (loading()) {
          <div class="text-light-muted">Vérification en cours...</div>
        } @else if (certificate()) {
          <div class="bg-dark-surface border border-emerald-500/30 rounded-xl p-8">
            <div class="text-5xl mb-4">✅</div>
            <h1 class="font-display text-2xl font-bold text-emerald-400 mb-2">Certificat Authentique</h1>
            <p class="text-light-muted text-sm mb-6">Ce certificat a été délivré par la plateforme Club des Formateurs</p>
            <div class="space-y-3 text-left">
              <div class="flex justify-between py-2 border-b border-dark-border">
                <span class="text-light-muted text-sm">Étudiant</span>
                <span class="text-light font-medium text-sm">{{ certificate()!.studentName }}</span>
              </div>
              <div class="flex justify-between py-2 border-b border-dark-border">
                <span class="text-light-muted text-sm">Cours</span>
                <span class="text-light font-medium text-sm">{{ certificate()!.courseTitle }}</span>
              </div>
              <div class="flex justify-between py-2 border-b border-dark-border">
                <span class="text-light-muted text-sm">Formateur</span>
                <span class="text-light font-medium text-sm">{{ certificate()!.teacherName }}</span>
              </div>
              <div class="flex justify-between py-2">
                <span class="text-light-muted text-sm">Code</span>
                <span class="text-primary font-mono text-sm">{{ certificate()!.verificationCode }}</span>
              </div>
            </div>
            <a [href]="certificate()!.pdfUrl" target="_blank"
               class="mt-6 inline-block px-5 py-2.5 bg-primary text-white font-semibold rounded-lg text-sm hover:bg-primary-400 transition-colors">
              Télécharger le certificat PDF
            </a>
          </div>
        } @else {
          <div class="bg-dark-surface border border-red-500/30 rounded-xl p-8">
            <div class="text-5xl mb-4">❌</div>
            <h1 class="font-display text-2xl font-bold text-red-400 mb-2">Certificat invalide</h1>
            <p class="text-light-muted text-sm">Le code de vérification est incorrect ou ce certificat n'existe pas.</p>
          </div>
        }
      </div>
    </div>
  `,
})
export class CertificateVerifyComponent implements OnInit {
  private route = inject(ActivatedRoute);
  private firestore = inject(Firestore);

  loading = signal(true);
  certificate = signal<Certificate | null>(null);

  ngOnInit(): void {
    const code = this.route.snapshot.params['code'];
    if (!code) { this.loading.set(false); return; }

    const q = query(
      collection(this.firestore, 'certificates'),
      where('verificationCode', '==', code.toUpperCase())
    );
    getDocs(q).then(snap => {
      this.certificate.set(snap.empty ? null : snap.docs[0].data() as Certificate);
      this.loading.set(false);
    });
  }
}
