import { Injectable, inject, signal, computed } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, finalize, tap } from 'rxjs';
import { API_URL } from '../constants/apis';

interface LoginResponse {
  username: string;    // the real username, also when logging in with the email
  idToken: string;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;   // seconds
}

interface Session {
  username: string;
  accessToken: string;
  expiresAt: number;   // ms timestamp
}

const STORAGE_KEY = 'marathon.session';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly session = signal<Session | null>(this.loadSession());

  readonly isLoggedIn = computed(() => this.session() !== null);
  readonly username = computed(() => this.session()?.username ?? null);

  // returns null (and logs out) once the token has expired
  get accessToken(): string | null {
    const s = this.session();
    if (!s) return null;
    if (Date.now() >= s.expiresAt) {
      this.clearSession();
      return null;
    }
    return s.accessToken;
  }

  signup(username: string, email: string, password: string): Observable<{ status: string }> {
    return this.http.post<{ status: string }>(`${API_URL}/auth/signup`, { username, email, password });
  }

  confirm(username: string, code: string): Observable<{ status: string }> {
    return this.http.post<{ status: string }>(`${API_URL}/auth/confirm`, { username, code });
  }

  // "login" can be the username or the email
  login(login: string, password: string): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${API_URL}/auth/login`, { username: login, password }).pipe(
      tap(res => this.saveSession({
        username: res.username,
        accessToken: res.accessToken,
        expiresAt: Date.now() + res.expiresIn * 1000
      }))
    );
  }

  // revokes the tokens in Cognito; the local session is cleared even if that call fails
  logout(): Observable<unknown> {
    return this.http.post(`${API_URL}/auth/logout`, {}).pipe(
      finalize(() => this.clearSession())
    );
  }

  clearSession(): void {
    localStorage.removeItem(STORAGE_KEY);
    this.session.set(null);
  }

  private saveSession(session: Session): void {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(session));
    this.session.set(session);
  }

  private loadSession(): Session | null {
    try {
      const session = JSON.parse(localStorage.getItem(STORAGE_KEY) ?? 'null') as Session | null;
      return session && Date.now() < session.expiresAt ? session : null;
    } catch {
      return null;
    }
  }
}

// turns the backend's Cognito errors into a message for the user
export function authErrorMessage(err: HttpErrorResponse): string {
  if (err.status === 0) return 'Cannot reach the server. Please try later.';
  switch (err.error?.error) {
    case 'NotAuthorizedException': return 'Wrong username or password.';
    case 'UserNotFoundException': return 'Wrong username or password.';
    case 'UsernameExistsException': return 'That username is already taken.';
    case 'InvalidPasswordException': return err.error.message;
    case 'CodeMismatchException': return 'The code is not correct.';
    case 'ExpiredCodeException': return 'The code has expired.';
    case 'LimitExceededException':
    case 'TooManyRequestsException': return 'Too many attempts. Wait a few minutes.';
  }
  return err.error?.message ?? err.error?.error ?? 'An error occurred. Please try later.';
}
