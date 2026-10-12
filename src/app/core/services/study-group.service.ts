import { Injectable, inject } from '@angular/core';
import {
  Firestore, collection, doc, collectionData, query,
  where, orderBy, serverTimestamp, addDoc, updateDoc, deleteDoc, getDoc, getDocs, Timestamp, arrayUnion, arrayRemove
} from '@angular/fire/firestore';
import { Storage, ref, uploadBytes, getDownloadURL } from '@angular/fire/storage';
import { Observable, from } from 'rxjs';
import { StudyGroup, GroupSharedTask, Message, User } from '../models';

@Injectable({
  providedIn: 'root'
})
export class StudyGroupService {
  private firestore = inject(Firestore);
  private storage = inject(Storage);

  // ─── Query Study Groups ───────────────────────────────────────

  getAllStudyGroups(): Observable<StudyGroup[]> {
    const q = query(
      collection(this.firestore, 'studyGroups'),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<StudyGroup[]>;
  }

  getCourseStudyGroups(courseId: string): Observable<StudyGroup[]> {
    const q = query(
      collection(this.firestore, 'studyGroups'),
      where('courseId', '==', courseId),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<StudyGroup[]>;
  }

  getMyStudyGroups(userId: string): Observable<StudyGroup[]> {
    const q = query(
      collection(this.firestore, 'studyGroups'),
      where('members', 'array-contains', userId),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<StudyGroup[]>;
  }

  // ─── Create & Manage Groups (Configurable limit & Approval mode) ──────────

  async createStudyGroup(params: {
    name: string;
    description: string;
    courseId: string;
    courseTitle: string;
    creator: User;
    maxMembers?: number;
    joinMode?: 'open' | 'request';
  }): Promise<string> {
    const groupRef = collection(this.firestore, 'studyGroups');
    const limit = params.maxMembers ? Math.min(Math.max(params.maxMembers, 2), 10) : 5;
    const mode = params.joinMode || 'open';

    const docRef = await addDoc(groupRef, {
      name: params.name,
      description: params.description || '',
      courseId: params.courseId,
      courseTitle: params.courseTitle,
      creatorId: params.creator.uid,
      creatorName: params.creator.displayName || 'Étudiant',
      creatorPhoto: params.creator.photoURL || '',
      admin1Id: params.creator.uid,
      admin1Name: params.creator.displayName || 'Étudiant',
      admin2Id: '',
      admin2Name: '',
      members: [params.creator.uid],
      memberNames: {
        [params.creator.uid]: params.creator.displayName || 'Étudiant'
      },
      memberPhotos: {
        [params.creator.uid]: params.creator.photoURL || ''
      },
      maxMembers: limit,
      joinMode: mode,
      joinRequests: [],
      status: 'open',
      liveActive: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    // Post initial system welcome message
    const modeMsg = mode === 'request' ? 'Sur demande d\'adhésion' : 'Accès libre';
    await this.sendGroupMessage(
      docRef.id,
      'system',
      'Groupe de Travail',
      `🎉 Groupe de travail « ${params.name} » créé ! Limite : ${limit} membres max (${modeMsg}). Partagez vos documents, devoirs, et révisez ensemble.`,
      '',
      'text'
    );

    return docRef.id;
  }

  async setAdmin2(groupId: string, memberId: string, memberName: string): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    await updateDoc(groupRef, {
      admin2Id: memberId,
      admin2Name: memberName,
      updatedAt: serverTimestamp(),
    });

    await this.sendGroupMessage(
      groupId,
      'system',
      'Groupe de Travail',
      `👑 ${memberName} a été nommé Administrateur 2 (Co-Administrateur du groupe).`,
      '',
      'text'
    );
  }

  async joinStudyGroup(groupId: string, user: User): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    const snap = await getDoc(groupRef);

    if (!snap.exists()) throw new Error('Groupe introuvable');
    const data = snap.data() as StudyGroup;
    const limit = data.maxMembers || 5;

    if (data.members.length >= limit) {
      throw new Error(`Ce groupe est complet (limite de ${limit} personnes atteinte).`);
    }

    if (data.members.includes(user.uid)) {
      return; // Already member
    }

    // If group requires approval, redirect to requestToJoin
    if (data.joinMode === 'request') {
      await this.requestToJoin(groupId, user);
      return;
    }

    const updatedMembers = [...data.members, user.uid];
    const isNowFull = updatedMembers.length >= limit;

    await updateDoc(groupRef, {
      members: arrayUnion(user.uid),
      [`memberNames.${user.uid}`]: user.displayName || 'Étudiant',
      [`memberPhotos.${user.uid}`]: user.photoURL || '',
      status: isNowFull ? 'full' : 'open',
      updatedAt: serverTimestamp(),
    });

    await this.sendGroupMessage(
      groupId,
      'system',
      'Groupe de Travail',
      `👋 ${user.displayName || 'Un nouvel étudiant'} a rejoint le groupe (${updatedMembers.length}/${limit}).`,
      '',
      'text'
    );
  }

  /** Envoyer une demande d'adhésion au créateur du groupe */
  async requestToJoin(groupId: string, user: User): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    const snap = await getDoc(groupRef);
    if (!snap.exists()) throw new Error('Groupe introuvable');
    const data = snap.data() as StudyGroup;
    const limit = data.maxMembers || 5;

    if (data.members.length >= limit) {
      throw new Error(`Ce groupe est déjà complet (${limit}/${limit}).`);
    }

    if (data.members.includes(user.uid)) {
      return; // Déjà membre
    }

    const requests = [...(data.joinRequests || [])];
    if (requests.some(r => r.uid === user.uid)) {
      return; // Déjà en attente
    }

    requests.push({
      uid: user.uid,
      displayName: user.displayName || 'Étudiant',
      photoURL: user.photoURL || '',
      matricule: user.matricule || `CF-2026-${user.uid.slice(0, 5).toUpperCase()}`,
      academicLevel: user.academicLevel || 'Étudiant en Licence',
      requestedAt: Date.now() as any,
    });

    await updateDoc(groupRef, {
      joinRequests: requests,
      updatedAt: serverTimestamp(),
    });
  }

  /** Annuler une demande d'adhésion envoyée */
  async cancelJoinRequest(groupId: string, userId: string): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    const snap = await getDoc(groupRef);
    if (!snap.exists()) return;
    const data = snap.data() as StudyGroup;

    const requests = (data.joinRequests || []).filter(r => r.uid !== userId);
    await updateDoc(groupRef, {
      joinRequests: requests,
      updatedAt: serverTimestamp(),
    });
  }

  /** Le créateur / admin accepte la demande d'un étudiant */
  async acceptJoinRequest(groupId: string, applicant: { uid: string; displayName: string; photoURL?: string }): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    const snap = await getDoc(groupRef);
    if (!snap.exists()) throw new Error('Groupe introuvable');
    const data = snap.data() as StudyGroup;
    const limit = data.maxMembers || 5;

    if (data.members.length >= limit) {
      throw new Error(`Le groupe a atteint sa capacité maximale de ${limit} membres.`);
    }

    const updatedMembers = Array.from(new Set([...data.members, applicant.uid]));
    const remainingRequests = (data.joinRequests || []).filter(r => r.uid !== applicant.uid);
    const isNowFull = updatedMembers.length >= limit;

    await updateDoc(groupRef, {
      members: updatedMembers,
      [`memberNames.${applicant.uid}`]: applicant.displayName || 'Étudiant',
      [`memberPhotos.${applicant.uid}`]: applicant.photoURL || '',
      joinRequests: remainingRequests,
      status: isNowFull ? 'full' : 'open',
      updatedAt: serverTimestamp(),
    });

    await this.sendGroupMessage(
      groupId,
      'system',
      'Groupe de Travail',
      `🤝 La demande de ${applicant.displayName} a été acceptée par l'administrateur (${updatedMembers.length}/${limit}). Bienvenue dans le groupe !`,
      '',
      'text'
    );
  }

  /** Le créateur / admin refuse la demande d'un étudiant */
  async rejectJoinRequest(groupId: string, userId: string): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    const snap = await getDoc(groupRef);
    if (!snap.exists()) return;
    const data = snap.data() as StudyGroup;

    const remainingRequests = (data.joinRequests || []).filter(r => r.uid !== userId);
    await updateDoc(groupRef, {
      joinRequests: remainingRequests,
      updatedAt: serverTimestamp(),
    });
  }

  async leaveStudyGroup(groupId: string, userId: string, userName: string): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    const snap = await getDoc(groupRef);

    if (!snap.exists()) return;
    const data = snap.data() as StudyGroup;

    const remainingMembers = data.members.filter(id => id !== userId);

    if (remainingMembers.length === 0) {
      await deleteDoc(groupRef);
    } else {
      const updates: any = {
        members: arrayRemove(userId),
        status: 'open',
        updatedAt: serverTimestamp(),
      };

      // Reassign admins if needed
      if (data.admin1Id === userId) {
        if (data.admin2Id && data.admin2Id !== userId) {
          updates.admin1Id = data.admin2Id;
          updates.admin1Name = data.admin2Name || '';
          updates.admin2Id = '';
          updates.admin2Name = '';
        } else if (remainingMembers[0]) {
          updates.admin1Id = remainingMembers[0];
          updates.admin1Name = data.memberNames[remainingMembers[0]] || 'Étudiant';
        }
      } else if (data.admin2Id === userId) {
        updates.admin2Id = '';
        updates.admin2Name = '';
      }

      await updateDoc(groupRef, updates);

      await this.sendGroupMessage(
        groupId,
        'system',
        'Groupe de Travail',
        `ℹ️ ${userName} a quitté le groupe (${remainingMembers.length}/5).`,
        '',
        'text'
      );
    }
  }

  // ─── Group Lives (Live en direct pour les 5 membres) ───────────

  async startGroupLive(groupId: string, userId: string, userName: string): Promise<string> {
    const roomId = `group_live_${groupId}_${Date.now()}`;
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    await updateDoc(groupRef, {
      liveActive: true,
      liveRoomId: roomId,
      liveStartedBy: userName,
      updatedAt: serverTimestamp(),
    });

    await this.sendGroupMessage(
      groupId,
      'system',
      'Live Session',
      `🔴 ${userName} a démarré une session Live de travail en direct ! Rejoignez la salle pour corriger les exercices ensemble.`,
      '',
      'text'
    );

    return roomId;
  }

  async endGroupLive(groupId: string): Promise<void> {
    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    await updateDoc(groupRef, {
      liveActive: false,
      liveRoomId: '',
      liveStartedBy: '',
      updatedAt: serverTimestamp(),
    });

    await this.sendGroupMessage(
      groupId,
      'system',
      'Live Session',
      `🏁 La session Live du groupe est terminée.`,
      '',
      'text'
    );
  }

  // ─── Shared Group Tasks & Devoirs (Pour tous les membres) ──────

  getGroupTasks(groupId: string): Observable<GroupSharedTask[]> {
    const q = query(
      collection(this.firestore, `studyGroups/${groupId}/tasks`),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<GroupSharedTask[]>;
  }

  async postGroupTask(groupId: string, taskData: Partial<GroupSharedTask>): Promise<string> {
    const tasksRef = collection(this.firestore, `studyGroups/${groupId}/tasks`);
    const docRef = await addDoc(tasksRef, {
      ...taskData,
      groupId,
      createdAt: serverTimestamp(),
    });

    await this.sendGroupMessage(
      groupId,
      'system',
      'Exercice & Devoir',
      `📚 ${taskData.authorName} a partagé un sujet d'exercice : « ${taskData.title} ».`,
      '',
      'text'
    );

    return docRef.id;
  }

  // ─── Group Chat & Media Sharing (PDFs, Screenshots, Audio) ─────

  getGroupMessages(groupId: string): Observable<Message[]> {
    const q = query(
      collection(this.firestore, `studyGroups/${groupId}/messages`),
      orderBy('createdAt', 'asc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Message[]>;
  }

  async sendGroupMessage(
    groupId: string,
    senderId: string,
    senderName: string,
    content: string,
    senderPhotoURL?: string,
    type: 'text' | 'image' | 'file' | 'audio' = 'text',
    fileUrl?: string,
    fileName?: string,
    audioDuration?: number
  ): Promise<void> {
    const messagesRef = collection(this.firestore, `studyGroups/${groupId}/messages`);
    await addDoc(messagesRef, {
      conversationId: groupId,
      senderId,
      senderName,
      senderPhotoURL: senderPhotoURL || '',
      content,
      type,
      fileUrl: fileUrl || '',
      fileName: fileName || '',
      audioDuration: audioDuration || 0,
      readBy: [senderId],
      createdAt: serverTimestamp(),
    });

    const groupRef = doc(this.firestore, `studyGroups/${groupId}`);
    await updateDoc(groupRef, {
      updatedAt: serverTimestamp()
    });
  }

  async uploadGroupFile(groupId: string, file: File): Promise<{ url: string; name: string; isImage: boolean }> {
    const isImage = file.type.startsWith('image/');
    const path = `study_groups/${groupId}/${Date.now()}_${file.name}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    const url = await getDownloadURL(storageRef);
    return { url, name: file.name, isImage };
  }

  async uploadGroupAudio(groupId: string, audioBlob: Blob): Promise<string> {
    const path = `study_groups/${groupId}/audio_${Date.now()}.webm`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, audioBlob, { contentType: 'audio/webm' });
    return await getDownloadURL(storageRef);
  }
}
