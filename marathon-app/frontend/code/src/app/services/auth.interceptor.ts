import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, throwError } from 'rxjs';
import { AuthService } from './auth.service';
import { API_URL } from '../constants/apis';

// adds the Cognito access token to every call to our backend (not to S3)
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const router = inject(Router);

  const token = req.url.startsWith(API_URL) ? auth.accessToken : null;
  if (token) {
    req = req.clone({ setHeaders: { Authorization: `Bearer ${token}` } });
  }

  return next(req).pipe(
    catchError((err: HttpErrorResponse) => {
      // token revoked or expired on the server side: log out and ask to log in again
      if (token && err.status === 401 && !req.url.startsWith(`${API_URL}/auth/`)) {
        auth.clearSession();
        router.navigate(['/login'], { queryParams: { returnUrl: router.url } });
      }
      return throwError(() => err);
    })
  );
};
