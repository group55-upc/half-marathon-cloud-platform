import { Component, signal, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService, authErrorMessage } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule, RouterLink],
  templateUrl: './login.component.html',
  styleUrls: ['../add-race/add-race.component.css', './login.component.css']
})
export class LoginComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  // Form fields
  username = this.route.snapshot.queryParamMap.get('username') ?? '';
  password = '';

  // Feedback states
  readonly justConfirmed = this.route.snapshot.queryParamMap.has('confirmed');
  isSubmitting = signal<boolean>(false);
  errorMsg = signal<string | null>(null);

  onSubmit(): void {
    if (this.isSubmitting()) return;

    const username = this.username.trim();
    if (!username || !this.password) {
      this.errorMsg.set('Enter your username or email and your password.');
      return;
    }

    this.isSubmitting.set(true);
    this.errorMsg.set(null);

    this.auth.login(username, this.password).subscribe({
      next: () => {
        const returnUrl = this.route.snapshot.queryParamMap.get('returnUrl') ?? '/dashboard';
        this.router.navigateByUrl(returnUrl);
      },
      error: (err: HttpErrorResponse) => {
        this.isSubmitting.set(false);
        if (err.error?.error === 'UserNotConfirmedException') {
          const queryParams = username.includes('@') ? {} : { username };
          this.router.navigate(['/confirm'], { queryParams });
          return;
        }
        this.errorMsg.set(authErrorMessage(err));
      }
    });
  }
}
