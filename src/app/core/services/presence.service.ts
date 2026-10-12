import { Injectable, inject } from '@angular/core';
import { Firestore, doc, docData, updateDoc, serverTimestamp, Timestamp } from '@angular/fire/firestore';
import { Observable, of, interval, Subscription } from 'rxjs';
import { map } from 'rxjs/operators';
import { User } from '../models';

export interface UserPresence {
  isOnline: boolean;
  lastSeen?: Date | null;
  statusText: string;
}

@Injectable({
  providedIn: 'root'
})
export class PresenceService {
  private firestore = inject(Firestore);
  private currentUserId: string | null = null;
  private heartbeatSub?: Subscription;
  private listenersBound = false;

  /**
   * Initialise le suivi de présence pour l'utilisateur connecté
   */
  initPresence(user: User | null): void {
    if (!user) {
      if (this.currentUserId) {
        this.setOffline(this.currentUserId);
      }
      this.currentUserId = null;
      if (this.heartbeatSub) {
        this.heartbeatSub.unsubscribe();
      }
      return;
    }

    this.currentUserId = user.uid;
    this.setOnline(user.uid);

    // Heartbeat toutes les 60 secondes pour rafraîchir lastSeen
    if (this.heartbeatSub) this.heartbeatSub.unsubscribe();
    this.heartbeatSub = interval(60000).subscribe(() => {
      if (this.currentUserId && document.visibilityState === 'visible') {
        this.setOnline(this.currentUserId);
      }
    });

    // Écouteurs de mise en arrière-plan et de fermeture d'onglet (enregistrés une seule fois)
    if (!this.listenersBound) {
      this.listenersBound = true;
      const goOffline = () => {
        if (this.currentUserId) {
          this.setOffline(this.currentUserId);
        }
      };
      window.addEventListener('beforeunload', goOffline);
      // iOS Safari ne déclenche pas toujours beforeunload : pagehide est fiable
      window.addEventListener('pagehide', goOffline);

      document.addEventListener('visibilitychange', () => {
        if (!this.currentUserId) return;
        if (document.visibilityState === 'visible') {
          this.setOnline(this.currentUserId);
        } else {
          this.setOffline(this.currentUserId);
        }
      });
    }
  }

  async setOnline(uid: string): Promise<void> {
    try {
      const userRef = doc(this.firestore, `users/${uid}`);
      await updateDoc(userRef, {
        isOnline: true,
        lastSeen: serverTimestamp()
      });
    } catch {
      // Tolérance silencieuse
    }
  }

  async setOffline(uid: string): Promise<void> {
    try {
      const userRef = doc(this.firestore, `users/${uid}`);
      await updateDoc(userRef, {
        isOnline: false,
        lastSeen: serverTimestamp()
      });
    } catch {
      // Tolérance silencieuse
    }
  }

  /**
   * Écoute en temps réel l'état d'un utilisateur (formateur ou étudiant)
   */
  getUserPresence(uid: string): Observable<UserPresence> {
    if (!uid) {
      return of({ isOnline: false, statusText: 'Hors ligne' });
    }

    const userRef = doc(this.firestore, `users/${uid}`);
    return (docData(userRef) as Observable<any>).pipe(
      map(data => {
        if (!data) return { isOnline: false, statusText: 'Hors ligne' };

        const isOnlineFlag = data.isOnline === true;
        let lastSeenDate: Date | null = null;

        if (data.lastSeen) {
          if (data.lastSeen instanceof Timestamp) {
            lastSeenDate = data.lastSeen.toDate();
          } else if (data.lastSeen.toDate) {
            lastSeenDate = data.lastSeen.toDate();
          } else if (typeof data.lastSeen === 'string' || typeof data.lastSeen === 'number') {
            lastSeenDate = new Date(data.lastSeen);
          }
        }

        // Si lastSeen remonte à moins de 3 minutes, l'utilisateur est considéré actif
        const now = Date.now();
        const diffMinutes = lastSeenDate ? Math.floor((now - lastSeenDate.getTime()) / 60000) : 999;
        const isReallyOnline = isOnlineFlag && diffMinutes <= 3;

        let statusText = 'Hors ligne';
        if (isReallyOnline) {
          statusText = 'En ligne';
        } else if (diffMinutes < 60) {
          statusText = `Vu il y a ${diffMinutes} min`;
        } else if (diffMinutes < 1440) {
          statusText = `Vu il y a ${Math.floor(diffMinutes / 60)}h`;
        } else if (lastSeenDate) {
          statusText = `Vu le ${lastSeenDate.toLocaleDateString()}`;
        }

        return {
          isOnline: isReallyOnline,
          lastSeen: lastSeenDate,
          statusText
        };
      })
    );
  }
}
