import 'package:flutter_test/flutter_test.dart';
import 'package:ucm_mapp_app/utils/map_utils.dart';

void main() {
  test("centroid calcula centro correctamente", () {
    final puntos = [
      Offset(0, 0),
      Offset(10, 10),
      Offset(10, 0),
    ];
    final resultado = centroid(puntos);
    expect(resultado.dx, 20 / 3);
    expect(resultado.dy, 10 / 3);
  });

  test("centroid con un solo punto devuelve ese mismo punto", () {
    final puntos = [Offset(5, 5)];
    final result = centroid(puntos);
    expect(result, Offset(5, 5));
  });

  test("centroid maneja puntos negativos", () {
    final puntos = [
      Offset(-10, -10),
      Offset(-20, -20),
    ];
    final result = centroid(puntos);
    expect(result, Offset(-15, -15));
  });

  test("centroid funciona con listas grandes", () {
    final puntos = List.generate(100, (i) => Offset(i.toDouble(), i.toDouble()));
    final result = centroid(puntos);
    expect(result.dx, 49.5);
    expect(result.dy, 49.5);
  });

  test("getPisos devuelve pisos en orden descendente", () {
    final nombres = ["Piso 1", "Piso 3", "Piso 2"];
    final resultado = getPisos(nombres);
    expect(resultado, [3, 2, 1]);
  });

  test("getPisos devuelve lista vacía si no hay pisos", () {
    final result = getPisos([]);
    expect(result, []);
  });

  test("getPisos maneja pisos duplicados", () {
    final nombres = ["Piso 2", "Piso 2", "Piso 3"];
    final result = getPisos(nombres);
    expect(result, [3, 2, 2]);
  });

  test("getPisos maneja espacios extra y formato inconsistente", () {
    final nombres = [" Piso 1 ", "PISO 3", "piso 2 "];
    final result = getPisos(nombres);
    expect(result, [3, 2, 1]);
  });

}



