import {
  AfterViewInit,
  Component,
  OnDestroy,
  OnInit,
  inject,
  signal
} from '@angular/core';

import { CommonModule } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import * as L from 'leaflet';

import {
  Race,
  RaceRoute,
  RaceService
} from '../../services/race.service';

@Component({
  selector: 'app-race-route',
  standalone: true,
  imports: [
    CommonModule,
    RouterLink
  ],
  templateUrl: './race-route.component.html',
  styleUrl: './race-route.component.css'
})
export class RaceRouteComponent
  implements OnInit, AfterViewInit, OnDestroy {

  private readonly route = inject(ActivatedRoute);
  private readonly raceService = inject(RaceService);

  race = signal<Race | null>(null);
  isLoading = signal(true);
  errorMsg = signal('');

  private map?: L.Map;
  private routeData?: RaceRoute;
  private viewReady = false;

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');

    if (!id) {
      this.errorMsg.set('Race identifier not found.');
      this.isLoading.set(false);
      return;
    }

    this.loadRace(id);
    this.loadRoute(id);
  }

  ngAfterViewInit(): void {
    this.viewReady = true;
    this.initializeMapIfReady();
  }

  ngOnDestroy(): void {
    this.map?.remove();
  }

  private loadRace(id: string): void {
    this.raceService.getRace(id).subscribe({
      next: (race) => {
        this.race.set(race);
      },
      error: () => {
        this.errorMsg.set(
          'Unable to load race information.'
        );
      }
    });
  }

  private loadRoute(id: string): void {
    this.raceService.getRaceRoute(id).subscribe({
      next: (routeData) => {
        this.routeData = routeData;
        this.isLoading.set(false);
        this.initializeMapIfReady();
      },
      error: (error) => {
        this.isLoading.set(false);

        if (error.status === 404) {
          this.errorMsg.set(
            'Route not available for this race.'
          );
        } else {
          this.errorMsg.set(
            'Unable to load the race route.'
          );
        }
      }
    });
  }

  private initializeMapIfReady(): void {
    if (!this.viewReady || !this.routeData || this.map) {
      return;
    }

    this.map = L.map('race-map', {
      zoomControl: true
    });

    L.tileLayer(
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      {
        maxZoom: 19,
        attribution:
          '&copy; OpenStreetMap contributors'
      }
    ).addTo(this.map);

    /*
     * Draw the route using a stronger visual style.
     */
    const routeLayer = L.geoJSON(
      this.routeData as any,
      {
        style: () => ({
          color: '#2563eb',
          weight: 6,
          opacity: 0.95
        })
      }
    ).addTo(this.map);

    /*
     * Establish the map view before adding
     * START and FINISH markers.
     */
    const bounds = routeLayer.getBounds();

    if (bounds.isValid()) {
      this.map.fitBounds(
        bounds,
        {
          padding: [30, 30]
        }
      );
    }

    /*
     * Add START and FINISH only after the
     * Leaflet map has a valid view.
     */
    this.addStartFinishMarkers();
  }

  private addStartFinishMarkers(): void {
    if (!this.map || !this.routeData) {
      return;
    }

    const routeFeature = this.routeData.features.find(
      feature =>
        feature.geometry.type === 'LineString'
    );

    if (!routeFeature) {
      return;
    }

    const coordinates =
      routeFeature.geometry.coordinates as number[][];

    if (coordinates.length < 2) {
      return;
    }

    /*
     * GeoJSON coordinates:
     * [longitude, latitude]
     */
    const firstPoint = coordinates[0];
    const lastPoint =
      coordinates[coordinates.length - 1];

    const startLon = firstPoint[0];
    const startLat = firstPoint[1];

    const finishLon = lastPoint[0];
    const finishLat = lastPoint[1];

    /*
     * START marker
     */
    L.circleMarker(
      [startLat, startLon],
      {
        radius: 8,
        color: '#166534',
        fillColor: '#22c55e',
        fillOpacity: 1,
        weight: 3
      }
    )
      .addTo(this.map)
      .bindTooltip(
        'START',
        {
          permanent: true,
          direction: 'top',
          offset: [0, -10]
        }
      );

    /*
     * FINISH marker
     */
    L.circleMarker(
      [finishLat, finishLon],
      {
        radius: 8,
        color: '#991b1b',
        fillColor: '#ef4444',
        fillOpacity: 1,
        weight: 3
      }
    )
      .addTo(this.map)
      .bindTooltip(
        'FINISH',
        {
          permanent: true,
          direction: 'top',
          offset: [0, -10]
        }
      );
  }
}
