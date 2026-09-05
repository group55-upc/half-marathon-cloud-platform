import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

interface AppConfig {
  apiUrl?: string;
}

interface AppWindow extends Window {
  __APP_CONFIG__?: AppConfig;
}

export interface Race {
  id?: string;
  name: string;
  city: string;
  country: string;
  date: string;
  web: string;
  distance: number;
  routeKey?: string;
}

export interface RaceRoute {
  type: 'FeatureCollection';
  features: Array<{
    type: 'Feature';
    properties: Record<string, unknown>;
    geometry: {
      type: string;
      coordinates: unknown;
    };
  }>;
}

@Injectable({
  providedIn: 'root'
})
export class RaceService {
  private readonly http = inject(HttpClient);

  private readonly apiUrl =
    (window as AppWindow).__APP_CONFIG__?.apiUrl ??
    'http://localhost:5000';
    
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

  getRace(id: string): Observable<Race> {
    const params = new HttpParams().set('id', id);

    return this.http.get<Race>(
      `${this.apiUrl}/races`,
      { params }
    );
  }

  getRaceRoute(id: string): Observable<RaceRoute> {
    return this.http.get<RaceRoute>(
      `${this.apiUrl}/races/${id}/route`
    );
  }

  createRace(race: Race): Observable<{ status: string }> {
    return this.http.post<{ status: string }>(
      `${this.apiUrl}/races`,
      race
    );
  }

  checkHealth(): Observable<{ status: string }> {
    return this.http.get<{ status: string }>(
      `${this.apiUrl}/`
    );
  }
}
