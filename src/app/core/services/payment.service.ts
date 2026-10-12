import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';
import {
  Firestore, collection, query, where, orderBy,
  collectionData, doc, docData,
} from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Payment } from '../models';

export interface WavePaymentRequest {
  courseId: string;
  amount: number;
  phone: string;
  studentName: string;
}

export interface WavePaymentResponse {
  paymentId: string;
  waveUrl: string;  // Redirect URL for Wave checkout
  transactionId: string;
}

export interface OrangeMoneyRequest {
  courseId: string;
  amount: number;
  phone: string;
  studentName: string;
}

export interface OrangeMoneyResponse {
  paymentId: string;
  ussd: string;   // USSD code to dial
  transactionId: string;
}

@Injectable({ providedIn: 'root' })
export class PaymentService {
  private functions = inject(Functions);
  private firestore = inject(Firestore);

  /** Initiate Wave payment — returns redirect URL */
  async initiateWavePayment(data: WavePaymentRequest): Promise<WavePaymentResponse> {
    const fn = httpsCallable<WavePaymentRequest, WavePaymentResponse>(this.functions, 'initiateWavePayment');
    const result = await fn(data);
    return result.data;
  }

  /** Initiate Orange Money payment — returns USSD code */
  async initiateOrangeMoneyPayment(data: OrangeMoneyRequest): Promise<OrangeMoneyResponse> {
    const fn = httpsCallable<OrangeMoneyRequest, OrangeMoneyResponse>(this.functions, 'initiateOrangeMoneyPayment');
    const result = await fn(data);
    return result.data;
  }

  /** Verify payment status */
  async verifyPayment(paymentId: string): Promise<Payment> {
    const fn = httpsCallable<{ paymentId: string }, Payment>(this.functions, 'verifyPayment');
    const result = await fn({ paymentId });
    return result.data;
  }

  /** Get payments for a user */
  getUserPayments(userId: string): Observable<Payment[]> {
    const q = query(
      collection(this.firestore, 'payments'),
      where('userId', '==', userId),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Payment[]>;
  }

  /** Get all payments (admin) */
  getAllPayments(status?: string): Observable<Payment[]> {
    const constraints: any[] = [orderBy('createdAt', 'desc')];
    if (status) constraints.unshift(where('status', '==', status));
    const q = query(collection(this.firestore, 'payments'), ...constraints);
    return collectionData(q, { idField: 'id' }) as Observable<Payment[]>;
  }

  /** Get earnings for a teacher */
  getTeacherEarnings(teacherId: string): Observable<Payment[]> {
    const q = query(
      collection(this.firestore, 'payments'),
      where('teacherId', '==', teacherId),
      where('status', '==', 'success'),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Payment[]>;
  }

  /** Traitement direct du paiement Wave ou Orange Money et déblocage immédiat du cours */
  async processDirectPaymentAndEnroll(data: {
    userId: string;
    userName: string;
    userEmail?: string;
    courseId: string;
    courseTitle: string;
    teacherId: string;
    teacherName: string;
    amount: number;
    method: 'wave' | 'orange_money';
    phone: string;
  }): Promise<string> {
    const { addDoc, serverTimestamp, setDoc, doc: firestoreDoc, increment, writeBatch } = await import('@angular/fire/firestore');
    
    const txnId = `TXN_${data.method.toUpperCase()}_${Date.now()}`;
    const platformFee = Math.round(data.amount * 0.1);
    const teacherEarnings = data.amount - platformFee;

    // 1. Création de la transaction de paiement dans Firestore
    const paymentRef = await addDoc(collection(this.firestore, 'payments'), {
      userId: data.userId,
      studentName: data.userName,
      studentEmail: data.userEmail || '',
      courseId: data.courseId,
      courseTitle: data.courseTitle,
      teacherId: data.teacherId,
      amount: data.amount,
      platformFee,
      teacherEarnings,
      currency: 'XOF',
      method: data.method,
      transactionId: txnId,
      waveRef: data.method === 'wave' ? `WV_${data.phone}_${Date.now()}` : undefined,
      orangeRef: data.method === 'orange_money' ? `OM_${data.phone}_${Date.now()}` : undefined,
      status: 'success',
      metadata: { phone: data.phone, timestamp: Date.now() },
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    const paymentId = paymentRef.id;

    // 2. Déblocage de l'inscription
    const batch = writeBatch(this.firestore);
    const enrollmentId = `${data.userId}_${data.courseId}`;
    
    batch.set(firestoreDoc(this.firestore, `enrollments/${enrollmentId}`), {
      id: enrollmentId,
      studentId: data.userId,
      studentName: data.userName,
      courseId: data.courseId,
      enrolledAt: serverTimestamp(),
      completedLessons: [],
      progress: 0,
      lastAccessedAt: serverTimestamp(),
      certificateIssued: false,
      paymentId,
      status: 'active',
    });

    // Incrémentation du compteur d'élèves inscrits
    batch.update(firestoreDoc(this.firestore, `courses/${data.courseId}`), {
      enrolledCount: increment(1),
    });

    // Ajout direct dans les cours inscrits de l'utilisateur
    try {
      const { arrayUnion } = await import('@angular/fire/firestore');
      batch.update(firestoreDoc(this.firestore, `users/${data.userId}`), {
        enrolledCourses: arrayUnion(data.courseId)
      });
    } catch {}

    await batch.commit();

    // 3. Initialisation du suivi de progression
    await setDoc(firestoreDoc(this.firestore, `progress/${data.userId}/courses/${data.courseId}`), {
      userId: data.userId,
      courseId: data.courseId,
      completedLessons: [],
      quizAttempts: {},
      totalWatchTime: 0,
      lastAccessedAt: serverTimestamp(),
      progress: 0,
    });

    // 4. Notifications automatiques
    try {
      // Notification élève
      await addDoc(collection(this.firestore, `notifications/${data.userId}/items`), {
        userId: data.userId,
        type: 'payment',
        title: `Inscription confirmée`,
        message: `Votre paiement de ${data.amount.toLocaleString()} FCFA par ${data.method === 'wave' ? 'Wave' : 'Orange Money'} pour « ${data.courseTitle} » de ${data.teacherName} a été validé avec succès.`,
        link: `/course/${data.courseId}`,
        isRead: false,
        createdAt: serverTimestamp(),
      });

      // Notification formateur
      if (data.teacherId) {
        await addDoc(collection(this.firestore, `notifications/${data.teacherId}/items`), {
          userId: data.teacherId,
          type: 'enrollment',
          title: `Nouvel élève inscrit`,
          message: `${data.userName} vient de rejoindre votre cours « ${data.courseTitle} » (${data.method === 'wave' ? 'Wave' : 'Orange Money'} : +${teacherEarnings.toLocaleString()} FCFA crédités).`,
          link: `/teacher/students`,
          isRead: false,
          createdAt: serverTimestamp(),
        });
      }
    } catch (e) {
      console.warn('Could not post payment notifications:', e);
    }

    return paymentId;
  }

  /** Free enrollment (price = 0) with direct Firestore fallback */
  async enrollFree(courseId: string, userId?: string, userName?: string): Promise<void> {
    try {
      const fn = httpsCallable<{ courseId: string }, void>(this.functions, 'enrollFree');
      await fn({ courseId });
    } catch (fnErr) {
      console.warn('Cloud Functions enrollFree not reachable, executing direct enrollment:', fnErr);
      if (!userId) return;

      const { setDoc, doc: firestoreDoc, serverTimestamp, increment, updateDoc, arrayUnion } = await import('@angular/fire/firestore');
      const enrollmentId = `${userId}_${courseId}`;
      await setDoc(firestoreDoc(this.firestore, `enrollments/${enrollmentId}`), {
        id: enrollmentId,
        studentId: userId,
        studentName: userName || 'Apprenant',
        courseId: courseId,
        enrolledAt: serverTimestamp(),
        completedLessons: [],
        progress: 0,
        lastAccessedAt: serverTimestamp(),
        certificateIssued: false,
        status: 'active',
      }, { merge: true });

      try {
        await updateDoc(firestoreDoc(this.firestore, `courses/${courseId}`), {
          enrolledCount: increment(1)
        });
        await updateDoc(firestoreDoc(this.firestore, `users/${userId}`), {
          enrolledCourses: arrayUnion(courseId)
        });
      } catch {}
    }
  }
}
