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
  trackUrl?: string;
  trackType?: 'geojson' | 'kml' | 'gpx';
}

@Injectable({
  providedIn: 'root'
})
export class RaceService {
  private readonly http = inject(HttpClient);
  private readonly apiUrl = 'https://api.fpcmarathon.upcnet.es';

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

  getRaceById(id: string): Observable<Race> {
    const params = new HttpParams().set('id', id);
    return this.http.get<Race>(`${this.apiUrl}/races`, { params });
  }

  // createRace(race: Race): Observable<{ status: string }> {
  //   return this.http.post<{ status: string }>(`${this.apiUrl}/races`, race);
  // }
  createRace(race: Race, trackFile: File): Observable<{ status: string }> {
    const formData = new FormData();
    formData.append('name', race.name);
    formData.append('city', race.city);
    formData.append('country', race.country);
    formData.append('date', race.date);
    formData.append('web', race.web);
    formData.append('distance', String(race.distance));
    formData.append('track', trackFile);
    return this.http.post<{ status: string }>(`${this.apiUrl}/races`, formData);
  }

  checkHealth(): Observable<{ status: string }> {
    return this.http.get<{ status: string }>(`${this.apiUrl}/`);
  }
}
