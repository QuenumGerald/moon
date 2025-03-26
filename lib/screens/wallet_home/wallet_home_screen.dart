import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/token.dart';
import '../../models/transaction.dart';
import '../../services/wallet_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/token_card.dart';
import '../../widgets/transaction_card.dart';

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshWalletData();
    });
  }
  
  Future<void> _refreshWalletData() async {
    final walletService = Provider.of<WalletService>(context, listen: false);
    await walletService.refreshWalletBalance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<WalletService>(
        builder: (context, walletService, child) {
          if (walletService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (!walletService.hasWallet) {
            return _buildNoWalletView();
          }

          return SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshWalletData,
              color: AppTheme.primaryColor,
              child: ValueListenableBuilder<int>(
                valueListenable: _selectedIndex,
                builder: (context, selectedIndex, _) {
                  return Column(
                    children: [
                      _buildAppBar(walletService),
                      Expanded(
                        child: _buildBody(selectedIndex, walletService),
                      ),
                      _buildBottomNavBar(),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildNoWalletView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'No Wallet Found',
              style: AppTheme.headingLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Create a new wallet or import an existing one to start using Moon',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Create New Wallet',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.createWallet);
              },
              type: ButtonType.primary,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Import Wallet',
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.importWallet);
              },
              type: ButtonType.outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(WalletService walletService) {
    final wallet = walletService.currentWallet!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Moon Wallet',
                style: AppTheme.headingMedium,
              ),
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
                icon: const Icon(Icons.settings_outlined),
                color: AppTheme.textPrimaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppTheme.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Address',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            // Copy address to clipboard
                          },
                          child: Row(
                            children: [
                              Text(
                                Formatters.formatAddress(wallet.address),
                                style: AppTheme.bodyLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Balance',
                  style: AppTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.formatTokenAmount(wallet.nativeBalance, 18)} MATIC',
                  style: AppTheme.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int selectedIndex, WalletService walletService) {
    switch (selectedIndex) {
      case 0:
        return _buildTokensTab(walletService);
      case 1:
        return _buildTransactionsTab(walletService);
      case 2:
        return _buildVestingTab(walletService);
      default:
        return _buildTokensTab(walletService);
    }
  }

  Widget _buildTokensTab(WalletService walletService) {
    final tokens = walletService.tokens;

    if (tokens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.token_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Tokens Yet',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Create your first token or add existing tokens to your wallet',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Add Token',
              onPressed: () {
                _showAddTokenDialog(context);
              },
              type: ButtonType.outlined,
              width: 180,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tokens.length + 1, // +1 for "Add Token" button
      itemBuilder: (context, index) {
        if (index == tokens.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: CustomButton(
              text: 'Add Token',
              onPressed: () {
                _showAddTokenDialog(context);
              },
              type: ButtonType.outlined,
            ),
          );
        }

        final token = tokens[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TokenCard(
            token: token,
            onTap: () {
              // Navigate to token details
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionsTab(WalletService walletService) {
    final transactions = walletService.transactions;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No Transactions Yet',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Your transactions will appear here',
                style: AppTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TransactionCard(
            transaction: transaction,
            onTap: () {
              // Navigate to transaction details
            },
          ),
        );
      },
    );
  }

  Widget _buildVestingTab(WalletService walletService) {
    // This would be populated with actual vesting data
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.timelapse_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Vesting Schedules',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create a vesting schedule or claim vested tokens',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Check Claimable Tokens',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.claim);
            },
            type: ButtonType.outlined,
            width: 220,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedIndex,
        builder: (context, selectedIndex, _) {
          return BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) {
              _selectedIndex.value = index;
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondaryColor,
            selectedLabelStyle: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTheme.bodySmall,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Wallet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.timelapse_outlined),
                activeIcon: Icon(Icons.timelapse),
                label: 'Vesting',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndex,
      builder: (context, selectedIndex, _) {
        if (selectedIndex == 0) {
          return FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createToken);
            },
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showAddTokenDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Add Token',
          style: AppTheme.headingMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Token Contract Address',
                filled: true,
                fillColor: AppTheme.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTheme.bodyLarge,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final address = controller.text.trim();
              if (address.isNotEmpty) {
                Provider.of<WalletService>(context, listen: false)
                    .addToken(address)
                    .then((_) {
                  Navigator.pop(context);
                }).catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding token: $error'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
