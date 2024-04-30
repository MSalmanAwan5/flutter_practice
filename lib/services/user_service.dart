import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "../models/user_model.dart";

final userServiceProvider = Provider<UserService>((ref) => UserService());

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User> getUser(String userId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _db.collection('users').doc(userId).get();

    if (snapshot.exists) {
      return User.fromMap(snapshot.data()!);
    } else {
      throw Exception('User not found');
    }
  }

  Future<void> updateUser(User user) async {
    await _db.collection('users').doc(user.id).update(user.toMap());
  }
}
