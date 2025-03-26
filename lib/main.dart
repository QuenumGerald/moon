import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/token.dart';
import 'services/wallet_service.dart';
import 'utils/constants.dart';
import 'screens/wallet_home/wallet_home_screen.dart';
import 'screens/create_token/create_token_screen.dart';
import 'screens/lock_tokens/lock_tokens_screen.dart';
import 'screens/vesting/create_vesting_screen.dart';
import 'screens/claim/claim_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize shared preferences for storage
  await SharedPreferences.getInstance();
  
  runApp(const MoonApp());
}

class MoonApp extends StatelessWidget {
  const MoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletService()),
      ],
      child: MaterialApp(
        title: 'Moon Wallet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.home,
        routes: {
          AppRoutes.home: (context) => const WalletHomeScreen(),
          AppRoutes.createToken: (context) => const CreateTokenScreen(),
          AppRoutes.claim: (context) => const ClaimScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.lockTokens) {
            final token = settings.arguments as Token;
            return MaterialPageRoute(
              builder: (context) => LockTokensScreen(token: token),
            );
          }
          
          if (settings.name == AppRoutes.createVesting) {
            final token = settings.arguments as Token;
            return MaterialPageRoute(
              builder: (context) => CreateVestingScreen(token: token),
            );
          }
          
          return null;
        },
      ),
    );
  }
}
