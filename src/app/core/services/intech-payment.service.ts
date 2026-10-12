import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { environment } from '../../../environments/environment';

export interface IntechPaymentResponse {
  code: number;
  msg: string;
  error: boolean;
  data: {
    phone: string;
    amount: number;
    codeService: string;
    transactionId: string;
    status: 'PENDING' | 'SUCCESS' | 'FAILED';
    externalTransactionId: string;
    callbackUrl: string;
    deepLinkUrl?: string;
    authLinkUrl?: string;
    notificationMessage?: string;
  };
}

export interface IntechTransactionStatusResponse {
  code: number;
  msg: string;
  error: boolean;
  data: {
    transactionId: number;
    createdAt: string;
    updatedAt: string;
    externalTransactionId: string;
    status: 'SUCCESS' | 'FAILED' | 'PENDING' | 'REFUNDED' | 'PROCESSING' | 'CANCELED';
    errorType?: {
      code: string;
      message: string;
    } | null;
  };
}

@Injectable({
  providedIn: 'root'
})
export class IntechPaymentService {
  private http = inject(HttpClient);
  
  private apiUrl = environment.intech.apiUrl;
  private apiKey = environment.intech.apiKey;
  
  // Pour limiter les appels (3 par minute max)
  private lastCheckTimestamps: Map<string, number[]> = new Map();

  /**
   * Initier un paiement (CASH_OUT pour paiement client -> nous)
   */
  initiatePayment(
    clientPhone: string,
    amount: number,
    method: 'wave' | 'orange',
    externalTransactionId: string,
    userId: string,
    courseId: string,
    courseTitle: string
  ): Observable<IntechPaymentResponse> {
    const codeService = method === 'wave' 
      ? environment.intech.waveServiceCode
      : environment.intech.orangeServiceCode;

    const formattedPhone = this.formatPhone(clientPhone);
    const baseUrl = window.location.origin;

    const paymentData = {
      phone: formattedPhone,
      amount: amount,
      codeService: codeService,
      externalTransactionId: externalTransactionId,
      callbackUrl: `${baseUrl}/api/payments/callback`,
      apiKey: this.apiKey,
      sender: 'Anour',
      successRedirectUrl: baseUrl,
      errorRedirectUrl: baseUrl,
      data: {
        userId,
        courseId,
        courseTitle,
        type: 'enrollment'
      }
    };

    return this.http.post<IntechPaymentResponse>(
      `${this.apiUrl}/operation`,
      paymentData
    ).pipe(
      catchError(error => this.handleError(error))
    );
  }

  /**
   * Vérifier le statut d'une transaction
   * ATTENTION: Maximum 3 appels par minute par transaction
   */
  checkTransactionStatus(externalTransactionId: string): Observable<IntechTransactionStatusResponse> {
    // Vérifier la limitation
    if (!this.canCheckTransaction(externalTransactionId)) {
      console.warn('⚠️ Limite de vérification atteinte pour cette transaction');
      return throwError(() => new Error('Trop de vérifications. Veuillez patienter.'));
    }

    console.log('📡 Vérification statut pour:', externalTransactionId);

    const requestBody = {
      externalTransactionId: externalTransactionId,
      apiKey: this.apiKey
    };

    return this.http.post<IntechTransactionStatusResponse>(
      `${this.apiUrl}/get-transaction-status`,
      requestBody
    ).pipe(
      map((response: any) => {
        console.log('📊 Statut transaction reçu:', response);
        
        // Transformer le statut FAILED (avec 2 L) en format standard
        if (response.data && response.data.status === 'FAILLED') {
          response.data.status = 'FAILED';
        }
        
        return response;
      }),
      catchError(error => this.handleError(error))
    );
  }

  /**
   * Vérifie si on peut vérifier une transaction (max 3 fois par minute)
   */
  private canCheckTransaction(externalTransactionId: string): boolean {
    const now = Date.now();
    const oneMinute = 60 * 1000;
    
    const timestamps = this.lastCheckTimestamps.get(externalTransactionId) || [];
    const recentTimestamps = timestamps.filter(t => now - t < oneMinute);
    
    if (recentTimestamps.length >= 3) {
      return false;
    }
    
    recentTimestamps.push(now);
    this.lastCheckTimestamps.set(externalTransactionId, recentTimestamps);
    
    return true;
  }

  /**
   * Formater le numéro de téléphone pour Intech
   */
  private formatPhone(phone: string): string {
    let clean = phone.replace(/\D/g, '');
    
    if (clean.startsWith('221')) {
      clean = clean.substring(3);
    }
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    
    clean = clean.slice(-9);
    return clean;
  }

  /**
   * Valider le format du téléphone
   */
  validatePhone(phone: string): boolean {
    if (!phone) return false;
    
    const clean = phone.replace(/\D/g, '');
    
    let number = clean;
    if (clean.startsWith('221')) {
      number = clean.substring(3);
    }
    if (number.startsWith('0')) {
      number = number.substring(1);
    }
    
    const senegalRegex = /^(77|78|76|70|75)[0-9]{7}$/;
    return senegalRegex.test(number);
  }

  /**
   * Générer un ID de transaction unique
   */
  generateTransactionId(userId: string, courseId: string): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 1000000);
    return `ENR_${userId.substring(0, 6)}_${courseId.substring(0, 6)}_${timestamp}_${random}`;
  }

  /**
   * Valider le montant
   */
  validateAmount(amount: number): { valid: boolean; message?: string } {
    if (amount < 20) {
      return { valid: false, message: 'Le montant minimum est de 20 FCFA' };
    }
    if (amount > 500000) {
      return { valid: false, message: 'Le montant maximum est de 500 000 FCFA' };
    }
    if (amount % 10 !== 0) {
      return { valid: false, message: 'Le montant doit être un multiple de 10 FCFA' };
    }
    return { valid: true };
  }

  private handleError(error: any): Observable<never> {
    console.error('❌ Erreur Intech API:', error);
    
    let errorMessage = 'Erreur de paiement';
    
    if (error.error) {
      const errorData = error.error;
      
      if (errorData.msg) {
        errorMessage = errorData.msg;
      }
      
      if (errorData.data) {
        if (errorData.data.apiKey) {
          const apiError = Array.isArray(errorData.data.apiKey) 
            ? errorData.data.apiKey[0] 
            : errorData.data.apiKey;
          
          if (apiError.includes('solde global du partenaire')) {
            errorMessage = '⚠️ Service de paiement temporairement indisponible';
          }
        }
        
        if (errorData.data.phone) {
          const phoneError = Array.isArray(errorData.data.phone) 
            ? errorData.data.phone[0] 
            : errorData.data.phone;
          errorMessage = `Erreur de numéro: ${phoneError}`;
        }
      }
    }
    
    return throwError(() => new Error(errorMessage));
  }
}
