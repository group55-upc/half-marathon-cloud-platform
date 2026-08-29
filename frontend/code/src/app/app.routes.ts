import { Routes } from '@angular/router';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AddRaceComponent } from './components/add-race/add-race.component';

export const routes: Routes = [
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-race', component: AddRaceComponent },
  {
    path: 'race/:id/route',
    loadComponent: () =>
      import('./components/race-route/race-route.component')
        .then(m => m.RaceRouteComponent)
  },
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: '**', redirectTo: 'dashboard' }
];
