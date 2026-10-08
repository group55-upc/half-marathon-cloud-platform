import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { SubscriptionService } from '../../services/subscription.service';
import { Countries } from '../../constants/countries';

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [],
  templateUrl: './notifications.component.html',
  styleUrls: ['../add-race/add-race.component.css', './notifications.component.css']
})
export class NotificationsComponent implements OnInit {
  private readonly subscriptionService = inject(SubscriptionService);

  search = signal<string>('');
  selected = signal<Set<string>>(new Set());
  private saved = signal<Set<string>>(new Set());     
  pending = signal<boolean>(false);

  // Feedback states
  isLoading = signal<boolean>(true);
  isSaving = signal<boolean>(false);
  successMsg = signal<string | null>(null);
  errorMsg = signal<string | null>(null);

  filteredCountries = computed(() => {
    const query = this.search().trim().toLowerCase();
    return query ? Countries.filter(c => c.toLowerCase().includes(query)) : Countries;
  });
  selectedList = computed(() => [...this.selected()].sort());
  isSubscribed = computed(() => this.saved().size > 0);
  hasChanges = computed(() => {
    const selected = this.selected();
    const saved = this.saved();
    return selected.size !== saved.size || [...selected].some(c => !saved.has(c));
  });

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.isLoading.set(true);
    this.subscriptionService.getSubscription().subscribe({
      next: (res) => {
        this.saved.set(new Set(res.countries));
        this.selected.set(new Set(res.countries));
        this.pending.set(res.pending);
        this.isLoading.set(false);
      },
      error: () => {
        this.errorMsg.set('Could not load your notification settings.');
        this.isLoading.set(false);
      }
    });
  }

  // a new Set is needed so the signal notices the change
  toggle(country: string): void {
    this.selected.update(current => {
      const next = new Set(current);
      if (next.has(country)) {
        next.delete(country);
      } else {
        next.add(country);
      }
      return next;
    });
  }

  onSearch(event: Event): void {
    this.search.set((event.target as HTMLInputElement).value);
  }

  save(): void {
    if (this.isSaving() || !this.hasChanges()) return;
    if (this.selected().size === 0) {
      this.cancel();
      return;
    }

    this.isSaving.set(true);
    this.successMsg.set(null);
    this.errorMsg.set(null);

    this.subscriptionService.saveSubscription(this.selectedList()).subscribe({
      next: (res) => {
        this.isSaving.set(false);
        this.successMsg.set(res.pending
          ? 'Almost done! Check your inbox and confirm the email from AWS Notifications.'
          : 'Your countries were updated. Changes can take a few minutes to apply.');
        this.load();
      },
      error: (err) => {
        this.isSaving.set(false);
        this.errorMsg.set(err.status === 409
          ? 'Confirm the AWS Notifications email before changing your countries.'
          : 'Could not save your notification settings.');
      }
    });
  }

  cancel(): void {
    if (this.isSaving()) return;
    if (!confirm('Stop receiving all race notifications?')) return;

    this.isSaving.set(true);
    this.successMsg.set(null);
    this.errorMsg.set(null);

    this.subscriptionService.cancelSubscription().subscribe({
      next: () => {
        this.isSaving.set(false);
        this.successMsg.set('You will no longer receive race notifications.');
        this.load();
      },
      error: () => {
        this.isSaving.set(false);
        this.errorMsg.set('Could not cancel your notifications.');
      }
    });
  }
}
