import { Component, signal, OnInit, inject } from '@angular/core';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RaceService } from './services/race.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {
  private readonly raceService = inject(RaceService);

  protected readonly title = signal('RunTracker SPA');
  protected readonly isBackendHealthy = signal<boolean | null>(null);

  ngOnInit(): void {
    this.checkApiHealth();
  }

  checkApiHealth(): void {
    this.isBackendHealthy.set(null);
    this.raceService.checkHealth().subscribe({
      next: (res) => {
        this.isBackendHealthy.set(res.status === 'ok');
      },
      error: () => {
        this.isBackendHealthy.set(false);
      }
    });
  }
}
