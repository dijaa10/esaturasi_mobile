// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// import 'package:esaturasi/main.dart';

// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Membangun aplikasi dan menampilkan frame pertama.
//     await tester.pumpWidget(const MyApp());

//     // Pastikan counter mulai dari 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);

//     // Mencari tombol tambah (FloatingActionButton dengan ikon add).
//     final Finder fab = find.byIcon(Icons.add);
//     expect(fab, findsOneWidget); // Pastikan tombol ada

//     // Simulasi klik pada FloatingActionButton.
//     await tester.tap(fab);
//     await tester.pump(); // Memproses ulang tampilan setelah perubahan

//     // Pastikan counter telah bertambah menjadi 1.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }
