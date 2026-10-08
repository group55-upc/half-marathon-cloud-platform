import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

// sends logged-out users to /login and brings them back afterwards
export const authGuard: CanActivateFn = (_route, state) => {
  if (inject(AuthService).accessToken) return true;
  return inject(Router).createUrlTree(['/login'], { queryParams: { returnUrl: state.url } });
};
