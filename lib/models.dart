// lib/core/tester.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Required for generating unique IDs (though Firestore generates doc IDs too)

// --- AppRoles (Utility for roles, kept as is for now) ---
class AppRoles {
  static const String user = 'user';
  static const String employer = 'employer';
// Add any other roles you might have
}

// --- Contact Types (unchanged, as requested) ---
enum ContactType {
  whatsapp,
  telegram,
  email,
  website,
  phone,
  facebook,
  other;

  String get displayName {
    switch (this) {
      case ContactType.whatsapp:
        return 'واتساب';
      case ContactType.telegram:
        return 'تيليجرام';
      case ContactType.email:
        return 'بريد إلكتروني';
      case ContactType.website:
        return 'موقع إلكتروني';
      case ContactType.phone:
        return 'هاتف';
      case ContactType.facebook:
        return 'فيسبوك';
      case ContactType.other:
        return 'أخرى';
    }
  }
}

class ContactOption {
  final ContactType type;
  final String value;

  ContactOption({required this.type, required this.value});

  Map<String, dynamic> toMap() {
    return {
      'type': type.name, // Store enum name as string
      'value': value,
    };
  }

  factory ContactOption.fromMap(Map<String, dynamic> map) {
    return ContactOption(
      type: ContactType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ContactType.other, // Default to 'other' if type not found
      ),
      value: map['value'] as String,
    );
  }
}

// --- UserModel (Updated for Firebase Firestore) ---
class UserModel {
  final String uid; // Changed from 'id' to 'uid' to match Firebase Auth UID
  final String? email; // Email from Firebase Auth
  final String? username; // Display name
  final String role; // "user", "employer", etc.
  final bool isAnonymous; // From Firebase Auth
  final List<String> favorites; // job IDs
  final List<String> myJobs; // job IDs (posted by this user)
  final DateTime createdAt; // Creation timestamp from Firestore

  UserModel({
    required this.uid,
    this.email,
    this.username,
    required this.role,
    required this.isAnonymous,
    this.favorites = const [],
    this.myJobs = const [],
    required this.createdAt,
  });

  // Factory constructor to create UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id, // Firestore document ID is the Firebase User UID
      email: data['email'] as String?,
      username: data['username'] as String?,
      role: data['role'] as String? ?? AppRoles.employer, // Default role
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      favorites: List<String>.from(data['favorites'] ?? []),
      myJobs: List<String>.from(data['myJobs'] ?? []),
      // Safely handle potential null for 'createdAt' Timestamp
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Method to convert UserModel to a Map for saving/updating in Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'role': role,
      'isAnonymous': isAnonymous,
      'favorites': favorites,
      'myJobs': myJobs,
      'createdAt': Timestamp.fromDate(createdAt), // Convert DateTime to Firestore Timestamp
    };
  }

  // copyWith method for easier immutable updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? role,
    bool? isAnonymous,
    List<String>? favorites,
    List<String>? myJobs,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      favorites: favorites ?? this.favorites,
      myJobs: myJobs ?? this.myJobs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// --- JobModel (Updated for Firebase Firestore) ---
class JobModel {
  final String id; // Job document ID (should be `Uuid().v4()`)
  final String title;
  final String description;
  final String city;
  final String jobType; // e.g., 'full-time', 'part-time', 'remote'
  final String location; // text description of location
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final List<String> hashtags;
  final List<ContactOption> contactOptions;
  final String ownerId; // ID of the Firebase user who posted this job

  // This will be calculated on the client side, not stored in Firestore
  double? distanceInKm;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.jobType,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.hashtags = const [],
    this.contactOptions = const [],
    required this.ownerId, // Add to constructor
    this.distanceInKm,
  });

  // Method to convert JobModel to a Map for saving/updating in Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Store ID within document for easy reference (though doc.id is primary)
      'title': title,
      'description': description,
      'city': city,
      'jobType': jobType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt), // Convert DateTime to Firestore Timestamp
      'hashtags': hashtags,
      'contactOptions': contactOptions.map((e) => e.toMap()).toList(), // Convert list of objects
      'ownerId': ownerId,
      // distanceInKm is NOT included as it's a runtime calculation
    };
  }

  // Factory constructor to create JobModel from a Firestore DocumentSnapshot
  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Safely handle potential nulls for fields
    final List<dynamic> rawHashtags = data['hashtags'] ?? [];
    final List<dynamic> rawContactOptions = data['contactOptions'] ?? [];

    return JobModel(
      id: doc.id, // Firestore document ID is the Job ID
      title: data['title'] as String,
      description: data['description'] as String,
      city: data['city'] as String,
      jobType: data['jobType'] as String,
      location: data['location'] as String,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0, // Handle potential null or int/double
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0, // Handle potential null or int/double
      // Safely handle potential null for 'createdAt' Timestamp
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hashtags: List<String>.from(rawHashtags),
      contactOptions: rawContactOptions
          .map((e) => ContactOption.fromMap(e as Map<String, dynamic>))
          .toList(),
      ownerId: data['ownerId'] as String,
      distanceInKm: null, // Distance is calculated dynamically, not from Firestore
    );
  }

  // Used for updating specific fields of a job (e.g., distanceInKm for UI)
  JobModel copyWith({
    String? id,
    String? title,
    String? description,
    String? city,
    String? jobType,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    List<String>? hashtags,
    List<ContactOption>? contactOptions,
    String? ownerId,
    double? distanceInKm,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      jobType: jobType ?? this.jobType,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      hashtags: hashtags ?? this.hashtags,
      contactOptions: contactOptions ?? this.contactOptions,
      ownerId: ownerId ?? this.ownerId,
      distanceInKm: distanceInKm ?? this.distanceInKm,
    );
  }
}