import { Component, signal, OnInit, inject } from '@angular/core';
import { Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { CommonModule } from '@angular/common';
import { RaceService } from './services/race.service';
import { AuthService } from './services/auth.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, CommonModule],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App implements OnInit {
  private readonly raceService = inject(RaceService);
  private readonly router = inject(Router);
  protected readonly auth = inject(AuthService);

  protected readonly title = signal('MarathonCloud');
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

  logout(): void {
    this.auth.logout().subscribe({
      next: () => this.router.navigate(['/dashboard']),
      error: () => this.router.navigate(['/dashboard'])
    });
  }
}
