import { Injectable, inject } from '@angular/core';
import {
  Firestore, doc, setDoc, getDoc, updateDoc, collection,
  query, where, collectionData, orderBy, serverTimestamp,
  writeBatch, increment,
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Enrollment, Progress } from '../models';

@Injectable({ providedIn: 'root' })
export class EnrollmentService {
  private firestore = inject(Firestore);

  /** Check if a student is enrolled in a course */
  async isEnrolled(studentId: string, courseId: string): Promise<boolean> {
    const snap = await getDoc(doc(this.firestore, `enrollments/${studentId}_${courseId}`));
    return snap.exists();
  }

  /** Enroll a student (called after successful payment) */
  async enroll(studentId: string, studentName: string, courseId: string, paymentId: string): Promise<void> {
    const batch = writeBatch(this.firestore);

    const enrollment: Enrollment = {
      id: `${studentId}_${courseId}`,
      studentId,
      studentName,
      courseId,
      enrolledAt: serverTimestamp() as any,
      completedLessons: [],
      progress: 0,
      lastAccessedAt: serverTimestamp() as any,
      certificateIssued: false,
      paymentId,
      status: 'active',
    };

    batch.set(doc(this.firestore, `enrollments/${studentId}_${courseId}`), enrollment);
    batch.update(doc(this.firestore, `courses/${courseId}`), { enrolledCount: increment(1) });
    batch.update(doc(this.firestore, `users/${studentId}`), {
      enrolledCourses: [...([] as string[]), courseId], // will be arrayUnion in real usage
    });
    await batch.commit();
  }

  /** Get all enrollments for a student */
  getStudentEnrollments(studentId: string): Observable<Enrollment[]> {
    const q = query(
      collection(this.firestore, 'enrollments'),
      where('studentId', '==', studentId),
      orderBy('enrolledAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Enrollment[]>;
  }

  /** Get all enrollments for a course (teacher view) */
  getCourseEnrollments(courseId: string): Observable<Enrollment[]> {
    const q = query(
      collection(this.firestore, 'enrollments'),
      where('courseId', '==', courseId),
      orderBy('enrolledAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Enrollment[]>;
  }

  /** Mark a lesson as completed and update progress */
  async completeLesson(studentId: string, courseId: string, lessonId: string, totalLessons: number): Promise<void> {
    const enrollRef = doc(this.firestore, `enrollments/${studentId}_${courseId}`);
    const snap = await getDoc(enrollRef);
    if (!snap.exists()) return;

    const enrollment = snap.data() as Enrollment;
    if (enrollment.completedLessons.includes(lessonId)) return;

    const updatedLessons = [...enrollment.completedLessons, lessonId];
    const progress = Math.round((updatedLessons.length / totalLessons) * 100);

    await updateDoc(enrollRef, {
      completedLessons: updatedLessons,
      progress,
      lastLessonId: lessonId,
      lastAccessedAt: serverTimestamp(),
    });

    // Update progress subcollection
    await updateDoc(doc(this.firestore, `progress/${studentId}/courses/${courseId}`), {
      completedLessons: updatedLessons,
      progress,
      lastAccessedAt: serverTimestamp(),
    });

    // If 100% — Cloud Function will generate certificate automatically
  }

  /** Get detailed progress for a student/course */
  getProgress(studentId: string, courseId: string): Observable<Progress | undefined> {
    return new Observable(observer => {
      getDoc(doc(this.firestore, `progress/${studentId}/courses/${courseId}`)).then(snap => {
        observer.next(snap.exists() ? (snap.data() as Progress) : undefined);
        observer.complete();
      });
    });
  }

  /** Initialize progress tracking when student first enrolls */
  async initProgress(studentId: string, courseId: string): Promise<void> {
    await setDoc(doc(this.firestore, `progress/${studentId}/courses/${courseId}`), {
      userId: studentId,
      courseId,
      completedLessons: [],
      quizAttempts: {},
      totalWatchTime: 0,
      lastAccessedAt: serverTimestamp(),
      progress: 0,
    });
  }
}
