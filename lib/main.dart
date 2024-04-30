import "firebase_options.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "./models/user_model.dart";
import "./services/user_service.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ProfilePage(),
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, Profile>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<Profile> {
  ProfileNotifier() : super(Profile('', '', '', false));

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value);
  }

  void setImageUrl(String value) {
    state = state.copyWith(imageUrl: value);
  }

  void setIsEditing(bool value) {
    state = state.copyWith(isEditing: value);
  }

  void saveChanges(UserService userService) {
    // Save changes to Firebase Firestore or Realtime Database
    // For this example, we'll just print the updated values
    // print('Updated profile: ${state.name}, ${state.email}');

    userService.updateUser(User(
        id: "bRxW9SqhiNpP3zFaZfRg",
        name: state.name,
        email: state.email,
        imageUrl: state.imageUrl));

    setIsEditing(false);
  }
}

class Profile {
  final String name;
  final String email;
  final String imageUrl;
  final bool isEditing;

  Profile(this.name, this.email, this.imageUrl, this.isEditing);

  Profile copyWith({
    String? name,
    String? email,
    String? imageUrl,
    bool? isEditing,
  }) {
    return Profile(
      name ?? this.name,
      email ?? this.email,
      imageUrl ?? this.imageUrl,
      isEditing ?? this.isEditing,
    );
  }
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    final userService = ref.watch(userServiceProvider);

    if (profile.name == "") {
      // Fetch user data from Firestore
      const userId = 'bRxW9SqhiNpP3zFaZfRg'; // Replace with the actual userId
      userService.getUser(userId).then((user) {
        final imgRef = FirebaseStorage.instance
            .ref("gs://fl-prof-ed.appspot.com")
            .child(user.imageUrl);
        print(imgRef.fullPath);
        // no need of the file extension, the name will do fine.
        print('user: ${user.imageUrl}');
        ref.read(profileProvider.notifier).setName(user.name);
        ref.read(profileProvider.notifier).setEmail(user.email);
        imgRef.getDownloadURL().then(
            (value) => {ref.read(profileProvider.notifier).setImageUrl(value)});
      });

      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                child: Image.network(profile.imageUrl),
              ),
              const SizedBox(height: 20),
              profile.isEditing
                  ? TextFormField(
                      initialValue: profile.name,
                      onChanged: (value) =>
                          ref.read(profileProvider.notifier).setName(value),
                    )
                  : Text(
                      profile.name,
                      style: const TextStyle(fontSize: 24),
                    ),
              const SizedBox(height: 20),
              profile.isEditing
                  ? TextFormField(
                      initialValue: profile.email,
                      onChanged: (value) =>
                          ref.read(profileProvider.notifier).setEmail(value),
                    )
                  : Text(
                      profile.email,
                      style: const TextStyle(fontSize: 24),
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (profile.isEditing) {
                    ref.read(profileProvider.notifier).saveChanges(userService);
                  } else {
                    ref.read(profileProvider.notifier).setIsEditing(true);
                  }
                },
                child: Text(profile.isEditing ? 'Save' : 'Edit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
