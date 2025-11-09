import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:form_app/main.dart'; 
void main() {
  testWidgets('App carrega e mostra a Home', (WidgetTester tester) async {
    await tester.pumpWidget(const FormApp());
    expect(find.text('Próximo'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
