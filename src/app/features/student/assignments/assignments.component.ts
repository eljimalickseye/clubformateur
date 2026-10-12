import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { Store } from '@ngrx/store';
import { ToastrService } from 'ngx-toastr';
import { switchMap, of, combineLatest } from 'rxjs';
import { selectCurrentUser } from '../../../store/auth/auth.selectors';
import { CourseService } from '../../../core/services/course.service';
import { AssignmentService } from '../../../core/services/assignment.service';
import { NotificationService } from '../../../core/services/notification.service';
import {
  Assignment,
  AssignmentSubmission,
  User,
  AssignmentType,
  AssignmentCreationMode,
  SubmissionStatus,
  QuestionAnswer,
  AssignmentMessage
} from '../../../core/models';
import { BackButtonComponent } from '../../../shared/components/back-button/back-button.component';

@Component({
  selector: 'app-student-assignments',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, DatePipe, DecimalPipe, BackButtonComponent],
  templateUrl: './assignments.component.html'
})
export class StudentAssignmentsComponent implements OnInit {
  private store = inject(Store);
  private courseService = inject(CourseService);
  private assignmentService = inject(AssignmentService);
  private notificationService = inject(NotificationService);
  private toastr = inject(ToastrService);

  currentUser$ = this.store.select(selectCurrentUser);
  student: User | null = null;

  allCourseAssignments = signal<Assignment[]>([]);
  mySubmissions = signal<AssignmentSubmission[]>([]);

  activeFilter = signal<'all' | 'pending' | 'submitted' | 'graded' | 'resubmit_requested'>('all');

  // Modal State
  selectedAssignment = signal<Assignment | null>(null);
  modalTab = signal<'work' | 'subject' | 'result' | 'chat'>('work');
  showConfirmModal = signal(false);

  // Form State
  selectedFile: File | null = null;
  questionAnswerTexts: Record<string, string> = {};
  freeTextContent = '';
  isUploading = signal(false);
  uploadProgress = signal(0);

  // Messages State
  messagesList = signal<AssignmentMessage[]>([]);
  newStudentMessage = '';
  isSendingMessage = signal(false);

  // Submissions Map by assignmentId
  submissionsMap = computed(() => {
    const map = new Map<string, AssignmentSubmission>();
    this.mySubmissions().forEach(sub => {
      map.set(sub.assignmentId, sub);
    });
    return map;
  });

  currentSelectedSubmission = computed(() => {
    const a = this.selectedAssignment();
    if (!a) return undefined;
    return this.submissionsMap().get(a.id);
  });

  pendingCount = computed(() => {
    return this.allCourseAssignments().filter(a => {
      const sub = this.submissionsMap().get(a.id);
      return !sub || sub.status === 'resubmit_requested' || sub.status === 'not_started' || sub.status === 'in_progress';
    }).length;
  });

  submittedCount = computed(() => {
    return this.allCourseAssignments().filter(a => {
      const sub = this.submissionsMap().get(a.id);
      return sub && (sub.status === 'submitted' || sub.status === 'pending_review');
    }).length;
  });

  gradedCount = computed(() => {
    return this.allCourseAssignments().filter(a => {
      const sub = this.submissionsMap().get(a.id);
      return sub && sub.status === 'graded';
    }).length;
  });

  resubmitCount = computed(() => {
    return this.allCourseAssignments().filter(a => {
      const sub = this.submissionsMap().get(a.id);
      return sub && sub.status === 'resubmit_requested';
    }).length;
  });

  filteredAssignments = computed(() => {
    const list = this.allCourseAssignments();
    const filter = this.activeFilter();

    if (filter === 'pending') {
      return list.filter(a => {
        const sub = this.submissionsMap().get(a.id);
        return !sub || sub.status === 'resubmit_requested' || sub.status === 'not_started';
      });
    }

    if (filter === 'submitted') {
      return list.filter(a => {
        const sub = this.submissionsMap().get(a.id);
        return sub && (sub.status === 'submitted' || sub.status === 'pending_review');
      });
    }

    if (filter === 'graded') {
      return list.filter(a => {
        const sub = this.submissionsMap().get(a.id);
        return sub && sub.status === 'graded';
      });
    }

    if (filter === 'resubmit_requested') {
      return list.filter(a => {
        const sub = this.submissionsMap().get(a.id);
        return sub && sub.status === 'resubmit_requested';
      });
    }

    return list;
  });

  ngOnInit(): void {
    this.currentUser$.pipe(
      switchMap(user => {
        if (!user) return of(null);
        this.student = user;
        return combineLatest([
          this.courseService.getCourses(),
          this.assignmentService.getStudentSubmissions(user.uid)
        ]);
      })
    ).subscribe(data => {
      if (!data) return;
      const [courses, subs] = data;
      this.mySubmissions.set(subs);

      // Collect course IDs enrolled by student + general
      const courseIds = ['general', ...courses.map(c => c.id)];

      combineLatest(
        courseIds.map(cId => this.assignmentService.getCourseAssignments(cId))
      ).subscribe(assignmentsMatrix => {
        const flat = assignmentsMatrix.flat();
        // Remove duplicates by ID and filter out draft status
        const unique = Array.from(new Map(flat.map(item => [item.id, item])).values())
          .filter(a => a.status !== 'draft');
        this.allCourseAssignments.set(unique);
      });
    });
  }

  subFor(assignmentId: string): AssignmentSubmission | undefined {
    return this.submissionsMap().get(assignmentId);
  }

  statusFor(assignment: Assignment): SubmissionStatus {
    return this.getAssignmentOverallStatus(assignment, this.subFor(assignment.id));
  }

  getSubmissionForAssignment(assignmentId: string): AssignmentSubmission | undefined {
    return this.submissionsMap().get(assignmentId);
  }

  getAssignmentOverallStatus(assignment: Assignment, sub?: AssignmentSubmission): SubmissionStatus {
    if (!sub) {
      if (assignment.dueDate) {
        const due = assignment.dueDate.toDate ? assignment.dueDate.toDate() : new Date(assignment.dueDate as any);
        if (new Date() > due) return 'late';
      }
      return 'not_started';
    }
    return sub.status;
  }

  getStatusLabel(status: SubmissionStatus, sub?: AssignmentSubmission): string {
    switch (status) {
      case 'not_started': return 'Non commencé';
      case 'in_progress': return 'En cours';
      case 'draft': return 'Brouillon';
      case 'submitted':
      case 'pending_review': return 'Soumis • En attente de correction';
      case 'graded': return 'Corrigé par le formateur';
      case 'resubmit_requested': return 'Retour demandé par le professeur';
      case 'late': return 'En retard';
      default: return 'À faire';
    }
  }

  getStatusBadgeBg(status: SubmissionStatus): string {
    switch (status) {
      case 'graded': return 'bg-emerald-50 text-emerald-900 border border-emerald-200';
      case 'submitted':
      case 'pending_review': return 'bg-blue-50 text-blue-900 border border-blue-200';
      case 'resubmit_requested': return 'bg-amber-50 text-amber-900 border border-amber-200 animate-pulse';
      case 'late': return 'bg-red-50 text-red-900 border border-red-200';
      default: return 'bg-slate-50 text-slate-700 border border-slate-200';
    }
  }

  getStatusIcon(status: SubmissionStatus): string {
    switch (status) {
      case 'graded': return '🎯';
      case 'submitted':
      case 'pending_review': return '⏳';
      case 'resubmit_requested': return '⚠️';
      case 'late': return '🚨';
      default: return '📝';
    }
  }

  getTypeLabel(type: AssignmentType): string {
    if (type === 'exam') return 'Examen officiel';
    if (type === 'homework') return 'Devoir noté';
    if (type === 'project') return 'Projet';
    return 'Exercice';
  }

  getTypeBadgeClass(type: AssignmentType): string {
    if (type === 'exam') return 'bg-red-50 text-red-700 border-red-200';
    if (type === 'homework') return 'bg-amber-50 text-amber-700 border-amber-200';
    if (type === 'project') return 'bg-purple-50 text-purple-700 border-purple-200';
    return 'bg-blue-50 text-blue-700 border-blue-200';
  }

  getModeLabel(mode?: AssignmentCreationMode): string {
    if (mode === 'document') return 'Word (.docx) / PDF';
    if (mode === 'template_to_fill') return 'Modèle à compléter';
    return 'Directement dans l’application';
  }

  formatFileSize(bytes?: number): string {
    if (!bytes) return 'Fichier joint';
    if (bytes < 1024) return `${bytes} o`;
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} Ko`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} Mo`;
  }

  openAssignmentModal(assignment: Assignment, tab: 'work' | 'subject' | 'result' | 'chat'): void {
    this.selectedAssignment.set(assignment);
    this.modalTab.set(tab);
    this.selectedFile = null;
    this.freeTextContent = '';
    this.questionAnswerTexts = {};
    this.showConfirmModal.set(false);

    const existingSub = this.submissionsMap().get(assignment.id);
    if (existingSub) {
      this.freeTextContent = existingSub.textContent || '';
      if (existingSub.questionAnswers) {
        existingSub.questionAnswers.forEach(qa => {
          this.questionAnswerTexts[qa.questionId] = qa.answerText || '';
        });
      }
    }

    // Load contextual messages for this assignment
    if (this.student) {
      this.assignmentService.getAssignmentMessages(assignment.id, this.student.uid).subscribe(msgs => {
        this.messagesList.set(msgs as AssignmentMessage[]);
      });
    }
  }

  closeModal(): void {
    this.selectedAssignment.set(null);
    this.selectedFile = null;
    this.showConfirmModal.set(false);
  }

  onFileSelected(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) {
      this.selectedFile = file;
      this.toastr.info(`Fichier sélectionné : ${file.name} (${this.formatFileSize(file.size)})`);
    }
  }

  canSubmit(): boolean {
    const a = this.selectedAssignment();
    if (!a) return false;

    // Has attached a document
    if (this.selectedFile) return true;

    // Has written free text
    if (this.freeTextContent.trim().length > 0) return true;

    // Has answered questions
    const answeredCount = Object.values(this.questionAnswerTexts).filter(t => t && t.trim().length > 0).length;
    if (answeredCount > 0) return true;

    return false;
  }

  promptSubmissionConfirmation(): void {
    if (!this.canSubmit()) {
      this.toastr.warning('Veuillez joindre votre document complété ou rédiger votre réponse avant de soumettre.');
      return;
    }
    this.showConfirmModal.set(true);
  }

  async executeFinalSubmission(): Promise<void> {
    const a = this.selectedAssignment();
    if (!a || !this.student) return;

    this.showConfirmModal.set(false);
    this.isUploading.set(true);
    this.uploadProgress.set(20);

    try {
      let attachmentUrl = '';
      let attachmentName = '';
      let attachmentSize = 0;

      // 1. Upload completed file if student attached one
      if (this.selectedFile) {
        this.uploadProgress.set(50);
        const upRes = await this.assignmentService.uploadStudentResponseDocument(a.id, this.student.uid, this.selectedFile);
        attachmentUrl = upRes.url;
        attachmentName = upRes.name;
        attachmentSize = upRes.size;
      }

      this.uploadProgress.set(80);

      // 2. Format question answers if any
      let questionAnswers: QuestionAnswer[] | undefined = undefined;
      if (a.questions && a.questions.length > 0) {
        questionAnswers = a.questions.map(q => ({
          questionId: q.id,
          questionText: q.question,
          answerText: this.questionAnswerTexts[q.id] || '',
          maxPoints: q.points,
        }));
      }

      const existingSub = this.submissionsMap().get(a.id);

      if (existingSub) {
        // Update existing submission (resubmission)
        await this.assignmentService.updateSubmission(existingSub.id, {
          textContent: this.freeTextContent.trim() || undefined,
          attachmentUrl: attachmentUrl || existingSub.attachmentUrl,
          attachmentName: attachmentName || existingSub.attachmentName,
          attachmentSize: attachmentSize || existingSub.attachmentSize,
          attachmentLastModified: Date.now(),
          questionAnswers: questionAnswers || existingSub.questionAnswers,
          status: 'submitted',
        });
      } else {
        // Create new submission
        await this.assignmentService.submitAssignment({
          assignmentId: a.id,
          assignmentTitle: a.title,
          courseId: a.courseId,
          courseTitle: a.courseTitle,
          studentId: this.student.uid,
          studentName: this.student.displayName || 'Étudiant',
          studentEmail: this.student.email || '',
          studentPhotoURL: this.student.photoURL,
          textContent: this.freeTextContent.trim() || undefined,
          attachmentUrl: attachmentUrl || undefined,
          attachmentName: attachmentName || undefined,
          attachmentSize: attachmentSize || undefined,
          attachmentLastModified: Date.now(),
          questionAnswers,
          submissionMode: this.selectedFile ? 'file' : 'direct',
          status: 'submitted',
          maxScore: a.maxScore || 20,
        });
      }

      this.uploadProgress.set(100);

      // 3. Notify teacher
      if (a.teacherId) {
        this.notificationService.notifyTeacherForSubmission(
          a.teacherId,
          this.student.displayName || 'Un étudiant',
          a.title
        );
      }

      this.toastr.success('🎉 Votre devoir a été soumis avec succès ! Le formateur en a été notifié.');
      this.closeModal();

    } catch (e) {
      console.error('Error submitting assignment:', e);
      this.toastr.error('Erreur lors de la soumission de votre travail.');
    } finally {
      this.isUploading.set(false);
      this.uploadProgress.set(0);
    }
  }

  async sendMessageToTeacher(): Promise<void> {
    const a = this.selectedAssignment();
    if (!a || !this.student || !this.newStudentMessage.trim()) return;

    this.isSendingMessage.set(true);
    const text = this.newStudentMessage.trim();
    this.newStudentMessage = '';

    try {
      const activeSub = this.currentSelectedSubmission();
      await this.assignmentService.sendAssignmentMessage({
        assignmentId: a.id,
        submissionId: activeSub?.id,
        studentId: this.student.uid,
        teacherId: a.teacherId,
        senderId: this.student.uid,
        senderName: this.student.displayName || 'Étudiant',
        senderRole: 'student',
        text
      });

      if (a.teacherId) {
        this.notificationService.notifyAssignmentMessage(
          a.teacherId,
          this.student.displayName || 'Un étudiant',
          a.title,
          text
        );
      }
    } catch {
      this.toastr.error('Erreur lors de l’envoi du message.');
    } finally {
      this.isSendingMessage.set(false);
    }
  }

  formatTs(ts: any): Date {
    if (!ts) return new Date();
    return ts.toDate ? ts.toDate() : new Date(ts);
  }

  // Non-nullable alias for template use inside @if guards
  getSub(): AssignmentSubmission {
    return this.currentSelectedSubmission()!;
  }
}
