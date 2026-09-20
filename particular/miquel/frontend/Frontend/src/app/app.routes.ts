import { Routes } from '@angular/router';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AddRaceComponent } from './components/add-race/add-race.component';

export const routes: Routes = [
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-race', component: AddRaceComponent },
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: '**', redirectTo: 'dashboard' }
];
