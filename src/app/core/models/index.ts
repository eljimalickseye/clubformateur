import { Timestamp } from '@angular/fire/firestore';

// ─── Enums ───────────────────────────────────────────────────
export type UserRole = 'student' | 'teacher' | 'admin';
export type CourseLevel = 'débutant' | 'intermédiaire' | 'avancé';
export type CourseLanguage = 'fr' | 'ar' | 'wo' | 'en';
export type LessonType = 'video' | 'pdf' | 'quiz' | 'live' | 'text';
export type PaymentMethod = 'wave' | 'orange_money' | 'free_money' | 'card' | 'bank_transfer';
export type PaymentStatus = 'pending' | 'success' | 'failed' | 'refunded';
export type LiveSessionStatus = 'scheduled' | 'live' | 'ended' | 'cancelled';
export type NotificationType = 'enrollment' | 'enrollment_request' | 'request_accepted' | 'request_rejected' | 'live_start' | 'live_replay' | 'course_update' | 'payment' | 'certificate' | 'message' | 'review' | 'course_approved' | 'course_rejected';
export type PricingType = 'one-time' | 'monthly';
export type CoursePublicationStatus = 'draft' | 'pending_approval' | 'published' | 'rejected' | 'archived';
export type EnrollmentRequestStatus = 'pending' | 'accepted' | 'rejected';

export interface TeacherScheduleSlot {
  day: string;          // Ex: Lundi, Mercredi, Samedi
  hours: string;        // Ex: 18h00 - 19h30
  activity: string;     // Ex: Masterclass Live, Suivi & Tutorat, Atelier pratique
  courseTitle?: string; // Titre du cours associé
}

// ─── User ────────────────────────────────────────────────────
export interface User {
  uid: string;
  email: string;
  displayName: string;
  photoURL: string;
  role: UserRole;
  phone?: string;
  bio?: string;
  speciality?: string;      // For teachers
  teachingLevel?: string;   // Niveau enseigné par le professeur (ex: Licence 3)
  taughtLevels?: string;    // Niveaux enseignés (ex: Licence 3)
  experience?: string;      // For teachers
  diplomas?: string[];      // For teachers
  languages?: string[];     // For teachers
  introVideoUrl?: string;   // Video de presentation personnelle du formateur
  scheduleSlots?: TeacherScheduleSlot[]; // Emploi du temps / Disponibilites
  socialLinks?: { youtube?: string; linkedin?: string; twitter?: string; website?: string };
  payoutDetails?: {
    method: PaymentMethod;
    accountNumber: string;
    accountName: string;
  };
  profileCompletedPercent?: number;
  enrolledCourses: string[];
  totalEarnings?: number;   // For teachers
  matricule?: string;       // Matricule etudiant (ex: CF-2026-XXXX)
  academicLevel?: string;   // Ex: Licence 2 • Sciences & Technologies
  academicYear?: string;    // Ex: 2025-2026
  isOnline?: boolean;       // Realtime online presence
  lastSeen?: any;           // Realtime presence timestamp
  isVerified: boolean;
  isActive: boolean;
  fcmToken?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ─── Category ────────────────────────────────────────────────
export interface Category {
  id: string;
  name: string;
  nameAr?: string;
  slug: string;
  iconUrl: string;
  courseCount: number;
  order: number;
}

// ─── Course ──────────────────────────────────────────────────
export interface Course {
  id: string;
  title: string;
  description: string;
  shortDescription: string;
  teacherId: string;
  teacherName: string;
  teacherPhotoURL: string;
  categoryId: string;
  categoryName: string;
  price: number;
  originalPrice?: number;  // For discounts
  pricingType: PricingType;
  currency: 'XOF';
  thumbnailUrl: string;
  promoVideoUrl?: string;
  totalDuration: number;   // seconds
  totalLessons: number;
  level: CourseLevel;
  language: CourseLanguage;
  tags: string[];
  learningObjectives: string[];
  requirements: string[];
  rating: number;
  ratingCount: number;
  enrolledCount: number;
  viewsCount?: number;
  earnings?: number;
  maxStudents?: number;
  isPublished: boolean;
  publicationStatus?: CoursePublicationStatus;
  adminFeedback?: string;
  isFeatured: boolean;
  isFree: boolean;
  hasLiveClasses: boolean;
  hasCertificate: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ─── Lesson ──────────────────────────────────────────────────
export interface Lesson {
  id: string;
  courseId: string;
  title: string;
  description?: string;
  type: LessonType;
  videoUrl?: string;
  videoPublicId?: string;  // Cloudinary
  hlsUrl?: string;         // HLS streaming URL
  pdfUrl?: string;
  pdfDocName?: string;
  notes?: string;
  textContent?: string;
  duration?: number;       // seconds
  isFree: boolean;
  order: number;
  quizId?: string;
  liveSessionId?: string;
  resources?: { name: string; url: string; type: string }[];
  createdAt: Timestamp;
}

// ─── Section (grouping lessons) ──────────────────────────────
export interface Section {
  id: string;
  courseId: string;
  title: string;
  order: number;
  lessonIds: string[];
}

// ─── Quiz ────────────────────────────────────────────────────
export interface Quiz {
  id: string;
  courseId: string;
  lessonId?: string;
  title: string;
  description?: string;
  passingScore: number;  // percentage
  timeLimit?: number;    // minutes
  allowRetake: boolean;
  showAnswers: boolean;
  createdAt: Timestamp;
}

export interface QuizQuestion {
  id: string;
  quizId: string;
  question: string;
  type: 'single' | 'multiple' | 'true_false';
  options: { id: string; text: string }[];
  correctAnswers: string[];
  explanation?: string;
  points: number;
  order: number;
}

export interface QuizAttempt {
  id: string;
  quizId: string;
  studentId: string;
  answers: { questionId: string; selectedAnswers: string[] }[];
  score: number;
  passed: boolean;
  startedAt: Timestamp;
  completedAt: Timestamp;
}

// ─── Enrollment ──────────────────────────────────────────────
export interface Enrollment {
  id: string;
  studentId: string;
  studentName: string;
  courseId: string;
  enrolledAt: Timestamp;
  completedLessons: string[];
  progress: number;         // 0-100
  lastAccessedAt: Timestamp;
  lastLessonId?: string;
  certificateIssued: boolean;
  certificateUrl?: string;
  certificateIssuedAt?: Timestamp;
  paymentId: string;
  status: 'active' | 'expired' | 'suspended';
  validUntil?: Timestamp;   // For monthly subscriptions
  lastPaymentAt?: Timestamp;
}

// ─── Live Session ────────────────────────────────────────────
export interface LiveSession {
  id: string;
  courseId: string;
  courseName: string;
  teacherId: string;
  teacherName: string;
  teacherPhotoURL?: string;
  title: string;
  description?: string;
  scheduledAt: Timestamp;
  startedAt?: Timestamp;
  endedAt?: Timestamp;
  durationMinutes?: number;
  livekitRoomName?: string;
  roomName?: string;
  status: LiveSessionStatus;
  hasReplay?: boolean;
  replayUrl?: string;
  replayDuration?: string;
  recordingUrl?: string;
  maxParticipants?: number;
  attendees?: string[];
  attendeeCount?: number;
  connectedParticipants?: string[];
  connectedParticipantNames?: Record<string, string>;
  participantCount?: number;
  thumbnailUrl?: string;
  raisedHands?: Array<{
    uid: string;
    displayName: string;
    photoURL?: string;
    raisedAt: number;
  }>;
  allowedSpeakers?: string[]; // Students permitted by teacher to open mic
  isMuteAll?: boolean;
  isFlash5Min?: boolean;      // Session / Capsule vidéo de 5 minutes chrono
  pdfDocUrl?: string;         // Document PDF d'accompagnement
  pdfDocName?: string;        // Nom du fichier PDF
  notes?: string;             // Notes textuelles du formateur
  recordingBlobUrl?: string;  // Vidéo enregistrée en local ou Replay
  createdAt?: Timestamp;
  updatedAt?: Timestamp;
}

// ─── Payment ─────────────────────────────────────────────────
export interface Payment {
  id: string;
  userId: string;
  studentName?: string;
  studentEmail?: string;
  courseId: string;
  courseTitle: string;
  teacherId: string;
  amount: number;
  platformFee: number;      // 10% platform commission
  teacherEarnings: number;  // 90% to teacher
  currency: 'XOF';
  method: PaymentMethod;
  transactionId: string;
  waveRef?: string;
  orangeRef?: string;
  status: PaymentStatus;
  metadata?: Record<string, unknown>;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ─── Enrollment Request ──────────────────────────────────────
export interface EnrollmentRequest {
  id: string;
  studentId: string;
  studentName: string;
  studentEmail: string;
  studentPhotoURL?: string;
  courseId: string;
  courseTitle: string;
  teacherId: string;
  teacherName?: string;
  message?: string;
  status: EnrollmentRequestStatus;
  reviewedAt?: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ─── Review ──────────────────────────────────────────────────
export interface Review {
  id: string;
  courseId: string;
  studentId: string;
  studentName: string;
  studentPhotoURL: string;
  rating: number;          // 1-5
  comment: string;
  teacherReply?: string;
  createdAt: Timestamp;
}

// ─── Message / Conversation ───────────────────────────────────
export interface Conversation {
  id: string;
  participants: string[];
  participantNames: Record<string, string>;
  participantPhotos: Record<string, string>;
  lastMessage: string;
  lastMessageAt: Timestamp;
  unreadCount: Record<string, number>;
  courseId?: string;
  courseName?: string;
}

export interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  senderName: string;
  senderPhotoURL?: string;
  content: string;
  type: 'text' | 'image' | 'file' | 'audio';
  fileUrl?: string;
  fileName?: string;
  audioDuration?: number;
  readBy: string[];
  createdAt: Timestamp;
}

// ─── Forum ────────────────────────────────────────────────────
export interface ForumPost {
  id: string;
  courseId: string;
  authorId: string;
  authorName: string;
  authorPhotoURL: string;
  authorRole: UserRole;
  title: string;
  content: string;
  tags: string[];
  likeCount: number;
  replyCount: number;
  isPinned: boolean;
  isResolved: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ─── Notification ────────────────────────────────────────────
export interface Notification {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
  isRead: boolean;
  createdAt: Timestamp;
}

// ─── Certificate ─────────────────────────────────────────────
export interface Certificate {
  id: string;
  studentId: string;
  studentName: string;
  courseId: string;
  courseTitle: string;
  teacherName: string;
  issuedAt: Timestamp;
  pdfUrl: string;
  verificationCode: string;
}

// ─── Progress ────────────────────────────────────────────────
export interface Progress {
  userId: string;
  courseId: string;
  completedLessons: string[];
  quizAttempts: Record<string, { score: number; passed: boolean; attempts: number }>;
  totalWatchTime: number;  // seconds
  lastAccessedAt: Timestamp;
  progress: number;        // 0-100
}

// ─── Assignment (Devoirs & Exercices) ─────────────────────────
// ─── Assignment (Devoirs & Examens) ─────────────────────────
export type AssignmentType = 'exercise' | 'homework' | 'project' | 'exam';
export type AssignmentCreationMode = 'direct' | 'document' | 'template_to_fill';
export type AssignmentStatus = 'draft' | 'published' | 'closed';

export interface AssignmentQuestion {
  id: string;
  question: string;
  points: number;
  order: number;
  instructions?: string;
  sampleAnswer?: string;
}

export interface Assignment {
  id: string;
  courseId: string;
  courseTitle: string;
  teacherId: string;
  teacherName?: string;
  title: string;
  description: string;
  type: AssignmentType;
  creationMode?: AssignmentCreationMode;
  status?: AssignmentStatus;
  dueDate?: Timestamp;
  timeLimitMinutes?: number;
  maxScore: number;       // default 20
  questions?: AssignmentQuestion[];
  attachmentUrl?: string; // Sujet Word (.docx), PDF ou modèle
  attachmentName?: string;
  attachmentType?: 'docx' | 'pdf' | 'other';
  attachmentSize?: number;
  additionalFiles?: { name: string; url: string; size?: number }[];
  allowDirectAnswer?: boolean; // L'étudiant peut rédiger directement en ligne
  allowFileUpload?: boolean;   // L'étudiant peut déposer un fichier Word/PDF
  allowResubmission?: boolean; // Le professeur autorise ou non une ré-évaluation
  submissionCount: number;
  gradedCount: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// ─── Assignment Submission (Rendu d'évaluation) ───────────────
export type SubmissionStatus = 
  | 'not_started' 
  | 'in_progress' 
  | 'draft' 
  | 'submitted' 
  | 'pending_review' 
  | 'graded' 
  | 'resubmit_requested' 
  | 'late';

export interface QuestionAnswer {
  questionId: string;
  questionText: string;
  answerText?: string;
  fileUrl?: string;
  fileName?: string;
  pointsEarned?: number;
  maxPoints: number;
  teacherComment?: string;
}

export interface AssignmentSubmission {
  id: string;
  assignmentId: string;
  assignmentTitle?: string;
  courseId: string;
  courseTitle?: string;
  studentId: string;
  studentName: string;
  studentEmail?: string;
  studentPhotoURL?: string;
  submittedAt: Timestamp;
  submissionMode?: 'direct' | 'file';
  questionAnswers?: QuestionAnswer[];
  textContent?: string;
  attachmentUrl?: string;
  attachmentName?: string;
  attachmentSize?: number;
  attachmentLastModified?: number;
  status: SubmissionStatus;
  score?: number;            // Note attribuée (ex: 18)
  maxScore: number;          // Barème (ex: 20)
  generalAppreciation?: string; // Appréciation globale
  feedbackText?: string;     // Commentaires écrits détaillés
  feedbackVoiceUrl?: string; // URL enregistrement vocal Firebase Storage
  feedbackVoiceDuration?: number; // Durée en secondes
  correctedDocumentUrl?: string; // Document corrigé joint par le professeur
  correctedDocumentName?: string;
  allowResubmit?: boolean;
  gradedAt?: Timestamp;
  gradedBy?: string;
}

// ─── Assignment Message (Communication Professeur ↔ Étudiant liée au Devoir) ───
export interface AssignmentMessage {
  id: string;
  assignmentId: string;
  submissionId?: string;
  studentId: string;
  teacherId: string;
  senderId: string;
  senderName: string;
  senderRole: 'teacher' | 'student';
  text?: string;
  voiceUrl?: string;
  voiceDuration?: number;
  fileUrl?: string;
  fileName?: string;
  createdAt: Timestamp;
}

// ─── Study Groups (Groupes de Travail de 5 personnes max) ────
export interface StudyGroup {
  id: string;
  name: string;
  description?: string;
  courseId: string;
  courseTitle: string;
  creatorId: string;
  creatorName: string;
  creatorPhoto?: string;
  admin1Id: string; // Administrateur 1 (Créateur ou principal)
  admin1Name: string;
  admin2Id?: string; // Administrateur 2 (Co-Administrateur / Relais)
  admin2Name?: string;
  members: string[]; // Max 5 participants
  memberNames: Record<string, string>;
  memberPhotos: Record<string, string>;
  maxMembers: number; // Configurable (ex: 2 a 5 membres)
  status: 'open' | 'full';
  joinMode?: 'open' | 'request'; // 'open' = direct libre, 'request' = sur approbation
  joinRequests?: Array<{
    uid: string;
    displayName: string;
    photoURL?: string;
    matricule?: string;
    academicLevel?: string;
    requestedAt: any;
  }>;
  liveActive?: boolean;
  liveRoomId?: string;
  liveStartedBy?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface GroupSharedTask {
  id: string;
  groupId: string;
  title: string;
  description: string;
  authorId: string;
  authorName: string;
  authorPhoto?: string;
  fileUrl?: string;
  fileName?: string;
  dueDate?: Timestamp;
  createdAt: Timestamp;
}

