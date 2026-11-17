class SavedDeviceAccount {
  final String userId;
  final String email;
  final String? fullName;
  final bool biometricEnabled;

  const SavedDeviceAccount({
    required this.userId,
    required this.email,
    this.fullName,
    this.biometricEnabled = true,
  });

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    return email.split('@').first;
  }

  String get firstName {
    final name = displayName;
    return name.contains(' ') ? name.split(' ').first : name;
  }

  String get initial {
    final name = displayName;
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }
}
