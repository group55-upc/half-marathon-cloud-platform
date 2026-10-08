import { Routes } from '@angular/router';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AddRaceComponent } from './components/add-race/add-race.component';
import { RaceViewComponent } from './components/race-view/race-view.component';
import { LoginComponent } from './components/login/login.component';
import { SignupComponent } from './components/signup/signup.component';
import { ConfirmComponent } from './components/confirm/confirm.component';
import { NotificationsComponent } from './components/notifications/notifications.component';
import { authGuard } from './services/auth.guard';

export const routes: Routes = [
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-race', component: AddRaceComponent, canActivate: [authGuard] },
  { path: 'races/:id', component: RaceViewComponent },
  { path: 'notifications', component: NotificationsComponent, canActivate: [authGuard] },
  { path: 'login', component: LoginComponent },
  { path: 'signup', component: SignupComponent },
  { path: 'confirm', component: ConfirmComponent },
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: '**', redirectTo: 'dashboard' }
];
