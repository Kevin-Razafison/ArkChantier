import 'package:flutter_test/flutter_test.dart';
import 'package:mon_chantier_app/main.dart';

void main() {
  testWidgets('Vérification du démarrage de ArkChantier', (WidgetTester tester) async {
    // On lance l'application
    await tester.pumpWidget(const ChantierApp());

    // On vérifie que le texte du logo ou du dashboard apparaît
    // Note : On utilise find.textContaining car le texte est en majuscule dans ton UI
    expect(find.textContaining('ARKCHANTIER'), findsWidgets);
  });
}