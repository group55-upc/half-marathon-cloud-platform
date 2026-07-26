import { Component, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { RaceService, Race } from '../../services/race.service';

@Component({
  selector: 'app-add-race',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './add-race.component.html',
  styleUrl: './add-race.component.css'
})
export class AddRaceComponent {
  private readonly raceService = inject(RaceService);
  private readonly router = inject(Router);

  // Form fields
  name = '';
  city = '';
  country = '';
  date = '';
  web = '';
  distance: number | null = null;

  // Feedback states
  isSubmitting = signal<boolean>(false);
  success = signal<boolean>(false);
  errorMsg = signal<string | null>(null);

  // Field validation states for styling
  errors = {
    name: false,
    city: false,
    country: false,
    date: false,
    web: false,
    distance: false
  };

  onSubmit(): void {
    if (this.isSubmitting()) return;

    // Reset validations
    this.errors = {
      name: false,
      city: false,
      country: false,
      date: false,
      web: false,
      distance: false
    };

    let hasErrors = false;

    // Validate inputs
    if (!this.name.trim()) {
      this.errors.name = true;
      hasErrors = true;
    }
    if (!this.city.trim()) {
      this.errors.city = true;
      hasErrors = true;
    }
    if (!this.country.trim()) {
      this.errors.country = true;
      hasErrors = true;
    }
    if (!this.date) {
      this.errors.date = true;
      hasErrors = true;
    }
    if (!this.web.trim() || !this.isValidUrl(this.web)) {
      this.errors.web = true;
      hasErrors = true;
    }
    if (this.distance === null || this.distance <= 0) {
      this.errors.distance = true;
      hasErrors = true;
    }

    if (hasErrors) {
      this.errorMsg.set('Please check the form.');
      return;
    }

    this.isSubmitting.set(true);
    this.errorMsg.set(null);

    const newRace: Race = {
      name: this.name.trim(),
      city: this.city.trim(),
      country: this.country.trim(),
      date: this.date,
      web: this.web.trim(),
      distance: Number(this.distance)
    };

    this.raceService.createRace(newRace).subscribe({
      next: (res) => {
        this.isSubmitting.set(false);
        if (res.status === 'ok') {
          this.success.set(true);
          setTimeout(() => {
            this.router.navigate(['/dashboard']);
          }, 2000);
        } else {
          this.errorMsg.set('Failed to save the race. Please try again.');
        }
      },
      error: (err) => {
        console.error(err);
        this.errorMsg.set('An error occurred. Please try later.');
        this.isSubmitting.set(false);
      }
    });
  }

  private isValidUrl(url: string): boolean {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  }
}
