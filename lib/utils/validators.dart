/// Form field validators used across authentication, booking and payments.
class Validators {
  // Email validation with regex pattern
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    // More comprehensive email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    // Check for common email patterns
    if (value.trim().length < 5) {
      return 'Email is too short';
    }
    
    if (value.trim().length > 50) {
      return 'Email is too long';
    }
    
    return null;
  }

  // Mobile number validation for Indian numbers
  static String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    
    // Remove spaces, dashes, and other characters
    final cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's a valid Indian mobile number
    // Indian mobile numbers: 10 digits starting with 6, 7, 8, 9
    final mobileRegex = RegExp(r'^[6-9]\d{9}$');
    
    if (!mobileRegex.hasMatch(cleanNumber)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name is too long';
    }
    
    // Check for valid characters (letters, spaces, dots, hyphens)
    final nameRegex = RegExp(r'^[a-zA-Z\s\.\-]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, dots, and hyphens';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (value.length > 50) {
      return 'Password is too long';
    }
    
    // Check for at least one letter and one number
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    
    if (!hasLetter || !hasNumber) {
      return 'Password must contain at least one letter and one number';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // PNR validation (6-10 digits)
  static String? validatePNR(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PNR is required';
    }
    
    final pnrRegex = RegExp(r'^\d{6,10}$');
    if (!pnrRegex.hasMatch(value.trim())) {
      return 'PNR must be 6-10 digits';
    }
    
    return null;
  }

  // Train number validation
  static String? validateTrainNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Train number is required';
    }
    
    // Train numbers are typically 5 digits
    final trainRegex = RegExp(r'^\d{5}$');
    if (!trainRegex.hasMatch(value.trim())) {
      return 'Train number must be 5 digits';
    }
    
    return null;
  }

  // Amount validation
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    
    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    
    if (amount > 10000) {
      return 'Amount cannot exceed ₹10,000';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  // Maximum length validation
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.trim().length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  // Card holder name validation
  static String? validateCardHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card holder name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Name is too long';
    }
    
    // Check for valid characters (letters, spaces, dots, hyphens)
    final nameRegex = RegExp(r'^[a-zA-Z\s\.\-]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, dots, and hyphens';
    }
    
    return null;
  }

  // Credit card number validation (Luhn algorithm)
  static String? validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }
    
    // Remove spaces and non-digits
    final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return 'Card number must be 13-19 digits';
    }
    
    // Luhn algorithm validation
    if (!_isValidLuhn(cleanNumber)) {
      return 'Invalid card number';
    }
    
    return null;
  }

  // CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }
    
    final cleanCvv = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanCvv.length < 3 || cleanCvv.length > 4) {
      return 'CVV must be 3-4 digits';
    }
    
    return null;
  }

  // Expiry date validation (MM/YY format)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }
    
    final cleanValue = value.trim();
    final expiryRegex = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$');
    
    if (!expiryRegex.hasMatch(cleanValue)) {
      return 'Please enter expiry in MM/YY format';
    }
    
    final parts = cleanValue.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    
    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0); // Last day of the month
    
    if (expiryDate.isBefore(now)) {
      return 'Card has expired';
    }
    
    return null;
  }

  // Luhn algorithm implementation
  static bool _isValidLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }
}
