import { Injectable, inject } from '@angular/core';
import {
  Firestore, collection, doc, collectionData, query,
  where, orderBy, serverTimestamp, addDoc, updateDoc, setDoc, getDocs, getDoc
} from '@angular/fire/firestore';
import { Storage, ref, uploadBytes, getDownloadURL } from '@angular/fire/storage';
import { Observable, from, map } from 'rxjs';
import { Conversation, Message } from '../models';

@Injectable({
  providedIn: 'root'
})
export class ChatService {
  private firestore = inject(Firestore);
  private storage = inject(Storage);

  // ─── Direct Conversations ─────────────────────────────────────

  getUserConversations(userId: string): Observable<Conversation[]> {
    const q = query(
      collection(this.firestore, 'conversations'),
      where('participants', 'array-contains', userId)
    );
    return collectionData(q, { idField: 'id' }) as Observable<Conversation[]>;
  }

  getMessages(conversationId: string): Observable<Message[]> {
    const q = query(
      collection(this.firestore, `conversations/${conversationId}/messages`),
      orderBy('createdAt', 'asc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Message[]>;
  }

  async getOrCreateConversation(
    currentUserId: string,
    currentUserName: string,
    currentUserPhoto: string,
    otherUserId: string,
    otherUserName: string,
    otherUserPhoto: string,
    courseName?: string
  ): Promise<string> {
    // Generate deterministic conversation ID or search
    const q = query(
      collection(this.firestore, 'conversations'),
      where('participants', 'array-contains', currentUserId)
    );
    const snap = await getDocs(q);
    const existing = snap.docs.find(d => {
      const p = d.data()['participants'] as string[];
      return p && p.includes(otherUserId);
    });

    if (existing) {
      return existing.id;
    }

    const newDoc = await addDoc(collection(this.firestore, 'conversations'), {
      participants: [currentUserId, otherUserId],
      participantNames: {
        [currentUserId]: currentUserName,
        [otherUserId]: otherUserName,
      },
      participantPhotos: {
        [currentUserId]: currentUserPhoto || '',
        [otherUserId]: otherUserPhoto || '',
      },
      lastMessage: 'Conversation démarrée',
      lastMessageAt: serverTimestamp(),
      unreadCount: {
        [currentUserId]: 0,
        [otherUserId]: 0,
      },
      courseName: courseName || 'Formation',
      createdAt: serverTimestamp(),
    });

    return newDoc.id;
  }

  async sendMessage(
    conversationId: string,
    senderId: string,
    senderName: string,
    content: string,
    senderPhotoURL?: string,
    type: 'text' | 'image' | 'file' | 'audio' = 'text',
    fileUrl?: string,
    fileName?: string,
    audioDuration?: number
  ): Promise<void> {
    const messageRef = collection(this.firestore, `conversations/${conversationId}/messages`);
    await addDoc(messageRef, {
      conversationId,
      senderId,
      senderName,
      senderPhotoURL: senderPhotoURL || '',
      content,
      type,
      fileUrl: fileUrl || '',
      fileName: fileName || '',
      audioDuration: audioDuration || 0,
      readBy: [senderId],
      createdAt: serverTimestamp()
    });

    const convRef = doc(this.firestore, `conversations/${conversationId}`);
    await updateDoc(convRef, {
      lastMessage: type === 'audio' ? '🎙️ Message vocal' : type === 'file' ? `📎 ${fileName || 'Fichier'}` : content,
      lastMessageAt: serverTimestamp()
    });
  }

  // ─── Public Channels (General & Q&A) ──────────────────────────

  getChannelMessages(channelId: string): Observable<Message[]> {
    const q = query(
      collection(this.firestore, `channels/${channelId}/messages`),
      orderBy('createdAt', 'asc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Message[]>;
  }

  async sendChannelMessage(
    channelId: string,
    senderId: string,
    senderName: string,
    content: string,
    senderPhotoURL?: string,
    type: 'text' | 'image' | 'file' | 'audio' = 'text',
    fileUrl?: string,
    fileName?: string,
    audioDuration?: number
  ): Promise<void> {
    const messageRef = collection(this.firestore, `channels/${channelId}/messages`);
    await addDoc(messageRef, {
      conversationId: channelId,
      senderId,
      senderName,
      senderPhotoURL: senderPhotoURL || '',
      content,
      type,
      fileUrl: fileUrl || '',
      fileName: fileName || '',
      audioDuration: audioDuration || 0,
      readBy: [senderId],
      createdAt: serverTimestamp()
    });
  }

  // ─── Media Uploads (Audio Notes & Attachments) ─────────────────

  async uploadChatAudio(chatId: string, audioBlob: Blob): Promise<string> {
    const path = `chat/${chatId}/audio_${Date.now()}.webm`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, audioBlob, { contentType: 'audio/webm' });
    return await getDownloadURL(storageRef);
  }

  async uploadChatFile(chatId: string, file: File): Promise<{ url: string; name: string }> {
    const path = `chat/${chatId}/files/${Date.now()}_${file.name}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    const url = await getDownloadURL(storageRef);
    return { url, name: file.name };
  }
}
