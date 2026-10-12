import { Injectable, inject } from '@angular/core';
import {
  Firestore, collection, doc, query, where, orderBy,
  collectionData, updateDoc, deleteDoc, getDocs, setDoc,
  serverTimestamp, docData,
} from '@angular/fire/firestore';
import { Observable, from, map } from 'rxjs';
import { User, Course, Payment, UserRole, CoursePublicationStatus } from '../models';
import { initializeApp as initSecondaryApp, deleteApp as deleteSecondaryApp } from 'firebase/app';
import { getAuth as getSecondaryAuth, createUserWithEmailAndPassword as createSecondaryUser, updateProfile as updateSecondaryProfile } from 'firebase/auth';
import { environment } from '../../../environments/environment';

export interface PlatformKPIs {
  totalStudents: number;
  totalTeachers: number;
  totalCourses: number;
  publishedCourses: number;
  pendingCourses: number;
  totalVolume: number;
  platformCommissions: number;
  totalTransactions: number;
}

@Injectable({
  providedIn: 'root',
})
export class AdminService {
  private firestore = inject(Firestore);

  /** Get all platform users with role filter */
  getUsers(role?: string): Observable<User[]> {
    const usersRef = collection(this.firestore, 'users');
    const q = role && role !== 'all'
      ? query(usersRef, where('role', '==', role), orderBy('createdAt', 'desc'))
      : query(usersRef, orderBy('createdAt', 'desc'));

    return collectionData(q, { idField: 'uid' }) as Observable<User[]>;
  }

  /** Update user role (e.g. promote to teacher or admin) */
  async updateUserRole(uid: string, role: UserRole): Promise<void> {
    const userRef = doc(this.firestore, `users/${uid}`);
    await updateDoc(userRef, { role, updatedAt: serverTimestamp() });
  }

  /** Toggle account active status (suspend/activate) */
  async toggleUserStatus(uid: string, isActive: boolean): Promise<void> {
    const userRef = doc(this.firestore, `users/${uid}`);
    await updateDoc(userRef, { isActive, updatedAt: serverTimestamp() });
  }

  /** Delete a user account */
  async deleteUser(uid: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `users/${uid}`));
  }

  /** Create a new teacher account by Super Admin, generate WhatsApp link & credentials */
  async createTeacherAccount(data: {
    displayName: string;
    email: string;
    phone: string;
    speciality: string;
    tempPassword?: string;
  }): Promise<{ user: User; tempPassword: string; whatsappMessage: string; whatsappUrl: string }> {
    const tempPassword = data.tempPassword || this.generateSecurePassword();
    const appName = `SecondaryAdminTeacherApp_${Date.now()}`;
    const secondaryApp = initSecondaryApp(environment.firebase, appName);
    const secondaryAuth = getSecondaryAuth(secondaryApp);

    try {
      const cred = await createSecondaryUser(secondaryAuth, data.email, tempPassword);
      await updateSecondaryProfile(cred.user, { displayName: data.displayName });
      const uid = cred.user.uid;

      const user: User = {
        uid,
        email: data.email,
        displayName: data.displayName,
        phone: data.phone,
        speciality: data.speciality,
        role: 'teacher',
        isActive: true,
        isVerified: true,
        enrolledCourses: [],
        photoURL: `https://ui-avatars.com/api/?name=${encodeURIComponent(data.displayName)}&background=2D5BE3&color=fff`,
        createdAt: serverTimestamp() as any,
        updatedAt: serverTimestamp() as any,
      };

      await setDoc(doc(this.firestore, `users/${uid}`), user);

      const loginUrl = `https://club-des-formateurs.web.app/auth/login?role=teacher&email=${encodeURIComponent(data.email)}`;
      const cleanPhone = (data.phone || '').replace(/[^0-9]/g, '');

      const whatsappMessage = 
`Bonjour Professeur ${data.displayName} ! 🎓

Votre compte Formateur a été créé avec succès sur le Club des Formateurs.

Voici vos identifiants d'accès confidentiels :
📧 Email : ${data.email}
🔑 Mot de passe : ${tempPassword}
📚 Matière / Spécialité : ${data.speciality}

🔗 Lien direct de connexion :
${loginUrl}

Connectez-vous pour commencer à publier vos cours et planifier vos sessions directes.
Bienvenue dans le corps professoral !`;

      const whatsappUrl = `https://api.whatsapp.com/send?phone=${cleanPhone}&text=${encodeURIComponent(whatsappMessage)}`;

      return { user, tempPassword, whatsappMessage, whatsappUrl };
    } finally {
      await deleteSecondaryApp(secondaryApp);
    }
  }

  generateSecurePassword(length: number = 10): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$';
    let result = 'Prof!';
    for (let i = 0; i < length - 5; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result + Math.floor(10 + Math.random() * 89);
  }

  /** Get all courses for administration / moderation */
  getAllCourses(status?: string): Observable<Course[]> {
    const coursesRef = collection(this.firestore, 'courses');
    const q = status && status !== 'all'
      ? query(coursesRef, where('publicationStatus', '==', status), orderBy('createdAt', 'desc'))
      : query(coursesRef, orderBy('createdAt', 'desc'));

    return collectionData(q, { idField: 'id' }) as Observable<Course[]>;
  }

  /** Approve a course submitted by teacher (makes it public in catalog) */
  async approveCourse(courseId: string, teacherId?: string, courseTitle?: string): Promise<void> {
    const courseRef = doc(this.firestore, `courses/${courseId}`);
    await updateDoc(courseRef, {
      isPublished: true,
      publicationStatus: 'published' as CoursePublicationStatus,
      adminFeedback: null,
      updatedAt: serverTimestamp(),
    });

    if (teacherId) {
      await this.notifyTeacher(teacherId, {
        type: 'course_approved',
        title: 'Cours validé et publié ! 🎉',
        body: `Votre cours "${courseTitle || 'Formation'}" a été validé par l'administration et est désormais visible dans le catalogue public.`,
        data: { courseId },
      });
    }
  }

  /** Reject a course with feedback */
  async rejectCourse(courseId: string, reason: string, teacherId?: string, courseTitle?: string): Promise<void> {
    const courseRef = doc(this.firestore, `courses/${courseId}`);
    await updateDoc(courseRef, {
      isPublished: false,
      publicationStatus: 'rejected' as CoursePublicationStatus,
      adminFeedback: reason,
      updatedAt: serverTimestamp(),
    });

    if (teacherId) {
      await this.notifyTeacher(teacherId, {
        type: 'course_rejected',
        title: 'Retour sur votre cours soumis',
        body: `Votre cours "${courseTitle || 'Formation'}" nécessite des ajustements : "${reason}".`,
        data: { courseId },
      });
    }
  }

  /** Archive a course */
  async archiveCourse(courseId: string): Promise<void> {
    const courseRef = doc(this.firestore, `courses/${courseId}`);
    await updateDoc(courseRef, {
      isPublished: false,
      publicationStatus: 'archived' as CoursePublicationStatus,
      updatedAt: serverTimestamp(),
    });
  }

  /** Update course status directly */
  async updateCourseStatus(courseId: string, publicationStatus: CoursePublicationStatus, isPublished: boolean): Promise<void> {
    const courseRef = doc(this.firestore, `courses/${courseId}`);
    await updateDoc(courseRef, {
      isPublished,
      publicationStatus,
      updatedAt: serverTimestamp(),
    });
  }

  /** Delete a course */
  async deleteCourse(courseId: string): Promise<void> {
    const courseRef = doc(this.firestore, `courses/${courseId}`);
    await deleteDoc(courseRef);
  }

  /** Get all platform instructors */
  getAllTeachers(): Observable<User[]> {
    const q = query(
      collection(this.firestore, 'users'),
      where('role', '==', 'teacher'),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'uid' }) as Observable<User[]>;
  }

  /** Fetch global KPIs */
  async getGlobalKPIs(): Promise<PlatformKPIs> {
    try {
      const [usersSnap, coursesSnap, paymentsSnap] = await Promise.all([
        getDocs(collection(this.firestore, 'users')),
        getDocs(collection(this.firestore, 'courses')),
        getDocs(collection(this.firestore, 'payments')),
      ]);

      const users = usersSnap.docs.map(d => d.data() as User);
      const courses = coursesSnap.docs.map(d => d.data() as Course);
      const payments = paymentsSnap.docs.map(d => d.data() as Payment);

      const totalStudents = users.filter(u => u.role === 'student').length;
      const totalTeachers = users.filter(u => u.role === 'teacher').length;
      const publishedCourses = courses.filter(c => c.isPublished || c.publicationStatus === 'published').length;
      const pendingCourses = courses.filter(c => c.publicationStatus === 'pending_approval').length;

      const successfulPayments = payments.filter(p => p.status === 'success');
      const totalVolume = successfulPayments.reduce((sum, p) => sum + (p.amount || 0), 0);
      const platformCommissions = successfulPayments.reduce((sum, p) => sum + (p.platformFee || 0), 0);

      return {
        totalStudents,
        totalTeachers,
        totalCourses: courses.length,
        publishedCourses,
        pendingCourses,
        totalVolume,
        platformCommissions,
        totalTransactions: payments.length,
      };
    } catch (e) {
      console.error('Failed to load global KPIs', e);
      return {
        totalStudents: 0,
        totalTeachers: 0,
        totalCourses: 0,
        publishedCourses: 0,
        pendingCourses: 0,
        totalVolume: 0,
        platformCommissions: 0,
        totalTransactions: 0,
      };
    }
  }

  private async notifyTeacher(teacherId: string, notif: { type: string; title: string; body: string; data?: Record<string, string> }): Promise<void> {
    try {
      const notifRef = collection(this.firestore, `notifications/${teacherId}/items`);
      await (await import('@angular/fire/firestore')).addDoc(notifRef, {
        ...notif,
        isRead: false,
        createdAt: (await import('@angular/fire/firestore')).serverTimestamp(),
      });
    } catch (e) {
      console.warn('Notification error', e);
    }
  }
}
