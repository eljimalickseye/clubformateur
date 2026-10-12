import { Injectable, inject } from '@angular/core';
import { Messaging, getToken, onMessage } from '@angular/fire/messaging';
import {
  Firestore, collection, query, where, orderBy,
  collectionData, updateDoc, doc, writeBatch, limit,
} from '@angular/fire/firestore';
import { Observable, BehaviorSubject } from 'rxjs';
import { Notification } from '../models';
import { AuthService } from './auth.service';
import { environment } from '../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private messaging = inject(Messaging);
  private firestore = inject(Firestore);
  private authService = inject(AuthService);

  private unreadCountSubject = new BehaviorSubject<number>(0);
  unreadCount$ = this.unreadCountSubject.asObservable();

  /** Request FCM permission and get token */
  async requestPermission(): Promise<string | null> {
    try {
      const token = await getToken(this.messaging, {
        vapidKey: 'YOUR_VAPID_KEY',
      });
      if (token && this.authService.currentFirebaseUser) {
        await this.authService.updateFcmToken(this.authService.currentFirebaseUser.uid, token);
      }
      return token;
    } catch (err) {
      console.warn('Notification permission denied');
      return null;
    }
  }

  /** Listen to foreground messages */
  listenToMessages(): Observable<any> {
    return new Observable(observer => {
      onMessage(this.messaging, payload => observer.next(payload));
    });
  }

  /** Get user notifications */
  getNotifications(userId: string): Observable<Notification[]> {
    const q = query(
      collection(this.firestore, `notifications/${userId}/items`),
      orderBy('createdAt', 'desc'),
      limit(50)
    );
    return collectionData(q, { idField: 'id' }) as Observable<Notification[]>;
  }

  /** Mark a notification as read */
  async markAsRead(userId: string, notificationId: string): Promise<void> {
    await updateDoc(doc(this.firestore, `notifications/${userId}/items/${notificationId}`), {
      isRead: true,
    });
  }

  /** Mark all notifications as read */
  async markAllAsRead(userId: string): Promise<void> {
    const q = query(
      collection(this.firestore, `notifications/${userId}/items`),
      where('isRead', '==', false)
    );
    const snap = await import('@angular/fire/firestore').then(({ getDocs }) => getDocs(q));
    const batch = writeBatch(this.firestore);
    snap.docs.forEach(d => batch.update(d.ref, { isRead: true }));
    await batch.commit();
  }

  /** Déclencher une notification PWA Push locale si la permission est accordée */
  async sendLocalPushNotification(title: string, body: string, url: string, icon = '/assets/icons/icon-192x192.png'): Promise<void> {
    try {
      if ('Notification' in window && Notification.permission === 'granted') {
        const notif = new Notification(title, {
          body,
          icon,
          badge: icon,
          data: { url },
          tag: 'live-event-' + Date.now(),
        });
        notif.onclick = (e) => {
          e.preventDefault();
          window.focus();
          window.location.href = url;
        };
      }
    } catch (err) {
      console.warn('Could not show native notification:', err);
    }
  }

  /** Demander la permission de notifications PWA au navigateur */
  async requestBrowserNotificationPermission(): Promise<boolean> {
    try {
      if ('Notification' in window) {
        const permission = await Notification.requestPermission();
        return permission === 'granted';
      }
    } catch (e) {
      console.warn('Error requesting notification permission:', e);
    }
    return false;
  }

  /** Notifier automatiquement tous les étudiants inscrits à une formation lors d'un Live ou Replay */
  async notifyEnrolledStudentsForLive(
    courseId: string,
    courseName: string,
    teacherName: string,
    liveTitle: string,
    sessionId: string,
    isReplay = false
  ): Promise<number> {
    try {
      const { getDocs, addDoc, serverTimestamp } = await import('@angular/fire/firestore');
      
      let targetStudentIds: string[] = [];

      if (courseId && courseId !== 'general') {
        const qEnrollments = query(collection(this.firestore, 'enrollments'), where('courseId', '==', courseId));
        const snap = await getDocs(qEnrollments);
        snap.forEach(docSnap => {
          const data = docSnap.data();
          if (data['studentId']) targetStudentIds.push(data['studentId']);
        });
      }

      // Si formation générale ou aucun inscrit trouvé, récupérer tous les étudiants enregistrés
      if (targetStudentIds.length === 0) {
        const qUsers = query(collection(this.firestore, 'users'), where('role', '==', 'student'), limit(50));
        const snap = await getDocs(qUsers);
        snap.forEach(docSnap => {
          targetStudentIds.push(docSnap.id);
        });
      }

      // Dédoublonnage
      targetStudentIds = Array.from(new Set(targetStudentIds));

      const notifTitle = isReplay 
        ? `🎥 Le replay est disponible !`
        : `🔴 Votre professeur est en direct !`;

      const notifMessage = isReplay
        ? `Le cours « ${liveTitle} » de ${teacherName} (${courseName}) est maintenant disponible en replay.`
        : `${teacherName} vient de démarrer un cours en direct : « ${liveTitle} » (${courseName}). Rejoignez la session !`;

      const link = isReplay ? `/student/lives` : `/student/live/${sessionId}`;

      // 1. Sauvegarder dans Firestore pour chaque apprenant
      const promises = targetStudentIds.map(studentId => {
        return addDoc(collection(this.firestore, `notifications/${studentId}/items`), {
          userId: studentId,
          type: isReplay ? 'live_replay' : 'live_start',
          title: notifTitle,
          message: notifMessage,
          link,
          isRead: false,
          createdAt: serverTimestamp(),
        });
      });

      await Promise.allSettled(promises);

      // 2. Déclencher une notification PWA Push
      await this.sendLocalPushNotification(notifTitle, notifMessage, link);

      return targetStudentIds.length;
    } catch (e) {
      console.warn('Error notifying enrolled students:', e);
      return 0;
    }
  }

  /** Notifier les apprenants lors de la publication d'un nouveau devoir */
  async notifyEnrolledStudentsForAssignment(
    courseId: string,
    courseName: string,
    teacherName: string,
    assignmentTitle: string,
    assignmentId: string
  ): Promise<number> {
    try {
      const { getDocs, addDoc, serverTimestamp } = await import('@angular/fire/firestore');
      let targetStudentIds: string[] = [];

      if (courseId && courseId !== 'general') {
        const qEnrollments = query(collection(this.firestore, 'enrollments'), where('courseId', '==', courseId));
        const snap = await getDocs(qEnrollments);
        snap.forEach(docSnap => {
          const data = docSnap.data();
          if (data['studentId']) targetStudentIds.push(data['studentId']);
        });
      }

      if (targetStudentIds.length === 0) {
        const qUsers = query(collection(this.firestore, 'users'), where('role', '==', 'student'), limit(50));
        const snap = await getDocs(qUsers);
        snap.forEach(docSnap => {
          targetStudentIds.push(docSnap.id);
        });
      }

      targetStudentIds = Array.from(new Set(targetStudentIds));

      const notifTitle = `📝 Nouveau devoir : ${assignmentTitle}`;
      const notifMessage = `${teacherName} a publié une nouvelle évaluation dans ${courseName}. Consultez le sujet et les consignes.`;
      const link = `/student/assignments`;

      const promises = targetStudentIds.map(studentId => {
        return addDoc(collection(this.firestore, `notifications/${studentId}/items`), {
          userId: studentId,
          type: 'assignment_new',
          title: notifTitle,
          message: notifMessage,
          link,
          isRead: false,
          createdAt: serverTimestamp(),
        });
      });

      await Promise.allSettled(promises);
      await this.sendLocalPushNotification(notifTitle, notifMessage, link);
      return targetStudentIds.length;
    } catch (e) {
      console.warn('Error notifying assignment:', e);
      return 0;
    }
  }

  /** Notifier l'étudiant lorsque sa copie a été corrigée */
  async notifyStudentForGraded(
    studentId: string,
    assignmentTitle: string,
    score: number,
    maxScore: number
  ): Promise<void> {
    try {
      const { addDoc, serverTimestamp } = await import('@angular/fire/firestore');
      const notifTitle = `🎯 Copie corrigée : ${assignmentTitle}`;
      const notifMessage = `Votre note est disponible : ${score}/${maxScore}. Consultez les appréciations et remarques du professeur.`;
      const link = `/student/assignments`;

      await addDoc(collection(this.firestore, `notifications/${studentId}/items`), {
        userId: studentId,
        type: 'assignment_graded',
        title: notifTitle,
        message: notifMessage,
        link,
        isRead: false,
        createdAt: serverTimestamp(),
      });

      await this.sendLocalPushNotification(notifTitle, notifMessage, link);
    } catch (e) {
      console.warn('Error notifying student graded:', e);
    }
  }

  /** Notifier le professeur lors de la soumission d'une copie */
  async notifyTeacherForSubmission(
    teacherId: string,
    studentName: string,
    assignmentTitle: string
  ): Promise<void> {
    try {
      const { addDoc, serverTimestamp } = await import('@angular/fire/firestore');
      const notifTitle = `📥 Nouveau devoir reçu`;
      const notifMessage = `${studentName} a déposé sa copie pour le devoir « ${assignmentTitle} ». Prêt pour la correction.`;
      const link = `/teacher/assignments`;

      await addDoc(collection(this.firestore, `notifications/${teacherId}/items`), {
        userId: teacherId,
        type: 'assignment_submitted',
        title: notifTitle,
        message: notifMessage,
        link,
        isRead: false,
        createdAt: serverTimestamp(),
      });

      await this.sendLocalPushNotification(notifTitle, notifMessage, link);
    } catch (e) {
      console.warn('Error notifying teacher submission:', e);
    }
  }

  /** Notifier d'un nouveau message lié à un devoir */
  async notifyAssignmentMessage(
    recipientUserId: string,
    senderName: string,
    assignmentTitle: string,
    snippet: string
  ): Promise<void> {
    try {
      const { addDoc, serverTimestamp } = await import('@angular/fire/firestore');
      const notifTitle = `💬 Message sur « ${assignmentTitle} »`;
      const notifMessage = `${senderName} : ${snippet.slice(0, 80)}`;
      const link = `/student/assignments`;

      await addDoc(collection(this.firestore, `notifications/${recipientUserId}/items`), {
        userId: recipientUserId,
        type: 'assignment_message',
        title: notifTitle,
        message: notifMessage,
        link,
        isRead: false,
        createdAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Error notifying assignment message:', e);
    }
  }

  /** Update unread count */
  updateUnreadCount(count: number): void {
    this.unreadCountSubject.next(count);
  }
}
