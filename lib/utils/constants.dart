import 'package:flutter/material.dart';

// Chain IDs
class ChainId {
  static const int polygonMainnet = 137;
  static const int polygonMumbai = 80001;
}

// App Theme
class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF6E56F8);
  static const Color primaryLightColor = Color(0xFF8A7AF9);
  static const Color primaryDarkColor = Color(0xFF5038D5);
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF242D3E);
  static const Color secondaryLightColor = Color(0xFF394358);
  static const Color secondaryDarkColor = Color(0xFF151B27);
  
  // Accent colors
  static const Color accentColor = Color(0xFFFFA726);
  static const Color accentLightColor = Color(0xFFFFBB59);
  static const Color accentDarkColor = Color(0xFFE59600);
  
  // Background colors
  static const Color backgroundColor = Color(0xFF0E1321);
  static const Color cardColor = Color(0xFF1A2235);
  static const Color surfaceColor = Color(0xFF212C42);
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFFAEB9CE);
  static const Color textHintColor = Color(0xFF626F88);
  
  // Status colors
  static const Color successColor = Color(0xFF00C853);
  static const Color warningColor = Color(0xFFFFB300);
  static const Color errorColor = Color(0xFFD50000);
  static const Color infoColor = Color(0xFF2196F3);

  // Card gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6E56F8),
    Color(0xFF8A7AF9),
  ];
  
  static const List<Color> secondaryGradient = [
    Color(0xFF394358),
    Color(0xFF242D3E),
  ];
  
  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      spreadRadius: 1,
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Text styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: 0.25,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: 0.15,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    letterSpacing: 0.15,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
    letterSpacing: 0.15,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
    letterSpacing: 0.25,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
    letterSpacing: 0.4,
  );
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    letterSpacing: 0.15,
  );
  
  // Input decoration theme
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surfaceColor,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    hintStyle: bodyMedium.copyWith(color: textHintColor),
  );
  
  // Card theme
  static CardTheme cardTheme = CardTheme(
    color: cardColor,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.all(8),
  );
  
  // Button themes
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: textPrimaryColor,
      textStyle: buttonText,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    ),
  );
  
  static OutlinedButtonThemeData outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: buttonText,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      side: const BorderSide(color: primaryColor, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
  
  static TextButtonThemeData textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: buttonText,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
  );
  
  // App theme data
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    canvasColor: backgroundColor,
    shadowColor: Colors.black45,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      background: backgroundColor,
      surface: surfaceColor,
      error: errorColor,
      onPrimary: textPrimaryColor,
      onSecondary: textPrimaryColor,
      onBackground: textPrimaryColor,
      onSurface: textPrimaryColor,
      onError: textPrimaryColor,
    ),
    textTheme: const TextTheme(
      displayLarge: headingLarge,
      displayMedium: headingMedium,
      displaySmall: headingSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: buttonText,
    ),
    cardTheme: cardTheme,
    inputDecorationTheme: inputDecorationTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    outlinedButtonTheme: outlinedButtonTheme,
    textButtonTheme: textButtonTheme,
  );
}

// Routes
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String createWallet = '/create-wallet';
  static const String importWallet = '/import-wallet';
  static const String home = '/home';
  static const String createToken = '/create-token';
  static const String lockTokens = '/lock-tokens';
  static const String vesting = '/vesting';
  static const String createVesting = '/create-vesting';
  static const String claim = '/claim';
  static const String walletDetails = '/wallet-details';
  static const String transactionDetails = '/transaction-details';
  static const String scan = '/scan';
  static const String settings = '/settings';
}

// Assets paths
class AppAssets {
  static const String logoPath = 'assets/icons/logo.svg';
  static const String ethPath = 'assets/icons/eth.svg';
  static const String maticPath = 'assets/icons/matic.svg';
  static const String lockPath = 'assets/icons/lock.svg';
  static const String vestingPath = 'assets/icons/vesting.svg';
  static const String tokenPath = 'assets/icons/token.svg';
  static const String walletPath = 'assets/icons/wallet.svg';
}

// API Endpoints
class ApiEndpoints {
  static const String polygonScan = 'https://api.polygonscan.com/api';
  static const String tokenPrice = 'https://api.coingecko.com/api/v3/simple/token_price/polygon-pos';
}
