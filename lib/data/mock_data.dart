import '../models/ouvrier_model.dart';
import '../models/chantier_model.dart';

List<Chantier> globalChantiers = [
  Chantier(id: "1", nom: "Villa Azure", lieu: "Nice", progression: 0.45, statut: StatutChantier.enCours),
  Chantier(id: "2", nom: "Immeuble Horizon", lieu: "Lyon", progression: 0.10, statut: StatutChantier.enRetard),
  // ... tes autres données
];

// Cette liste sera partagée par TOUTE l'application
List<Ouvrier> globalOuvriers = [
  Ouvrier(id: '1', nom: "Jean Dupont", specialite: "Maçon Expert"),
  Ouvrier(id: '2', nom: "Marc Vasseur", specialite: "Électricien"),
  Ouvrier(id: '3', nom: "Amine Sadek", specialite: "Conducteur d'engins"),
  Ouvrier(id: '4', nom: "Lucie Bernard", specialite: "Architecte"),
];