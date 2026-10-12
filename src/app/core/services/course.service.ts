import { Injectable, inject } from '@angular/core';
import {
  Firestore, collection, doc, collectionData, docData,
  query, where, orderBy, limit, startAfter, getDocs,
  addDoc, updateDoc, deleteDoc, serverTimestamp,
  increment, writeBatch, DocumentSnapshot, getDoc,
} from '@angular/fire/firestore';
import { Storage, ref, uploadBytesResumable, uploadBytes, getDownloadURL, deleteObject } from '@angular/fire/storage';
import { Observable, from, map } from 'rxjs';
import { Course, Lesson, Section, Review, CourseLevel, CourseLanguage, User } from '../models';

export interface CourseFilters {
  categoryId?: string;
  level?: CourseLevel;
  language?: CourseLanguage;
  isFree?: boolean;
  minPrice?: number;
  maxPrice?: number;
  search?: string;
}

export interface UploadProgress {
  progress: number;
  downloadURL?: string;
  error?: string;
}

@Injectable({ providedIn: 'root' })
export class CourseService {
  private firestore = inject(Firestore);
  private storage = inject(Storage);

  // ── Courses ──────────────────────────────────────────────

  getCourses(filters: CourseFilters = {}, pageSize = 12, lastDoc?: DocumentSnapshot): Observable<Course[]> {
    const constraints: any[] = [where('isPublished', '==', true)];
    if (filters.categoryId) constraints.push(where('categoryId', '==', filters.categoryId));
    if (filters.level) constraints.push(where('level', '==', filters.level));
    if (filters.language) constraints.push(where('language', '==', filters.language));
    if (filters.isFree !== undefined) constraints.push(where('isFree', '==', filters.isFree));
    constraints.push(orderBy('rating', 'desc'), limit(pageSize));
    if (lastDoc) constraints.push(startAfter(lastDoc));

    const q = query(collection(this.firestore, 'courses'), ...constraints);
    return collectionData(q, { idField: 'id' }) as Observable<Course[]>;
  }

  getFeaturedCourses(): Observable<Course[]> {
    const q = query(
      collection(this.firestore, 'courses'),
      where('isPublished', '==', true),
      where('isFeatured', '==', true),
      orderBy('enrolledCount', 'desc'),
      limit(6)
    );
    return collectionData(q, { idField: 'id' }) as Observable<Course[]>;
  }

  getCourseById(id: string): Observable<Course | undefined> {
    return docData(doc(this.firestore, `courses/${id}`), { idField: 'id' }) as Observable<Course | undefined>;
  }

  getTeacherCourses(teacherId: string): Observable<Course[]> {
    const q = query(
      collection(this.firestore, 'courses'),
      where('teacherId', '==', teacherId),
      orderBy('createdAt', 'desc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Course[]>;
  }

  async createCourse(courseData: Partial<Course>): Promise<string> {
    const ref = await addDoc(collection(this.firestore, 'courses'), {
      ...courseData,
      rating: 0,
      ratingCount: 0,
      enrolledCount: 0,
      viewsCount: 0,
      earnings: 0,
      isPublished: false,
      publicationStatus: (courseData.publicationStatus || 'draft'),
      isFeatured: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
    return ref.id;
  }

  async updateCourse(id: string, data: Partial<Course>): Promise<void> {
    await updateDoc(doc(this.firestore, `courses/${id}`), { ...data, updatedAt: serverTimestamp() });
  }

  async publishCourse(id: string): Promise<void> {
    await updateDoc(doc(this.firestore, `courses/${id}`), {
      isPublished: true,
      publicationStatus: 'published',
      updatedAt: serverTimestamp(),
    });
  }

  async submitForReview(id: string): Promise<void> {
    await updateDoc(doc(this.firestore, `courses/${id}`), {
      isPublished: false,
      publicationStatus: 'pending_approval',
      updatedAt: serverTimestamp(),
    });
  }

  async incrementViews(id: string): Promise<void> {
    try {
      await updateDoc(doc(this.firestore, `courses/${id}`), {
        viewsCount: increment(1),
      });
    } catch (e) {
      // Non-blocking view tracking
    }
  }

  async duplicateCourse(courseId: string, teacherId: string): Promise<string> {
    const snap = await getDoc(doc(this.firestore, `courses/${courseId}`));
    if (!snap.exists()) throw new Error('Course not found');
    const orig = snap.data() as Course;

    return await this.createCourse({
      ...orig,
      title: `${orig.title} (Copie)`,
      teacherId,
      isPublished: false,
      publicationStatus: 'draft',
      enrolledCount: 0,
      rating: 0,
      ratingCount: 0,
      viewsCount: 0,
    });
  }

  async deleteCourse(id: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `courses/${id}`));
  }

  /** Get certified teachers for the public directory */
  getPublicTeachers(): Observable<User[]> {
    const q = query(
      collection(this.firestore, 'users'),
      where('role', '==', 'teacher'),
      where('isActive', '==', true)
    );
    return collectionData(q, { idField: 'uid' }) as Observable<User[]>;
  }

  // ── Sections ─────────────────────────────────────────────

  getSections(courseId: string): Observable<Section[]> {
    const q = query(
      collection(this.firestore, `courses/${courseId}/sections`),
      orderBy('order', 'asc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Section[]>;
  }

  async addSection(courseId: string, section: Partial<Section>): Promise<string> {
    const ref = await addDoc(collection(this.firestore, `courses/${courseId}/sections`), {
      ...section,
      courseId,
      lessonIds: [],
    });
    return ref.id;
  }

  async updateSection(courseId: string, sectionId: string, data: Partial<Section>): Promise<void> {
    await updateDoc(doc(this.firestore, `courses/${courseId}/sections/${sectionId}`), data);
  }

  async deleteSection(courseId: string, sectionId: string): Promise<void> {
    await deleteDoc(doc(this.firestore, `courses/${courseId}/sections/${sectionId}`));
  }

  // ── Lessons ──────────────────────────────────────────────

  getLessons(courseId: string): Observable<Lesson[]> {
    const q = query(
      collection(this.firestore, `courses/${courseId}/lessons`),
      orderBy('order', 'asc')
    );
    return collectionData(q, { idField: 'id' }) as Observable<Lesson[]>;
  }

  async addLesson(courseId: string, lesson: Partial<Lesson>): Promise<string> {
    const ref = await addDoc(collection(this.firestore, `courses/${courseId}/lessons`), {
      ...lesson,
      courseId,
      createdAt: serverTimestamp(),
    });
    await updateDoc(doc(this.firestore, `courses/${courseId}`), {
      totalLessons: increment(1),
      updatedAt: serverTimestamp(),
    });
    return ref.id;
  }

  async updateLesson(courseId: string, lessonId: string, data: Partial<Lesson>): Promise<void> {
    await updateDoc(doc(this.firestore, `courses/${courseId}/lessons/${lessonId}`), data);
  }

  async deleteLesson(courseId: string, lessonId: string): Promise<void> {
    const batch = writeBatch(this.firestore);
    batch.delete(doc(this.firestore, `courses/${courseId}/lessons/${lessonId}`));
    batch.update(doc(this.firestore, `courses/${courseId}`), { totalLessons: increment(-1) });
    await batch.commit();
  }

  // ── Reviews ──────────────────────────────────────────────

  getReviews(courseId: string): Observable<Review[]> {
    const q = query(
      collection(this.firestore, `courses/${courseId}/reviews`),
      orderBy('createdAt', 'desc'),
      limit(20)
    );
    return collectionData(q, { idField: 'id' }) as Observable<Review[]>;
  }

  async addReview(courseId: string, review: Partial<Review>): Promise<void> {
    const batch = writeBatch(this.firestore);
    const reviewRef = doc(collection(this.firestore, `courses/${courseId}/reviews`));
    batch.set(reviewRef, { ...review, courseId, createdAt: serverTimestamp() });

    // Recalculate rating
    const courseSnap = await getDoc(doc(this.firestore, `courses/${courseId}`));
    const course = courseSnap.data() as Course;
    const newCount = (course.ratingCount || 0) + 1;
    const newRating = ((course.rating || 0) * (course.ratingCount || 0) + (review.rating || 0)) / newCount;
    batch.update(doc(this.firestore, `courses/${courseId}`), {
      rating: Math.round(newRating * 10) / 10,
      ratingCount: newCount,
    });
    await batch.commit();
  }

  // ── File Upload (Cloudinary via direct upload) ───────────

  async uploadThumbnail(courseId: string, file: File): Promise<string> {
    const path = `courses/${courseId}/thumbnail_${Date.now()}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    return getDownloadURL(storageRef);
  }

  async uploadLessonFile(courseId: string, file: File, type: 'video' | 'pdf' | 'resource'): Promise<string> {
    const path = `courses/${courseId}/lessons/${type}_${Date.now()}_${file.name}`;
    const storageRef = ref(this.storage, path);
    await uploadBytes(storageRef, file);
    return getDownloadURL(storageRef);
  }

  uploadToStorage(path: string, file: File): Observable<UploadProgress> {
    const storageRef = ref(this.storage, path);
    const task = uploadBytesResumable(storageRef, file);

    return new Observable(observer => {
      task.on(
        'state_changed',
        snapshot => {
          const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          observer.next({ progress });
        },
        error => observer.next({ progress: 0, error: error.message }),
        async () => {
          const downloadURL = await getDownloadURL(task.snapshot.ref);
          observer.next({ progress: 100, downloadURL });
          observer.complete();
        }
      );
    });
  }

  async deleteFromStorage(path: string): Promise<void> {
    await deleteObject(ref(this.storage, path));
  }
}
