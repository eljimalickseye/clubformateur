import { Injectable, inject } from '@angular/core';
import {
  Firestore, collection, doc, query, where, orderBy,
  collectionData, addDoc, updateDoc, getDocs, serverTimestamp,
  docData, getDoc,
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { EnrollmentRequest, EnrollmentRequestStatus } from '../models';
import { EnrollmentService } from './enrollment.service';

@Injectable({
  providedIn: 'root',
})
export class RequestService {
  private firestore = inject(Firestore);
  private enrollmentService = inject(EnrollmentService);

  /** Create a new course enrollment request by a student */
  async createRequest(data: {
    studentId: string;
    studentName: string;
    studentEmail: string;
    studentPhotoURL?: string;
    courseId: string;
    courseTitle: string;
    teacherId: string;
    teacherName?: string;
    message?: string;
  }): Promise<string> {
    const requestsRef = collection(this.firestore, 'enrollment_requests');
    const docRef = await addDoc(requestsRef, {
      ...data,
      status: 'pending' as EnrollmentRequestStatus,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    // Also send in-app notification to teacher
    await this.notifyUser(data.teacherId, {
      type: 'enrollment_request',
      title: 'Nouvelle demande d\'inscription',
      body: `${data.studentName} souhaite rejoindre votre cours "${data.courseTitle}".`,
      data: { courseId: data.courseId, requestId: docRef.id },
    });

    return docRef.id;
  }

  /** Check if student already has a pending or accepted request for this course */
  async checkExistingRequest(studentId: string, courseId: string): Promise<EnrollmentRequest | null> {
    const q = query(
      collection(this.firestore, 'enrollment_requests'),
      where('studentId', '==', studentId),
      where('courseId', '==', courseId)
    );
    const snap = await getDocs(q);
    if (!snap.empty) {
      const list = snap.docs.map(d => ({ ...d.data() as EnrollmentRequest, id: d.id }));
      list.sort((a, b) => {
        const tA = (a.createdAt as any)?.toMillis ? (a.createdAt as any).toMillis() : (a.createdAt ? new Date(a.createdAt as any).getTime() : 0);
        const tB = (b.createdAt as any)?.toMillis ? (b.createdAt as any).toMillis() : (b.createdAt ? new Date(b.createdAt as any).getTime() : 0);
        return tB - tA;
      });
      return list[0];
    }
    return null;
  }

  /** Get all requests for a teacher (ordered by newest first) */
  getTeacherRequests(teacherId: string): Observable<EnrollmentRequest[]> {
    const q = query(
      collection(this.firestore, 'enrollment_requests'),
      where('teacherId', '==', teacherId),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<EnrollmentRequest[]>;
  }

  /** Get all requests made by a student */
  getStudentRequests(studentId: string): Observable<EnrollmentRequest[]> {
    const q = query(
      collection(this.firestore, 'enrollment_requests'),
      where('studentId', '==', studentId),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<EnrollmentRequest[]>;
  }

  /** Get all requests (admin view) */
  getAllRequests(): Observable<EnrollmentRequest[]> {
    const q = query(
      collection(this.firestore, 'enrollment_requests'),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<EnrollmentRequest[]>;
  }

  /** Accept a request: enrolls student and notifies them */
  async acceptRequest(request: EnrollmentRequest): Promise<void> {
    const reqRef = doc(this.firestore, `enrollment_requests/${request.id}`);
    await updateDoc(reqRef, {
      status: 'accepted' as EnrollmentRequestStatus,
      reviewedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    // Enroll the student in course
    await this.enrollmentService.enroll(
      request.studentId,
      request.studentName,
      request.courseId,
      'REQUEST_' + request.id
    );

    // Notify the student
    await this.notifyUser(request.studentId, {
      type: 'request_accepted',
      title: 'Demande acceptée ! 🎉',
      body: `Félicitations, votre demande pour le cours "${request.courseTitle}" a été acceptée par le professeur.`,
      data: { courseId: request.courseId },
    });
  }

  /** Reject a request */
  async rejectRequest(request: EnrollmentRequest, reason?: string): Promise<void> {
    const reqRef = doc(this.firestore, `enrollment_requests/${request.id}`);
    await updateDoc(reqRef, {
      status: 'rejected' as EnrollmentRequestStatus,
      reviewedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      rejectionReason: reason || null,
    });

    // Notify student
    await this.notifyUser(request.studentId, {
      type: 'request_rejected',
      title: 'Mise à jour de votre demande',
      body: `Votre demande pour le cours "${request.courseTitle}" n'a pas pu être retenue pour le moment.`,
      data: { courseId: request.courseId },
    });
  }

  private async notifyUser(userId: string, notif: { type: string; title: string; body: string; data?: Record<string, string> }): Promise<void> {
    try {
      const notifRef = collection(this.firestore, `notifications/${userId}/items`);
      await addDoc(notifRef, {
        ...notif,
        isRead: false,
        createdAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Failed to deliver in-app notification', e);
    }
  }
}
