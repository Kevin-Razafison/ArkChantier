import '../models/ouvrier_model.dart';
import '../models/chantier_model.dart';

List<Chantier> globalChantiers = [
  Chantier(id: "1", nom: "Villa Azure", lieu: "Nice", progression: 0.45, statut: StatutChantier.enCours),
  Chantier(id: "2", nom: "Immeuble Horizon", lieu: "Lyon", progression: 0.10, statut: StatutChantier.enRetard),
  // ... tes autres données
];


List<Ouvrier> globalOuvriers = [
  Ouvrier(
    id: "1",
    nom: "Jean Dupont",
    specialite: "Maçon",
    telephone: "0601020304", // Ajouté ici
    salaireJournalier: 60.0,
    joursPointes: ["2026-02-02", "2026-02-03"],
  ),
  Ouvrier(
    id: "2",
    nom: "Marc Simon",
    specialite: "Électricien",
    telephone: "0611223344", // Ajouté ici
    salaireJournalier: 75.0,
    joursPointes: ["2026-02-02"],
  ),
  Ouvrier(
    id: "3",
    nom: "Paul Martin",
    specialite: "Conducteur d'engins",
    telephone: "0788990011", // Ajouté ici
    salaireJournalier: 90.0,
    joursPointes: [],
  ),
  Ouvrier(
    id: "4",
    nom: "Lucas Bernard",
    specialite: "Plombier",
    telephone: "0655443322", // Ajouté ici
    salaireJournalier: 70.0,
    joursPointes: ["2026-02-01", "2026-02-02"],
  ),
];