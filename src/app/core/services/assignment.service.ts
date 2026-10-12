import { Injectable, inject } from '@angular/core';
import {
  Firestore, collection, collectionData, doc, docData,
  addDoc, updateDoc, deleteDoc, query, where, orderBy,
  serverTimestamp, increment, getDoc,
} from '@angular/fire/firestore';
import { Storage, ref, uploadBytes, uploadBytesResumable, getDownloadURL } from '@angular/fire/storage';
import { Observable } from 'rxjs';
import { Assignment, AssignmentSubmission } from '../models';

export interface UploadProgress {
  progress: number;
  downloadURL?: string;
  error?: string;
}

@Injectable({ providedIn: 'root' })
export class AssignmentService {
  private firestore = inject(Firestore);
  private storage = inject(Storage);

  // ─── Assignments (Devoirs / Exercices) ─────────────────────────

  getTeacherAssignments(teacherId: string): Observable<Assignment[]> {
    const q = query(
      collection(this.firestore, 'assignments'),
      where('teacherId', '==', teacherId)
    );
    return collectionData(q, { idField: 'id' }) as Observable<Assignment[]>;
  }

  getCourseAssignments(courseId: string): Observable<Assignment[]> {
    const q = query(
      collection(this.firestore, 'assignments'),
      where('courseId', '==', courseId)
    );
    return collectionData(q, { idField: 'id' }) as Observable<Assignment[]>;
  }

  getAssignmentById(id: string): Observable<Assignment | undefined> {
    return docData(doc(this.firestore, `assignments/${id}`), { idField: 'id' }) as Observable<Assignment | undefined>;
  }

  async createAssignment(data: Partial<Assignment>): Promise<string> {
    const ref = await addDoc(collection(this.firestore, 'assignments'), {
      ...data,
      submissionCount: 0,
      gradedCount: 0,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    return ref.id;
  }

  async updateAssignment(id: string, data: Partial<Assignment>): Promise<void> {
    await updateDoc(doc(this.firestore, `assignments/${id}`), {
      ...data,
      updatedAt: serverTimestamp(),
    });
  }

  async deleteAssignment(id: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `assignments/${id}`));
  }

  // ─── Submissions (Rendus d'étudiants) ──────────────────────────

  getAssignmentSubmissions(assignmentId: string): Observable<AssignmentSubmission[]> {
    const q = query(
      collection(this.firestore, 'submissions'),
      where('assignmentId', '==', assignmentId)
    );
    return collectionData(q, { idField: 'id' }) as Observable<AssignmentSubmission[]>;
  }

  getTeacherAllSubmissions(courseIds: string[]): Observable<AssignmentSubmission[]> {
    if (!courseIds || courseIds.length === 0) {
      const q = query(collection(this.firestore, 'submissions'));
      return collectionData(q, { idField: 'id' }) as Observable<AssignmentSubmission[]>;
    }
    const limitedIds = courseIds.slice(0, 10);
    const q = query(
      collection(this.firestore, 'submissions'),
      where('courseId', 'in', limitedIds)
    );
    return collectionData(q, { idField: 'id' }) as Observable<AssignmentSubmission[]>;
  }

  getStudentSubmissions(studentId: string): Observable<AssignmentSubmission[]> {
    const q = query(
      collection(this.firestore, 'submissions'),
      where('studentId', '==', studentId)
    );
    return collectionData(q, { idField: 'id' }) as Observable<AssignmentSubmission[]>;
  }

  async submitAssignment(data: Partial<AssignmentSubmission>): Promise<string> {
    const ref = await addDoc(collection(this.firestore, 'submissions'), {
      ...data,
      status: 'submitted',
      submittedAt: serverTimestamp(),
    });

    if (data.assignmentId) {
      await updateDoc(doc(this.firestore, `assignments/${data.assignmentId}`), {
        submissionCount: increment(1),
        updatedAt: serverTimestamp(),
      });
    }

    return ref.id;
  }

  async updateSubmission(id: string, data: Partial<AssignmentSubmission>): Promise<void> {
    await updateDoc(doc(this.firestore, `submissions/${id}`), {
      ...data,
      submittedAt: serverTimestamp(),
    });
  }

  async gradeSubmission(
    submissionId: string,
    assignmentId: string,
    gradeData: {
      score: number;
      maxScore?: number;
      generalAppreciation?: string;
      feedbackText?: string;
      feedbackVoiceUrl?: string;
      feedbackVoiceDuration?: number;
      correctedDocumentUrl?: string;
      correctedDocumentName?: string;
      questionAnswers?: any[];
      allowResubmit?: boolean;
      gradedBy?: string;
    }
  ): Promise<void> {
    await updateDoc(doc(this.firestore, `submissions/${submissionId}`), {
      ...gradeData,
      status: 'graded',
      gradedAt: serverTimestamp(),
    });

    if (assignmentId) {
      await updateDoc(doc(this.firestore, `assignments/${assignmentId}`), {
        gradedCount: increment(1),
        updatedAt: serverTimestamp(),
      });
    }
  }

  async requestResubmission(
    submissionId: string,
    reason: string,
    gradedBy?: string
  ): Promise<void> {
    await updateDoc(doc(this.firestore, `submissions/${submissionId}`), {
      status: 'resubmit_requested',
      allowResubmit: true,
      feedbackText: reason,
      gradedBy: gradedBy || 'Professeur',
      gradedAt: serverTimestamp(),
    });
  }

  // ─── Communication Professeur ↔ Étudiant liée au Devoir ────────

  getAssignmentMessages(assignmentId: string, studentId?: string): Observable<any[]> {
    let q;
    if (studentId) {
      q = query(
        collection(this.firestore, 'assignment_messages'),
        where('assignmentId', '==', assignmentId),
        where('studentId', '==', studentId),
        orderBy('createdAt', 'asc')
      );
    } else {
      q = query(
        collection(this.firestore, 'assignment_messages'),
        where('assignmentId', '==', assignmentId),
        orderBy('createdAt', 'asc')
      );
    }
    return collectionData(q, { idField: 'id' });
  }

  async sendAssignmentMessage(data: any): Promise<string> {
    const ref = await addDoc(collection(this.firestore, 'assignment_messages'), {
      ...data,
      createdAt: serverTimestamp(),
    });
    return ref.id;
  }

  async uploadAssignmentVoiceMessage(assignmentId: string, audioBlob: Blob): Promise<string> {
    const filename = `voice_msg_${Date.now()}.webm`;
    const path = `assignments/${assignmentId}/chat_voices/${filename}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, audioBlob, { contentType: 'audio/webm' });
    return await getDownloadURL(storageRef);
  }

  // ─── Storage & Document Uploads ───────────────────────────────

  async uploadVoiceFeedback(assignmentId: string, submissionId: string, audioBlob: Blob): Promise<string> {
    const filename = `voice_feedback_${Date.now()}.webm`;
    const path = `assignments/${assignmentId}/voice_notes/${submissionId}_${filename}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, audioBlob, { contentType: 'audio/webm' });
    return await getDownloadURL(storageRef);
  }

  async uploadAssignmentDocument(courseId: string, file: File): Promise<{ url: string; name: string; size: number }> {
    const path = `assignments/${courseId}/docs/${Date.now()}_${file.name}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    const url = await getDownloadURL(storageRef);
    return { url, name: file.name, size: file.size };
  }

  async uploadStudentResponseDocument(assignmentId: string, studentId: string, file: File): Promise<{ url: string; name: string; size: number }> {
    const path = `assignments/${assignmentId}/submissions/${studentId}_${Date.now()}_${file.name}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    const url = await getDownloadURL(storageRef);
    return { url, name: file.name, size: file.size };
  }

  async uploadCorrectedDocument(assignmentId: string, submissionId: string, file: File): Promise<{ url: string; name: string }> {
    const path = `assignments/${assignmentId}/corrected/${submissionId}_${Date.now()}_${file.name}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    const url = await getDownloadURL(storageRef);
    return { url, name: file.name };
  }
}
