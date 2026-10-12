import { Injectable, inject } from '@angular/core';
import { Functions, httpsCallable } from '@angular/fire/functions';
import {
  Firestore, collection, doc, addDoc, updateDoc, deleteDoc, getDoc,
  query, where, collectionData, serverTimestamp, Timestamp
} from '@angular/fire/firestore';
import { Room, RoomEvent, RemoteParticipant, LocalParticipant } from 'livekit-client';
import { Observable, BehaviorSubject, of } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { LiveSession } from '../models';
import { environment } from '../../../environments/environment';

export interface LiveParticipant {
  identity: string;
  name: string;
  isTeacher: boolean;
  isSpeaking: boolean;
  isMuted: boolean;
  isCameraOff: boolean;
}

@Injectable({ providedIn: 'root' })
export class LivekitService {
  private functions = inject(Functions);
  private firestore = inject(Firestore);

  private room: Room | null = null;
  private participantsSubject = new BehaviorSubject<LiveParticipant[]>([]);
  participants$ = this.participantsSubject.asObservable();

  private connectionStateSubject = new BehaviorSubject<string>('disconnected');
  connectionState$ = this.connectionStateSubject.asObservable();

  // ── Session management ───────────────────────────────────

  async createSession(
    courseId: string,
    title: string,
    scheduledAt: Date,
    teacherId?: string,
    teacherName?: string,
    courseName?: string,
    teacherPhotoURL?: string
  ): Promise<string> {
    try {
      const fn = httpsCallable<any, { session: LiveSession }>(this.functions, 'initLiveSession');
      const result = await fn({ courseId, title, scheduledAt: scheduledAt.toISOString() });
      if (result?.data?.session?.id) {
        return result.data.session.id;
      }
    } catch (e) {
      console.warn('Cloud function initLiveSession not reachable, creating session directly in Firestore:', e);
    }

    // Direct Firestore creation fallback
    const roomName = `club_live_${courseId}_${Date.now()}`;
    const docRef = await addDoc(collection(this.firestore, 'live_sessions'), {
      courseId: courseId || 'general',
      courseName: courseName || 'Formation Générale',
      title,
      teacherId: teacherId || '',
      teacherName: teacherName || 'Formateur',
      teacherPhotoURL: teacherPhotoURL || '',
      scheduledAt: Timestamp.fromDate(scheduledAt),
      status: 'scheduled',
      roomName,
      hasReplay: false,
      participantCount: 0,
      connectedParticipants: [],
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    return docRef.id;
  }

  async startSession(sessionId: string): Promise<void> {
    await updateDoc(doc(this.firestore, `live_sessions/${sessionId}`), {
      status: 'live',
      startedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  }

  async endSession(sessionId: string): Promise<void> {
    await this.endSessionWithReplay(sessionId);
  }

  async endSessionWithReplay(
    sessionId: string,
    replayUrl?: string,
    replayDuration?: string
  ): Promise<void> {
    const fallbackReplay = replayUrl || 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
    await updateDoc(doc(this.firestore, `live_sessions/${sessionId}`), {
      status: 'ended',
      hasReplay: true,
      replayUrl: fallbackReplay,
      replayDuration: replayDuration || '45 min',
      endedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    await this.disconnect();
  }

  async updateSessionData(sessionId: string, data: Partial<LiveSession>): Promise<void> {
    await updateDoc(doc(this.firestore, `live_sessions/${sessionId}`), {
      ...data,
      updatedAt: serverTimestamp()
    });
  }

  async deleteSession(sessionId: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `live_sessions/${sessionId}`));
  }

  /** Obtenir toutes les sessions en direct actives sur la plateforme */
  getActiveLiveSessions(): Observable<LiveSession[]> {
    const q = query(
      collection(this.firestore, 'live_sessions'),
      where('status', '==', 'live')
    );
    return (collectionData(q, { idField: 'id' }) as Observable<LiveSession[]>).pipe(
      catchError(err => {
        console.warn('Erreur lecture active lives:', err);
        return of([]);
      })
    );
  }

  /** Obtenir une session spécifique par son ID avec écoute temps réel */
  getLiveSessionById(sessionId: string): Observable<LiveSession | null> {
    return new Observable(observer => {
      import('@angular/fire/firestore').then(({ onSnapshot, doc: firestoreDoc }) => {
        const unsub = onSnapshot(firestoreDoc(this.firestore, `live_sessions/${sessionId}`), snap => {
          if (snap.exists()) {
            observer.next({ id: snap.id, ...snap.data() } as LiveSession);
          } else {
            observer.next(null);
          }
        }, err => {
          console.warn('Live session snapshot error:', err);
          observer.next(null);
        });
        return () => unsub();
      });
    });
  }

  /** Rejoindre un direct en tant qu'apprenant */
  async joinLiveSession(sessionId: string, user: { uid: string; displayName?: string }): Promise<void> {
    try {
      const { arrayUnion, increment } = await import('@angular/fire/firestore');
      await updateDoc(doc(this.firestore, `live_sessions/${sessionId}`), {
        connectedParticipants: arrayUnion(user.uid),
        participantCount: increment(1),
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Could not update connectedParticipants on join:', e);
    }
  }

  /** Quitter un direct */
  async leaveLiveSession(sessionId: string, userId: string): Promise<void> {
    try {
      const { arrayRemove, increment } = await import('@angular/fire/firestore');
      await updateDoc(doc(this.firestore, `live_sessions/${sessionId}`), {
        connectedParticipants: arrayRemove(userId),
        participantCount: increment(-1),
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Could not update connectedParticipants on leave:', e);
    }
  }

  /** Lever ou baisser la main en tant qu'étudiant */
  async toggleRaiseHand(sessionId: string, user: { uid: string; displayName?: string; photoURL?: string }): Promise<boolean> {
    try {
      const sessionDoc = doc(this.firestore, `live_sessions/${sessionId}`);
      const snap = await getDoc(sessionDoc);
      if (!snap.exists()) return false;
      const data = snap.data() as LiveSession;
      const hands = [...(data.raisedHands || [])];
      const index = hands.findIndex(h => h.uid === user.uid);
      let isRaisedNow = false;

      if (index >= 0) {
        hands.splice(index, 1);
        isRaisedNow = false;
      } else {
        hands.push({
          uid: user.uid,
          displayName: user.displayName || 'Étudiant',
          photoURL: user.photoURL || '',
          raisedAt: Date.now(),
        });
        isRaisedNow = true;
      }

      await updateDoc(sessionDoc, {
        raisedHands: hands,
        updatedAt: serverTimestamp(),
      });
      return isRaisedNow;
    } catch (e) {
      console.warn('Erreur toggleRaiseHand:', e);
      return false;
    }
  }

  /** Le professeur accorde la parole à un étudiant */
  async grantSpeakingPermission(sessionId: string, studentId: string): Promise<void> {
    try {
      const sessionDoc = doc(this.firestore, `live_sessions/${sessionId}`);
      const snap = await getDoc(sessionDoc);
      if (!snap.exists()) return;
      const data = snap.data() as LiveSession;

      const allowed = Array.from(new Set([...(data.allowedSpeakers || []), studentId]));
      const hands = (data.raisedHands || []).filter(h => h.uid !== studentId);

      await updateDoc(sessionDoc, {
        allowedSpeakers: allowed,
        raisedHands: hands,
        isMuteAll: false,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Erreur grantSpeakingPermission:', e);
    }
  }

  /** Le professeur coupe la parole à un étudiant */
  async revokeSpeakingPermission(sessionId: string, studentId: string): Promise<void> {
    try {
      const sessionDoc = doc(this.firestore, `live_sessions/${sessionId}`);
      const snap = await getDoc(sessionDoc);
      if (!snap.exists()) return;
      const data = snap.data() as LiveSession;

      const allowed = (data.allowedSpeakers || []).filter(id => id !== studentId);
      await updateDoc(sessionDoc, {
        allowedSpeakers: allowed,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Erreur revokeSpeakingPermission:', e);
    }
  }

  /** Le professeur coupe tous les micros des apprenants */
  async muteAllStudents(sessionId: string): Promise<void> {
    try {
      const sessionDoc = doc(this.firestore, `live_sessions/${sessionId}`);
      await updateDoc(sessionDoc, {
        allowedSpeakers: [],
        raisedHands: [],
        isMuteAll: true,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Erreur muteAllStudents:', e);
    }
  }

  /** Baisser la main d'un étudiant */
  async lowerHand(sessionId: string, studentId: string): Promise<void> {
    try {
      const sessionDoc = doc(this.firestore, `live_sessions/${sessionId}`);
      const snap = await getDoc(sessionDoc);
      if (!snap.exists()) return;
      const data = snap.data() as LiveSession;

      const hands = (data.raisedHands || []).filter(h => h.uid !== studentId);
      await updateDoc(sessionDoc, {
        raisedHands: hands,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      console.warn('Erreur lowerHand:', e);
    }
  }

  /** Obtenir les replays et enregistrements disponibles pour un cours spécifique */
  getCourseReplays(courseId: string): Observable<LiveSession[]> {
    const q = query(
      collection(this.firestore, 'live_sessions'),
      where('courseId', '==', courseId)
    );
    return (collectionData(q, { idField: 'id' }) as Observable<LiveSession[]>).pipe(
      map(list =>
        list
          .filter(s => s.hasReplay || s.replayUrl || s.recordingUrl || s.recordingBlobUrl || s.status === 'ended')
          .sort((a, b) => this.getMillis(b.endedAt || b.scheduledAt) - this.getMillis(a.endedAt || a.scheduledAt))
      ),
      catchError(() => of([]))
    );
  }

  /** Obtenir l'ensemble des séances Meet associées à ce cours (en direct, programmées ou enregistrées) */
  getCourseLiveSessions(courseId: string): Observable<LiveSession[]> {
    const q = query(
      collection(this.firestore, 'live_sessions'),
      where('courseId', '==', courseId)
    );
    return (collectionData(q, { idField: 'id' }) as Observable<LiveSession[]>).pipe(
      map(list => list.sort((a, b) => this.getMillis(b.scheduledAt) - this.getMillis(a.scheduledAt))),
      catchError(() => of([]))
    );
  }

  /** Obtenir tous les replays récents de la plateforme */
  getAllReplays(): Observable<LiveSession[]> {
    const q = query(
      collection(this.firestore, 'live_sessions'),
      where('status', '==', 'ended')
    );
    return (collectionData(q, { idField: 'id' }) as Observable<LiveSession[]>).pipe(
      map(list => list.filter(s => s.hasReplay || s.replayUrl || s.recordingUrl).sort((a, b) => this.getMillis(b.endedAt || b.scheduledAt) - this.getMillis(a.endedAt || a.scheduledAt))),
      catchError(() => of([]))
    );
  }

  getUpcomingSessions(courseId: string): Observable<LiveSession[]> {
    const q = query(
      collection(this.firestore, 'live_sessions'),
      where('courseId', '==', courseId)
    );
    return (collectionData(q, { idField: 'id' }) as Observable<LiveSession[]>).pipe(
      map(sessions => {
        return sessions
          .filter(s => s.status === 'scheduled' || s.status === 'live')
          .sort((a, b) => {
            const timeA = this.getMillis(a.scheduledAt);
            const timeB = this.getMillis(b.scheduledAt);
            return timeA - timeB;
          });
      }),
      catchError(err => {
        console.warn('Erreur lecture upcoming sessions:', err);
        return of([]);
      })
    );
  }

  getTeacherSessions(teacherId: string): Observable<LiveSession[]> {
    const q = query(
      collection(this.firestore, 'live_sessions'),
      where('teacherId', '==', teacherId)
    );
    return (collectionData(q, { idField: 'id' }) as Observable<LiveSession[]>).pipe(
      map(sessions => {
        return sessions.sort((a, b) => {
          const timeA = this.getMillis(a.scheduledAt);
          const timeB = this.getMillis(b.scheduledAt);
          return timeB - timeA;
        });
      }),
      catchError(err => {
        console.warn('Erreur lecture teacher sessions:', err);
        return of([]);
      })
    );
  }

  private getMillis(val: any): number {
    if (!val) return 0;
    if (typeof val.toMillis === 'function') return val.toMillis();
    if (typeof val.toDate === 'function') return val.toDate().getTime();
    if (val instanceof Date) return val.getTime();
    if (typeof val === 'number') return val;
    if (typeof val === 'string') return new Date(val).getTime();
    return 0;
  }

  // ── Room connection ──────────────────────────────────────

  async getToken(roomName: string, participantName: string, isTeacher: boolean): Promise<string> {
    try {
      const fn = httpsCallable<any, { token: string }>(this.functions, 'getLivekitToken');
      const result = await fn({ roomName, participantName, isTeacher });
      if (result?.data?.token) {
        return result.data.token;
      }
    } catch (e) {
      console.warn('Cloud function getLivekitToken not available:', e);
    }
    return 'mock_token_live_' + Date.now();
  }

  async connect(token: string): Promise<Room | null> {
    try {
      this.room = new Room({
        adaptiveStream: true,
        dynacast: true,
      });

      this.room.on(RoomEvent.ParticipantConnected, () => this.updateParticipants());
      this.room.on(RoomEvent.ParticipantDisconnected, () => this.updateParticipants());
      this.room.on(RoomEvent.ActiveSpeakersChanged, () => this.updateParticipants());
      this.room.on(RoomEvent.TrackMuted, () => this.updateParticipants());
      this.room.on(RoomEvent.TrackUnmuted, () => this.updateParticipants());
      this.room.on(RoomEvent.ConnectionStateChanged, state => {
        this.connectionStateSubject.next(state);
      });
      this.room.on(RoomEvent.Disconnected, () => {
        this.connectionStateSubject.next('disconnected');
        this.participantsSubject.next([]);
      });

      if (environment.livekit?.serverUrl && !token.startsWith('mock_')) {
        await this.room.connect(environment.livekit.serverUrl, token);
      }
      this.updateParticipants();
      return this.room;
    } catch (e) {
      console.warn('LiveKit Room connection failed:', e);
      return null;
    }
  }

  async disconnect(): Promise<void> {
    if (this.room) {
      try {
        await this.room.disconnect();
      } catch (e) {
        console.warn('Disconnect error:', e);
      }
      this.room = null;
    }
    this.connectionStateSubject.next('disconnected');
    this.participantsSubject.next([]);
  }

  async toggleMic(): Promise<void> {
    if (!this.room?.localParticipant) return;
    const enabled = this.room.localParticipant.isMicrophoneEnabled;
    await this.room.localParticipant.setMicrophoneEnabled(!enabled);
  }

  async toggleCamera(): Promise<void> {
    if (!this.room?.localParticipant) return;
    const enabled = this.room.localParticipant.isCameraEnabled;
    await this.room.localParticipant.setCameraEnabled(!enabled);
  }

  async shareScreen(): Promise<void> {
    if (!this.room?.localParticipant) return;
    await this.room.localParticipant.setScreenShareEnabled(true);
  }

  async stopScreenShare(): Promise<void> {
    if (!this.room?.localParticipant) return;
    await this.room.localParticipant.setScreenShareEnabled(false);
  }

  getLocalParticipant(): LocalParticipant | undefined {
    return this.room?.localParticipant;
  }

  getRemoteParticipants(): RemoteParticipant[] {
    return this.room ? Array.from(this.room.remoteParticipants.values()) : [];
  }

  private updateParticipants(): void {
    if (!this.room) return;
    const participants: LiveParticipant[] = [];

    const local = this.room.localParticipant;
    if (local) {
      participants.push({
        identity: local.identity,
        name: local.name ?? local.identity,
        isTeacher: local.metadata === 'teacher',
        isSpeaking: local.isSpeaking,
        isMuted: !local.isMicrophoneEnabled,
        isCameraOff: !local.isCameraEnabled,
      });
    }

    this.room.remoteParticipants.forEach(p => {
      participants.push({
        identity: p.identity,
        name: p.name ?? p.identity,
        isTeacher: p.metadata === 'teacher',
        isSpeaking: p.isSpeaking,
        isMuted: !p.isMicrophoneEnabled,
        isCameraOff: !p.isCameraEnabled,
      });
    });

    this.participantsSubject.next(participants);
  }
}
