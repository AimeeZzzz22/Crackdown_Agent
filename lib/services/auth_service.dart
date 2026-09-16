/// Simple in-memory auth service for demo purposes.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final List<_User> _users = [
    _User(username: 'demo', email: 'demo@crackdown.app', password: 'demo123'),
  ];
  _User? _currentUser;

  /// Instantly log in as the demo account — no credentials needed.
  void signInAsDemo() {
    _currentUser = _users.first;
  }

  _User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // ── Sign Up ────────────────────────────────────────────────────────────────
  /// Returns a list of validation error strings.
  /// Empty list means success — account created.
  List<String> signUp({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final errors = <String>[];

    if (username.trim().isEmpty) {
      errors.add('Username is required');
    } else if (username.trim().length < 3) {
      errors.add('Username must be at least 3 characters');
    }

    if (email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(email.trim())) {
      errors.add('Email format is invalid (e.g. user@gmail.com)');
    }

    if (password.isEmpty) {
      errors.add('Password is required');
    } else if (password.length < 6) {
      errors.add('Password must be at least 6 characters');
    }

    if (confirmPassword.isEmpty) {
      errors.add('Please confirm your password');
    } else if (password != confirmPassword) {
      errors.add('Passwords do not match');
    }

    if (errors.isNotEmpty) return errors;

    // Check duplicate username or email
    final lowerEmail = email.trim().toLowerCase();
    final lowerUsername = username.trim().toLowerCase();
    if (_users.any((u) => u.email.toLowerCase() == lowerEmail)) {
      return ['An account with this email already exists'];
    }
    if (_users.any((u) => u.username.toLowerCase() == lowerUsername)) {
      return ['Username is already taken'];
    }

    _users.add(_User(
      username: username.trim(),
      email: email.trim(),
      password: password,
    ));
    return []; // success
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  /// Returns a list of validation error strings.
  /// Empty list means success — user is now logged in.
  List<String> signIn({
    required String usernameOrEmail,
    required String password,
  }) {
    final errors = <String>[];

    if (usernameOrEmail.trim().isEmpty) {
      errors.add('Username or email is required');
    }
    if (password.isEmpty) {
      errors.add('Password is required');
    }
    if (errors.isNotEmpty) return errors;

    final input = usernameOrEmail.trim().toLowerCase();
    final match = _users.firstWhere(
      (u) =>
          u.username.toLowerCase() == input ||
          u.email.toLowerCase() == input,
      orElse: () => _User.empty,
    );

    if (match.isEmpty) {
      return ['No account found with that username or email'];
    }
    if (match.password != password) {
      return ['Incorrect password'];
    }

    _currentUser = match;
    return []; // success
  }

  // ── Change Password ────────────────────────────────────────────────────────
  List<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    final errors = <String>[];
    if (_currentUser == null) return ['Not logged in'];

    if (currentPassword.isEmpty) errors.add('Current password is required');
    if (newPassword.isEmpty) {
      errors.add('New password is required');
    } else if (newPassword.length < 6) {
      errors.add('New password must be at least 6 characters');
    }
    if (confirmNewPassword != newPassword) {
      errors.add('New passwords do not match');
    }
    if (errors.isNotEmpty) return errors;

    if (_currentUser!.password != currentPassword) {
      return ['Current password is incorrect'];
    }

    _currentUser!.password = newPassword;
    // Update in list too
    final idx = _users.indexWhere((u) => u.username == _currentUser!.username);
    if (idx != -1) _users[idx].password = newPassword;
    return [];
  }

  void signOut() => _currentUser = null;

  // ── Helpers ────────────────────────────────────────────────────────────────
  static bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
}

class _User {
  final String username;
  final String email;
  String password;

  _User({required this.username, required this.email, required this.password});

  static final _User empty = _User(username: '', email: '', password: '');
  bool get isEmpty => username.isEmpty;
}
