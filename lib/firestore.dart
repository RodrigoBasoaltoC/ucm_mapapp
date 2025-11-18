import 'package:cloud_firestore/cloud_firestore.dart';
import 'modelos/app_user.dart';// Importa el modelo AppUser

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crea o actualiza un documento de usuario en Firestore
  Future<void> setUser(AppUser user) {
    final options = SetOptions(merge: true);

    return _db
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore(), options);
  }

  // Obtiene los datos de un usuario como un stream
  Stream<AppUser?> userStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? AppUser.fromFirestore(snapshot) : null);
  }

  // Elimina un documento de usuario de Firestore
  Future<void> deleteUser(String uid) {
    return _db.collection('users').doc(uid).delete();
  }
}