import 'package:flutter/material.dart';

Offset centroid(List<Offset> puntos) {
  double x = 0;
  double y = 0;
  for (var p in puntos) {
    x += p.dx;
    y += p.dy;
  }
  return Offset(x / puntos.length, y / puntos.length);
}

List<int> getPisos(List<String> nombres) {
  return nombres
      .map((e) => int.parse(e.replaceAll("Piso ", "")))
      .toList()
    ..sort((a, b) => b.compareTo(a));
}