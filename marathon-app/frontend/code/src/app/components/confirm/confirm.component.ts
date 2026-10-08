import { Component, signal, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { AuthService, authErrorMessage } from '../../services/auth.service';

@Component({
  selector: 'app-confirm',
  standalone: true,
  imports: [FormsModule, RouterLink],
  templateUrl: './confirm.component.html',
  styleUrl: '../add-race/add-race.component.css'
})
export class ConfirmComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  username = this.route.snapshot.queryParamMap.get('username') ?? '';
  code = '';

  isSubmitting = signal<boolean>(false);
  errorMsg = signal<string | null>(null);

  onSubmit(): void {
    if (this.isSubmitting()) return;

    const username = this.username.trim();
    const code = this.code.trim();
    if (!username || !code) {
      this.errorMsg.set('Enter your username and the code from the email.');
      return;
    }

    this.isSubmitting.set(true);
    this.errorMsg.set(null);

    this.auth.confirm(username, code).subscribe({
      next: () => {
        this.router.navigate(['/login'], { queryParams: { username, confirmed: 1 } });
      },
      error: (err: HttpErrorResponse) => {
        this.errorMsg.set(authErrorMessage(err));
        this.isSubmitting.set(false);
      }
    });
  }
}
