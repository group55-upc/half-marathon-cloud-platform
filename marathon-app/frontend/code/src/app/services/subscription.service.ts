import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_URL } from '../constants/apis';

export interface SubscriptionState {
  countries: string[];
  pending: boolean;    // true until the user confirms the AWS Notifications email
}

@Injectable({
  providedIn: 'root'
})
export class SubscriptionService {
  private readonly http = inject(HttpClient);

  private readonly apiUrl = API_URL;

  getSubscription(): Observable<SubscriptionState> {
    return this.http.get<SubscriptionState>(`${this.apiUrl}/subscriptions`);
  }

  saveSubscription(countries: string[]): Observable<{ status: string; pending: boolean }> {
    return this.http.put<{ status: string; pending: boolean }>(`${this.apiUrl}/subscriptions`, { countries });
  }

  cancelSubscription(): Observable<{ status: string }> {
    return this.http.delete<{ status: string }>(`${this.apiUrl}/subscriptions`);
  }
}
