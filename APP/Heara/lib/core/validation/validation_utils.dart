class ValidationUtils {
  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  static bool isStrongPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9]).{8,}$');
    return regex.hasMatch(password);
  }

  static bool isValidPhone(String phone) {
    final regex = RegExp(r'^01[0-9]{9}$');
    return regex.hasMatch(phone);
  }
}