import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/token.dart';
import '../../services/wallet_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class LockTokensScreen extends StatefulWidget {
  final Token token;

  const LockTokensScreen({
    super.key,
    required this.token,
  });

  @override
  State<LockTokensScreen> createState() => _LockTokensScreenState();
}

class _LockTokensScreenState extends State<LockTokensScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  DateTime _unlockDate = DateTime.now().add(const Duration(days: 30));
  bool _isLocking = false;
  
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Lock Tokens'),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTokenInfo(),
                const SizedBox(height: 24),
                _buildInfoCard(),
                const SizedBox(height: 24),
                Text(
                  'Lock Details',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                _buildAmountField(),
                const SizedBox(height: 24),
                _buildDateSelector(),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Lock Tokens',
                  onPressed: _isLocking ? null : _lockTokens,
                  isLoading: _isLocking,
                  type: ButtonType.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryLightColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                widget.token.symbol.isNotEmpty
                    ? widget.token.symbol.substring(0, widget.token.symbol.length > 2 ? 2 : widget.token.symbol.length)
                    : '??',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.token.name,
                  style: AppTheme.headingSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: ${Formatters.formatTokenAmount(widget.token.balance, widget.token.decimals)} ${widget.token.symbol}',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.infoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.infoColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About Token Locking',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Locking tokens means they will be temporarily unavailable until the unlock date. This is useful for demonstrating long-term commitment to a project.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Locked tokens cannot be transferred or sold until they are unlocked.',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount to Lock',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            hintText: 'Enter amount',
            suffixText: widget.token.symbol,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: AppTheme.surfaceColor,
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
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
          ),
          style: AppTheme.bodyLarge,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Amount is required';
            }
            
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Amount must be a positive number';
            }
            
            // Convert to token's smallest unit based on decimals
            BigInt amountInSmallestUnit = BigInt.from(double.parse(value) * 
                          pow(10, widget.token.decimals));
            
            if (amountInSmallestUnit > widget.token.balance) {
              return 'Insufficient balance';
            }
            
            return null;
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                // Set max amount (100% of balance)
                final maxAmount = Formatters.formatTokenAmount(
                  widget.token.balance,
                  widget.token.decimals,
                  maxFractionDigits: 6,
                );
                _amountController.text = maxAmount;
              },
              child: Text(
                'Max',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unlock Date',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showDatePicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(_unlockDate),
                  style: AppTheme.bodyLarge,
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tokens will be locked until this date.',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  void _showDatePicker() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 1));
    final maxDate = now.add(const Duration(days: 3650)); // ~10 years
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _unlockDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.textPrimaryColor,
            ),
            dialogBackgroundColor: AppTheme.cardColor,
          ),
          child: child!,
        );
      },
    );
    
    if (selectedDate != null) {
      setState(() {
        _unlockDate = selectedDate;
      });
    }
  }

  // Helper method for math pow with BigInt
  BigInt pow(int base, int exponent) {
    BigInt result = BigInt.one;
    for (int i = 0; i < exponent; i++) {
      result *= BigInt.from(base);
    }
    return result;
  }

  Future<void> _lockTokens() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLocking = true;
      });

      try {
        final amount = BigInt.from(double.parse(_amountController.text) * 
                      pow(10, widget.token.decimals).toInt());
        final unlockTime = _unlockDate.millisecondsSinceEpoch ~/ 1000; // Convert to unix timestamp
        
        final walletService = Provider.of<WalletService>(context, listen: false);
        
        final txHash = await walletService.lockTokens(
          tokenAddress: widget.token.address,
          amount: amount,
          unlockTime: unlockTime,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tokens locked successfully! TX: ${Formatters.formatAddress(txHash)}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate back
        Navigator.pop(context);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error locking tokens: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLocking = false;
          });
        }
      }
    }
  }
}
