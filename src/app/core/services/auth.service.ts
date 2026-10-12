import { Injectable, inject } from '@angular/core';
import {
  Auth, authState, signInWithEmailAndPassword,
  createUserWithEmailAndPassword, signInWithPopup,
  GoogleAuthProvider, sendPasswordResetEmail,
  updateProfile, signOut, User as FirebaseUser,
} from '@angular/fire/auth';
import {
  Firestore, doc, setDoc, getDoc, updateDoc, serverTimestamp,
} from '@angular/fire/firestore';
import { Observable, from, switchMap, of } from 'rxjs';
import { User, UserRole } from '../models';

export interface RegisterData {
  email: string;
  password: string;
  displayName: string;
  role: UserRole;
  phone?: string;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private auth = inject(Auth);
  private firestore = inject(Firestore);

  /** Stream of the current Firestore user profile (null if unauthenticated) */
  readonly currentUser$: Observable<User | null> = authState(this.auth).pipe(
    switchMap(firebaseUser =>
      firebaseUser ? this.getUserProfile(firebaseUser.uid) : of(null)
    )
  );

  /** Register with email/password and create Firestore profile */
  async register(data: RegisterData): Promise<User> {
    const cred = await createUserWithEmailAndPassword(this.auth, data.email, data.password);
    await updateProfile(cred.user, { displayName: data.displayName });

    const user: User = {
      uid: cred.user.uid,
      email: data.email,
      displayName: data.displayName,
      photoURL: cred.user.photoURL ?? `https://ui-avatars.com/api/?name=${encodeURIComponent(data.displayName)}&background=C9A84C&color=0D0D0D`,
      role: data.role,
      phone: data.phone,
      enrolledCourses: [],
      isVerified: false,
      isActive: true,
      createdAt: serverTimestamp() as any,
      updatedAt: serverTimestamp() as any,
    };

    await setDoc(doc(this.firestore, `users/${cred.user.uid}`), user);
    return user;
  }

  /** Login with email/password */
  login(email: string, password: string) {
    return from(signInWithEmailAndPassword(this.auth, email, password));
  }

  /** Login with Google — creates profile if first time */
  async loginWithGoogle(role: UserRole = 'student'): Promise<User> {
    const provider = new GoogleAuthProvider();
    const cred = await signInWithPopup(this.auth, provider);
    const userRef = doc(this.firestore, `users/${cred.user.uid}`);
    const snap = await getDoc(userRef);

    if (!snap.exists()) {
      const user: User = {
        uid: cred.user.uid,
        email: cred.user.email!,
        displayName: cred.user.displayName!,
        photoURL: cred.user.photoURL ?? '',
        role,
        enrolledCourses: [],
        isVerified: true,
        isActive: true,
        createdAt: serverTimestamp() as any,
        updatedAt: serverTimestamp() as any,
      };
      await setDoc(userRef, user);
      return user;
    }
    return snap.data() as User;
  }

  /** Send password reset email */
  resetPassword(email: string) {
    return from(sendPasswordResetEmail(this.auth, email));
  }

  /** Sign out */
  logout() {
    return from(signOut(this.auth));
  }

  /** Update user FCM token for push notifications */
  async updateFcmToken(uid: string, token: string): Promise<void> {
    await updateDoc(doc(this.firestore, `users/${uid}`), { fcmToken: token, updatedAt: serverTimestamp() });
  }

  /** Update profile fields */
  async updateProfile(uid: string, data: Partial<User>): Promise<void> {
    await updateDoc(doc(this.firestore, `users/${uid}`), { ...data, updatedAt: serverTimestamp() });
    if (data.displayName || data.photoURL) {
      await updateProfile(this.auth.currentUser!, {
        displayName: data.displayName,
        photoURL: data.photoURL,
      });
    }
  }

  get currentFirebaseUser(): FirebaseUser | null {
    return this.auth.currentUser;
  }

  getUserById(uid: string): Observable<User | null> {
    return new Observable(observer => {
      getDoc(doc(this.firestore, `users/${uid}`)).then(snap => {
        observer.next(snap.exists() ? (snap.data() as User) : null);
        observer.complete();
      }).catch(err => observer.error(err));
    });
  }

  private getUserProfile(uid: string): Observable<User | null> {
    return new Observable(observer => {
      getDoc(doc(this.firestore, `users/${uid}`)).then(snap => {
        observer.next(snap.exists() ? (snap.data() as User) : null);
        observer.complete();
      }).catch(err => observer.error(err));
    });
  }
}
