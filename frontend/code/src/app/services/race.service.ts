import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Race {
  id?: string;
  name: string;
  city: string;
  country: string;
  date: string;
  web: string;
  distance: number;
}

@Injectable({
  providedIn: 'root'
})
export class RaceService {
  private readonly http = inject(HttpClient);
  private readonly apiUrl = 'http://lb-backend-1510711001.us-east-1.elb.amazonaws.com';

  getRaces(filters?: Partial<Race>): Observable<Race[]> {
    let params = new HttpParams();
    if (filters) {
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          params = params.set(key, String(value));
        }
      });
    }
    return this.http.get<Race[]>(`${this.apiUrl}/races`, { params });
  }

  createRace(race: Race): Observable<{ status: string }> {
    return this.http.post<{ status: string }>(`${this.apiUrl}/races`, race);
  }

  checkHealth(): Observable<{ status: string }> {
    return this.http.get<{ status: string }>(`${this.apiUrl}/`);
  }
}
