import { Component, OnInit, signal, inject, viewChild, effect, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import * as L from 'leaflet';
import { kml, gpx } from '@tmcw/togeojson';
import { RaceService, Race } from '../../services/race.service';

// TEMPORARY: set to false once the real API is reachable again.
const MOCK_MODE = false;
const MOCK_TRACK_GEOJSON = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      properties: {},
      geometry: {
        type: 'LineString',
        coordinates: [
          [2.1734, 41.3851],
          [2.1650, 41.3879],
          [2.1550, 41.3900],
          [2.1450, 41.3920],
          [2.1350, 41.3945],
          [2.1300, 41.3980],
          [2.1250, 41.4010],
          [2.1200, 41.4050]
        ]
      }
    }
  ]
};
const MOCK_RACE: Race = {
  id: 'mock-1',
  name: 'Barcelona Marathon',
  city: 'Barcelona',
  country: 'Spain',
  date: '2026-03-15',
  web: 'https://www.zurichmaratobarcelona.es',
  distance: 42,
  trackUrl: 'https://fpcmarathon-tracks.s3.amazonaws.com/tracks/mock-1.geojson',
  trackType: 'geojson'
};

@Component({
  selector: 'app-race-view',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './race-view.component.html',
  styleUrl: './race-view.component.css'
})
export class RaceViewComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly raceService = inject(RaceService);
  private readonly http = inject(HttpClient);

  race = signal<Race | null>(null);
  isLoading = signal<boolean>(true);
  errorMsg = signal<string | null>(null);

  isMapLoading = signal<boolean>(false);
  mapError = signal<string | null>(null);

  mapContainer = viewChild<ElementRef<HTMLDivElement>>('mapContainer');

  private map: L.Map | null = null;
  private mapInitStarted = false;

  constructor() {
    // Waits for both the race data (with trackUrl) and the map <div> to exist in the DOM
    // before creating the Leaflet map — either can arrive first depending on load timing.
    effect(() => {
      const r = this.race();
      const container = this.mapContainer();
      if (r?.trackUrl && container && !this.mapInitStarted) {
        this.mapInitStarted = true;
        this.initMap(container.nativeElement, r.trackUrl, r.trackType);
      }
    });
  }

  ngOnInit(): void {
    if (MOCK_MODE) {
      const blob = new Blob([JSON.stringify(MOCK_TRACK_GEOJSON)], { type: 'application/geo+json' });
      this.race.set({ ...MOCK_RACE, trackUrl: URL.createObjectURL(blob) });
      this.isLoading.set(false);
      return;
    }

    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.errorMsg.set('No race id provided.');
      this.isLoading.set(false);
      return;
    }
    this.loadRace(id);
  }

  loadRace(id: string): void {
    this.isLoading.set(true);
    this.errorMsg.set(null);
    this.raceService.getRaceById(id).subscribe({
      next: (data) => {
        this.race.set(data);
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error(err);
        this.errorMsg.set('Failed to load the race. It may not exist or the service is offline.');
        this.isLoading.set(false);
      }
    });
  }

  private initMap(el: HTMLDivElement, trackUrl: string, trackType?: Race['trackType']): void {
    this.isMapLoading.set(true);
    this.mapError.set(null);

    this.loadGeoJson(trackUrl, trackType).subscribe({
      next: (geojson) => {
        this.map = L.map(el, { scrollWheelZoom: false });

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
          maxZoom: 19
        }).addTo(this.map);

        const layer = L.geoJSON(geojson, {
          style: { color: '#3b82f6', weight: 4 },
          pointToLayer: (_feature, latlng) =>
            L.circleMarker(latlng, {
              radius: 6,
              color: '#3b82f6',
              fillColor: '#3b82f6',
              fillOpacity: 0.9
            })
        }).addTo(this.map);

        const bounds = layer.getBounds();
        if (bounds.isValid()) {
          this.map.fitBounds(bounds, { padding: [24, 24] });
        } else {
          this.map.setView([0, 0], 2);
        }

        // Leaflet measures its container synchronously on creation; if the surrounding
        // flex/card layout hasn't finished settling yet, it caches a stale size and
        // leaves the rest of the tile grid blank. Force it to re-measure post-paint.
        requestAnimationFrame(() => {
          this.map?.invalidateSize();
          if (bounds.isValid()) {
            this.map?.fitBounds(bounds, { padding: [24, 24] });
          }
        });

        this.isMapLoading.set(false);
      },
      error: (err) => {
        console.error(err);
        this.mapError.set('Could not load or display the route on the map.');
        this.isMapLoading.set(false);
      }
    });
  }

  private loadGeoJson(url: string, trackType?: Race['trackType']): Observable<any> {
    const type = trackType ?? this.inferTypeFromUrl(url);

    if (type === 'geojson') {
      return this.http.get(url);
    }

    return this.http.get(url, { responseType: 'text' }).pipe(
      map((text) => {
        const xml = new DOMParser().parseFromString(text, 'text/xml');
        return type === 'kml' ? kml(xml) : gpx(xml);
      })
    );
  }

  private inferTypeFromUrl(url: string): 'geojson' | 'kml' | 'gpx' {
    const cleanUrl = url.split('?')[0];
    const ext = cleanUrl.split('.').pop()?.toLowerCase();
    if (ext === 'kml') return 'kml';
    if (ext === 'gpx') return 'gpx';
    return 'geojson';
  }
}
