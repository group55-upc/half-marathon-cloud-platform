import { Component, OnInit, signal, computed, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { RaceService, Race } from '../../services/race.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.css'
})
export class DashboardComponent implements OnInit {
  private readonly raceService = inject(RaceService);

  // States
  races = signal<Race[]>([]);
  isLoading = signal<boolean>(true);
  errorMsg = signal<string | null>(null);

  // Filters
  searchTerm = signal<string>('');
  filterCountry = signal<string>('');
  filterDistance = signal<string>(''); // 'all', '10', '21', '42', 'other'

  // Options for dropdowns
  countries = computed(() => {
    const list = this.races().map(r => r.country);
    return Array.from(new Set(list)).sort();
  });

  // Filtered races
  filteredRaces = computed(() => {
    let list = this.races();
    const search = this.searchTerm().toLowerCase().trim();
    const country = this.filterCountry();
    const dist = this.filterDistance();

    if (search) {
      list = list.filter(r => 
        r.name.toLowerCase().includes(search) || 
        r.city.toLowerCase().includes(search)
      );
    }

    if (country) {
      list = list.filter(r => r.country === country);
    }

    if (dist && dist !== 'all') {
      if (dist === '10') {
        list = list.filter(r => r.distance === 10);
      } else if (dist === '21') {
        list = list.filter(r => r.distance === 21 || r.distance === 21.097 || (r.distance > 20 && r.distance < 22));
      } else if (dist === '42') {
        list = list.filter(r => r.distance === 42 || r.distance === 42.195 || (r.distance > 41 && r.distance < 43));
      } else if (dist === 'other') {
        list = list.filter(r => 
          ! (r.distance === 10 || 
             (r.distance > 20 && r.distance < 22) || 
             (r.distance > 41 && r.distance < 43))
        );
      }
    }

    return list;
  });

  // Stats
  stats = computed(() => {
    const list = this.filteredRaces();
    const total = list.length;
    const totalDist = list.reduce((sum, r) => sum + Number(r.distance), 0);
    const avgDist = total > 0 ? (totalDist / total).toFixed(1) : '0';
    
    // Find most popular country
    const countryCounts: { [key: string]: number } = {};
    let topCountry = '-';
    let maxCount = 0;
    list.forEach(r => {
      countryCounts[r.country] = (countryCounts[r.country] || 0) + 1;
      if (countryCounts[r.country] > maxCount) {
        maxCount = countryCounts[r.country];
        topCountry = r.country;
      }
    });

    return {
      total,
      avgDist,
      topCountry
    };
  });

  ngOnInit(): void {
    this.loadRaces();
  }

  loadRaces(): void {
    this.isLoading.set(true);
    this.errorMsg.set(null);
    this.raceService.getRaces().subscribe({
      next: (data) => {
        this.races.set(data);
        this.isLoading.set(false);
      },
      error: (err) => {
        console.error(err);
        this.errorMsg.set('Failed to load the data. The service is currently offline.');
        this.isLoading.set(false);
      }
    });
  }

  clearFilters(): void {
    this.searchTerm.set('');
    this.filterCountry.set('');
    this.filterDistance.set('');
  }
}
