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
        this.errorMsg.set('Unable to load race information.');
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
          this.errorMsg.set('Route not available for this race.');
        } else {
          this.errorMsg.set('Unable to load the race route.');
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

    const routeLayer = L.geoJSON(
      this.routeData as any
    ).addTo(this.map);

    const bounds = routeLayer.getBounds();

    if (bounds.isValid()) {
      this.map.fitBounds(bounds, {
        padding: [30, 30]
      });
    }
  }
}
