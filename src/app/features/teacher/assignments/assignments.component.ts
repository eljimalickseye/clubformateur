import { Component, inject, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DatePipe, DecimalPipe } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
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
  Course,
  User,
  AssignmentType,
  AssignmentCreationMode,
  AssignmentStatus,
  AssignmentQuestion,
  AssignmentMessage
} from '../../../core/models';
import { Timestamp } from '@angular/fire/firestore';

@Component({
  selector: 'app-teacher-assignments',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, DatePipe, DecimalPipe],
  templateUrl: './assignments.component.html'
})
export class TeacherAssignmentsComponent implements OnInit {
  private store = inject(Store);
  private courseService = inject(CourseService);
  private assignmentService = inject(AssignmentService);
  private notificationService = inject(NotificationService);
  private toastr = inject(ToastrService);
  private fb = inject(FormBuilder);

  currentUser$ = this.store.select(selectCurrentUser);
  teacherId = '';
  teacherName = '';

  activeTab = signal<'assignments' | 'submissions'>('assignments');
  assignmentFilter = signal<'all' | 'direct' | 'document' | 'template_to_fill' | 'draft'>('all');
  submissionFilter = signal<'all' | 'submitted' | 'graded' | 'resubmit_requested'>('all');

  myCourses = signal<Course[]>([]);
  assignments = signal<Assignment[]>([]);
  submissions = signal<AssignmentSubmission[]>([]);

  // Modal Création Devoir
  showCreateModal = signal(false);
  isSubmitting = signal(false);
  selectedAssignmentFile: File | null = null;
  selectedCreationMode = signal<AssignmentCreationMode>('direct');
  questionsList = signal<AssignmentQuestion[]>([
    { id: 'q1', question: 'Question 1 : Analysez et commentez le sujet proposé.', points: 10, order: 1 }
  ]);

  createAssignmentForm = this.fb.group({
    courseId: ['', Validators.required],
    title: ['', Validators.required],
    type: ['homework' as AssignmentType, Validators.required],
    status: ['published' as AssignmentStatus, Validators.required],
    description: ['', Validators.required],
    maxScore: [20, [Validators.required, Validators.min(1)]],
    timeLimitMinutes: [null as number | null],
    dueDate: [''],
    allowDirectAnswer: [true],
    allowFileUpload: [true],
    allowResubmission: [true],
  });

  // Drawer Correction & Notation
  selectedSubmission = signal<AssignmentSubmission | null>(null);
  drawerTab = signal<'grade' | 'messages'>('grade');
  gradeScore: number | null = null;
  generalAppreciation = '';
  feedbackText = '';
  isResubmitRequested = false;
  selectedCorrectedFile: File | null = null;
  isSubmittingGrade = signal(false);

  // Question-by-question grading state (for Mode A assignments)
  questionScores: Record<string, { points: number; comment: string }> = {};

  // Audio Recording State
  mediaRecorder: MediaRecorder | null = null;
  audioChunks: Blob[] = [];
  isRecording = signal(false);
  recordingSeconds = signal(0);
  recordingInterval: any = null;
  recordedAudioBlob = signal<Blob | null>(null);
  recordedAudioUrl = signal<string | null>(null);

  // Assignment Context Messages
  assignmentMessages = signal<AssignmentMessage[]>([]);
  newMessageText = '';
  isSendingMessage = signal(false);

  // Computed KPIs
  totalSubmissionsCount = computed(() => this.submissions().length);
  pendingCorrectionsCount = computed(() => this.submissions().filter(s => s.status === 'submitted').length);
  gradedSubmissionsCount = computed(() => this.submissions().filter(s => s.status === 'graded').length);
  resubmitRequestedCount = computed(() => this.submissions().filter(s => s.status === 'resubmit_requested').length);

  filteredAssignments = computed(() => {
    const list = this.assignments();
    const filter = this.assignmentFilter();
    if (filter === 'draft') return list.filter(a => a.status === 'draft');
    if (filter === 'direct') return list.filter(a => a.creationMode === 'direct');
    if (filter === 'document') return list.filter(a => a.creationMode === 'document');
    if (filter === 'template_to_fill') return list.filter(a => a.creationMode === 'template_to_fill');
    return list;
  });

  filteredSubmissions = computed(() => {
    const list = this.submissions();
    const filter = this.submissionFilter();
    if (filter === 'submitted') return list.filter(s => s.status === 'submitted');
    if (filter === 'graded') return list.filter(s => s.status === 'graded');
    if (filter === 'resubmit_requested') return list.filter(s => s.status === 'resubmit_requested');
    return list;
  });

  ngOnInit(): void {
    this.currentUser$.pipe(
      switchMap(user => {
        if (!user) return of(null);
        this.teacherId = user.uid;
        this.teacherName = user.displayName || 'Professeur';
        return combineLatest([
          this.courseService.getTeacherCourses(user.uid),
          this.assignmentService.getTeacherAssignments(user.uid)
        ]);
      })
    ).subscribe(data => {
      if (!data) return;
      const [courses, assignments] = data;
      this.myCourses.set(courses);
      this.assignments.set(assignments);

      const courseIds = courses.map(c => c.id);
      this.assignmentService.getTeacherAllSubmissions(courseIds).subscribe(subs => {
        this.submissions.set(subs);
      });
    });
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
    if (mode === 'document') return 'Document Word / PDF';
    if (mode === 'template_to_fill') return 'Document à compléter';
    return 'Direct dans l’application';
  }

  openCreateModal(): void {
    this.createAssignmentForm.reset({
      courseId: this.myCourses()[0]?.id || 'general',
      title: '',
      type: 'homework',
      status: 'published',
      description: '',
      maxScore: 20,
      timeLimitMinutes: null,
      dueDate: '',
      allowDirectAnswer: true,
      allowFileUpload: true,
      allowResubmission: true,
    });
    this.selectedCreationMode.set('direct');
    this.questionsList.set([
      { id: 'q1', question: 'Question 1 : Décrivez la démarche et justifiez vos réponses.', points: 10, order: 1 }
    ]);
    this.selectedAssignmentFile = null;
    this.showCreateModal.set(true);
  }

  addQuestion(): void {
    const nextIdx = this.questionsList().length + 1;
    this.questionsList.update(list => [
      ...list,
      { id: `q${Date.now()}`, question: `Question ${nextIdx} : `, points: 5, order: nextIdx }
    ]);
  }

  removeQuestion(index: number): void {
    this.questionsList.update(list => list.filter((_, i) => i !== index));
  }

  onAssignmentFileSelected(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) {
      this.selectedAssignmentFile = file;
    }
  }

  onCorrectedFileSelected(event: Event): void {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) {
      this.selectedCorrectedFile = file;
    }
  }

  async saveAssignment(): Promise<void> {
    if (this.createAssignmentForm.invalid) return;

    this.isSubmitting.set(true);
    const formVal = this.createAssignmentForm.value;
    const selectedCourse = this.myCourses().find(c => c.id === formVal.courseId);
    const courseTitle = selectedCourse?.title || (formVal.courseId === 'general' ? 'Formation Générale' : 'Cours');

    try {
      let attachmentUrl = '';
      let attachmentName = '';
      let attachmentSize = 0;
      let attachmentType: 'docx' | 'pdf' | 'other' = 'other';

      const courseIdToUse = formVal.courseId || 'general';

      if (this.selectedAssignmentFile) {
        const uploadRes = await this.assignmentService.uploadAssignmentDocument(courseIdToUse, this.selectedAssignmentFile);
        attachmentUrl = uploadRes.url;
        attachmentName = uploadRes.name;
        attachmentSize = uploadRes.size;
        if (uploadRes.name.endsWith('.docx') || uploadRes.name.endsWith('.doc')) {
          attachmentType = 'docx';
        } else if (uploadRes.name.endsWith('.pdf')) {
          attachmentType = 'pdf';
        }
      }

      let dueTimestamp: Timestamp | undefined = undefined;
      if (formVal.dueDate) {
        dueTimestamp = Timestamp.fromDate(new Date(formVal.dueDate));
      }

      const assignmentId = await this.assignmentService.createAssignment({
        courseId: courseIdToUse,
        courseTitle,
        teacherId: this.teacherId || 'teacher_uid',
        teacherName: this.teacherName || 'Professeur',
        title: formVal.title!,
        description: formVal.description!,
        type: formVal.type as AssignmentType,
        creationMode: this.selectedCreationMode(),
        status: formVal.status as AssignmentStatus,
        maxScore: Number(formVal.maxScore) || 20,
        timeLimitMinutes: formVal.timeLimitMinutes ? Number(formVal.timeLimitMinutes) : undefined,
        dueDate: dueTimestamp,
        questions: this.selectedCreationMode() === 'direct' ? this.questionsList() : undefined,
        attachmentUrl,
        attachmentName,
        attachmentSize,
        attachmentType,
        allowDirectAnswer: formVal.allowDirectAnswer ?? true,
        allowFileUpload: formVal.allowFileUpload ?? true,
        allowResubmission: formVal.allowResubmission ?? true,
      });

      // Si le devoir est publié, notifier les étudiants
      if (formVal.status === 'published') {
        this.notificationService.notifyEnrolledStudentsForAssignment(
          courseIdToUse,
          courseTitle,
          this.teacherName || 'Professeur',
          formVal.title!,
          assignmentId
        ).then(count => {
          this.toastr.success(`🚀 Devoir publié avec succès ! ${count} étudiant(s) notifié(s).`);
        });
      } else {
        this.toastr.info('Devoir enregistré comme brouillon.');
      }

      this.showCreateModal.set(false);
    } catch (err: any) {
      console.error(err);
      this.toastr.error('Erreur lors de la création du devoir.');
    } finally {
      this.isSubmitting.set(false);
    }
  }

  async deleteAssignment(id: string): Promise<void> {
    if (!confirm('Êtes-vous sûr de vouloir supprimer cette évaluation ?')) return;
    try {
      await this.assignmentService.deleteAssignment(id);
      this.assignments.update(list => list.filter(a => a.id !== id));
      this.toastr.success('Devoir supprimé.');
    } catch (e) {
      this.toastr.error('Erreur lors de la suppression.');
    }
  }

  viewSubmissionsForAssignment(assignment: Assignment): void {
    this.activeTab.set('submissions');
  }

  // ─── Grading & Correction Drawer ───────────────────────────────

  openGradingDrawer(sub: AssignmentSubmission): void {
    this.selectedSubmission.set(sub);
    this.drawerTab.set('grade');
    this.gradeScore = sub.score !== undefined ? sub.score : null;
    this.generalAppreciation = sub.generalAppreciation || '';
    this.feedbackText = sub.feedbackText || '';
    this.isResubmitRequested = sub.status === 'resubmit_requested';
    this.selectedCorrectedFile = null;
    this.resetVoiceRecording();

    // Initialize question scores if student submitted in-app question answers
    this.questionScores = {};
    if (sub.questionAnswers) {
      sub.questionAnswers.forEach(qa => {
        this.questionScores[qa.questionId] = {
          points: qa.pointsEarned !== undefined ? qa.pointsEarned : qa.maxPoints,
          comment: qa.teacherComment || ''
        };
      });
    }

    // Load contextual messages for this student on this assignment
    this.assignmentService.getAssignmentMessages(sub.assignmentId, sub.studentId).subscribe(msgs => {
      this.assignmentMessages.set(msgs as AssignmentMessage[]);
    });
  }

  closeGradingDrawer(): void {
    this.stopVoiceRecording();
    this.resetVoiceRecording();
    this.selectedSubmission.set(null);
  }

  async startVoiceRecording(): Promise<void> {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.mediaRecorder = new MediaRecorder(stream);
      this.audioChunks = [];

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          this.audioChunks.push(event.data);
        }
      };

      this.mediaRecorder.onstop = () => {
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });
        this.recordedAudioBlob.set(audioBlob);
        this.recordedAudioUrl.set(URL.createObjectURL(audioBlob));
        stream.getTracks().forEach(track => track.stop());
      };

      this.mediaRecorder.start();
      this.isRecording.set(true);
      this.recordingSeconds.set(0);

      this.recordingInterval = setInterval(() => {
        this.recordingSeconds.update(s => s + 1);
      }, 1000);
    } catch (err) {
      console.error('Erreur accès micro:', err);
      this.toastr.error('Impossible d\'accéder au microphone. Veuillez vérifier vos autorisations.');
    }
  }

  stopVoiceRecording(): void {
    if (this.mediaRecorder && this.isRecording()) {
      this.mediaRecorder.stop();
      this.isRecording.set(false);
      clearInterval(this.recordingInterval);
    }
  }

  resetVoiceRecording(): void {
    this.stopVoiceRecording();
    this.recordedAudioBlob.set(null);
    this.recordedAudioUrl.set(null);
    this.recordingSeconds.set(0);
  }

  formatRecordTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  calculateTotalFromQuestions(): void {
    const vals = Object.values(this.questionScores);
    if (vals.length > 0) {
      const total = vals.reduce((sum, item) => sum + (Number(item.points) || 0), 0);
      this.gradeScore = total;
    }
  }

  async submitGrade(): Promise<void> {
    const sub = this.selectedSubmission();
    if (!sub || this.gradeScore === null) return;

    this.isSubmittingGrade.set(true);

    try {
      let voiceUrl = sub.feedbackVoiceUrl;
      let voiceDuration = sub.feedbackVoiceDuration;

      // Upload newly recorded voice feedback
      const newVoiceBlob = this.recordedAudioBlob();
      if (newVoiceBlob) {
        voiceUrl = await this.assignmentService.uploadVoiceFeedback(sub.assignmentId, sub.id, newVoiceBlob);
        voiceDuration = this.recordingSeconds();
      }

      // Upload corrected document if selected
      let correctedUrl = sub.correctedDocumentUrl;
      let correctedName = sub.correctedDocumentName;
      if (this.selectedCorrectedFile) {
        const upRes = await this.assignmentService.uploadCorrectedDocument(sub.assignmentId, sub.id, this.selectedCorrectedFile);
        correctedUrl = upRes.url;
        correctedName = upRes.name;
      }

      // Format updated question answers with scores and teacher comments
      let updatedQuestions = sub.questionAnswers;
      if (updatedQuestions && updatedQuestions.length > 0) {
        updatedQuestions = updatedQuestions.map(qa => ({
          ...qa,
          pointsEarned: this.questionScores[qa.questionId]?.points ?? qa.pointsEarned,
          teacherComment: this.questionScores[qa.questionId]?.comment ?? qa.teacherComment
        }));
      }

      if (this.isResubmitRequested) {
        await this.assignmentService.requestResubmission(sub.id, this.feedbackText || 'Veuillez revoir votre copie et la resoumettre.');
        this.toastr.warning('Nouvelle soumission demandée à l’étudiant.');
      } else {
        await this.assignmentService.gradeSubmission(sub.id, sub.assignmentId, {
          score: Number(this.gradeScore),
          maxScore: sub.maxScore || 20,
          generalAppreciation: this.generalAppreciation,
          feedbackText: this.feedbackText,
          feedbackVoiceUrl: voiceUrl,
          feedbackVoiceDuration: voiceDuration,
          correctedDocumentUrl: correctedUrl,
          correctedDocumentName: correctedName,
          questionAnswers: updatedQuestions,
          allowResubmit: !this.isResubmitRequested,
          gradedBy: this.teacherName,
        });

        this.notificationService.notifyStudentForGraded(
          sub.studentId,
          sub.assignmentTitle || 'Devoir',
          Number(this.gradeScore),
          sub.maxScore || 20
        );

        this.toastr.success('Note, appréciations et document corrigé enregistrés !');
      }

      this.closeGradingDrawer();
    } catch (err: any) {
      console.error(err);
      this.toastr.error('Erreur lors de l\'enregistrement de la correction.');
    } finally {
      this.isSubmittingGrade.set(false);
    }
  }

  // ─── Assignment Contextual Chat ────────────────────────────────

  async sendMessage(): Promise<void> {
    const sub = this.selectedSubmission();
    if (!sub || !this.newMessageText.trim()) return;

    this.isSendingMessage.set(true);
    const text = this.newMessageText.trim();
    this.newMessageText = '';

    try {
      await this.assignmentService.sendAssignmentMessage({
        assignmentId: sub.assignmentId,
        submissionId: sub.id,
        studentId: sub.studentId,
        teacherId: this.teacherId,
        senderId: this.teacherId,
        senderName: this.teacherName || 'Professeur',
        senderRole: 'teacher',
        text
      });

      this.notificationService.notifyAssignmentMessage(
        sub.studentId,
        this.teacherName || 'Professeur',
        sub.assignmentTitle || 'Devoir',
        text
      );
    } catch (e) {
      this.toastr.error('Erreur lors de l’envoi du message.');
    } finally {
      this.isSendingMessage.set(false);
    }
  }

  formatFileSize(bytes?: number): string {
    if (!bytes) return 'Fichier joint';
    if (bytes < 1024) return `${bytes} o`;
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} Ko`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} Mo`;
  }

  formatTs(ts: any): Date {
    if (!ts) return new Date();
    return ts.toDate ? ts.toDate() : new Date(ts);
  }
}
