import { Component, signal, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { HttpErrorResponse } from '@angular/common/http';
import { Router, RouterLink } from '@angular/router';
import { AuthService, authErrorMessage } from '../../services/auth.service';

@Component({
  selector: 'app-signup',
  standalone: true,
  imports: [FormsModule, RouterLink],
  templateUrl: './signup.component.html',
  styleUrl: '../add-race/add-race.component.css'
})
export class SignupComponent {
  private readonly auth = inject(AuthService);
  private readonly router = inject(Router);

  username = '';
  email = '';
  password = '';
  repeatPassword = '';

  isSubmitting = signal<boolean>(false);
  errorMsg = signal<string | null>(null);

  errors = {
    username: false,
    email: false,
    password: false,
    repeatPassword: false
  };

  onSubmit(): void {
    if (this.isSubmitting()) return;

    // Politica de pssw de cognito
    this.errors = {
      username: !/^[^\s@]+$/.test(this.username.trim()),
      email: !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.email.trim()),
      password: this.password.length < 8,
      repeatPassword: this.password !== this.repeatPassword
    };

    if (Object.values(this.errors).some(Boolean)) {
      this.errorMsg.set('Please check the form.');
      return;
    }

    this.isSubmitting.set(true);
    this.errorMsg.set(null);

    const username = this.username.trim();
    this.auth.signup(username, this.email.trim(), this.password).subscribe({
      next: () => {
        this.router.navigate(['/confirm'], { queryParams: { username } });
      },
      error: (err: HttpErrorResponse) => {
        this.errorMsg.set(authErrorMessage(err));
        this.isSubmitting.set(false);
      }
    });
  }
}
