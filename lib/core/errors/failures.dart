sealed class AppFailure {
  final String message;
  final int? code;
  const AppFailure(this.message, {this.code});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.code});
}

class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, {super.code});
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.code});
}

class ConsentRequiredFailure extends AppFailure {
  const ConsentRequiredFailure()
      : super('Statutory DPDP consent required before accessing this resource.');
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class SyncConflictFailure extends AppFailure {
  const SyncConflictFailure(super.message);
}

