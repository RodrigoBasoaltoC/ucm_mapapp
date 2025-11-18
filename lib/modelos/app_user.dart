import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? username;

  AppUser({
    required this.uid,
    this.email,
    this.username,
  });

  // Factory para crear un AppUser desde un DocumentSnapshot de Firestore
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'],
      username: data['username'],
    );
  }

  // Método para convertir un AppUser a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      // 'createdAt' se maneja en el servicio para registrar la hora de creación/actualización
    };
  }
}