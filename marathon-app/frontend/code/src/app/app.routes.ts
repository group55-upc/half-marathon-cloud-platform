import { Routes } from '@angular/router';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AddRaceComponent } from './components/add-race/add-race.component';
import { RaceViewComponent } from './components/race-view/race-view.component';

export const routes: Routes = [
  { path: 'dashboard', component: DashboardComponent },
  { path: 'add-race', component: AddRaceComponent },
  { path: 'races/:id', component: RaceViewComponent },
  { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
  { path: '**', redirectTo: 'dashboard' }
];
