import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/token.dart';
import '../../services/wallet_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class CreateVestingScreen extends StatefulWidget {
  final Token token;

  const CreateVestingScreen({
    super.key,
    required this.token,
  });

  @override
  State<CreateVestingScreen> createState() => _CreateVestingScreenState();
}

class _CreateVestingScreenState extends State<CreateVestingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  DateTime _cliffDate = DateTime.now().add(const Duration(days: 90));
  bool _hasCliff = true;
  bool _isCreating = false;

  @override
  void dispose() {
    _amountController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Vesting'),
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
                  'Vesting Details',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                _buildAmountField(),
                const SizedBox(height: 24),
                _buildBeneficiaryField(),
                const SizedBox(height: 24),
                _buildVestingPeriodSelector(),
                const SizedBox(height: 24),
                _buildCliffToggle(),
                if (_hasCliff) ...[
                  const SizedBox(height: 16),
                  _buildCliffDateSelector(),
                ],
                const SizedBox(height: 32),
                _buildVestingPreview(),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Create Vesting Schedule',
                  onPressed: _isCreating ? null : _createVesting,
                  isLoading: _isCreating,
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
                'About Token Vesting',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Token vesting gradually releases tokens over time according to a predefined schedule. It is commonly used for team allocations, investor tokens, and other strategic distributions.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'A cliff is an initial period during which no tokens are released, after which tokens start vesting linearly until the end date.',
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
          'Amount to Vest',
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

  Widget _buildBeneficiaryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beneficiary Address',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _beneficiaryController,
          decoration: InputDecoration(
            hintText: '0x...',
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
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.qr_code_scanner_outlined,
                color: AppTheme.textSecondaryColor,
              ),
              onPressed: () {
                // Implement QR scanning for address
              },
            ),
          ),
          style: AppTheme.bodyLarge,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Beneficiary address is required';
            }
            
            // Basic Ethereum address validation
            if (!value.startsWith('0x') || value.length != 42) {
              return 'Invalid Ethereum address format';
            }
            
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'The address that will be able to claim the vested tokens',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVestingPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vesting Period',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Start Date',
                date: _startDate,
                onTap: () => _selectDate(
                  initialDate: _startDate,
                  onDateSelected: (date) {
                    setState(() {
                      _startDate = date;
                      // Ensure cliff is not before start date
                      if (_cliffDate.isBefore(_startDate)) {
                        _cliffDate = _startDate.add(const Duration(days: 1));
                      }
                      // Ensure end date is after start date
                      if (_endDate.isBefore(_startDate)) {
                        _endDate = _startDate.add(const Duration(days: 30));
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateField(
                label: 'End Date',
                date: _endDate,
                onTap: () => _selectDate(
                  initialDate: _endDate,
                  firstDate: _startDate.add(const Duration(days: 1)),
                  onDateSelected: (date) {
                    setState(() {
                      _endDate = date;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'The tokens will vest linearly from start to end date',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: AppTheme.bodyMedium,
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCliffToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Add Cliff Period',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: _hasCliff,
          onChanged: (value) {
            setState(() {
              _hasCliff = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildCliffDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliff Date',
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(
            initialDate: _cliffDate,
            firstDate: _startDate,
            lastDate: _endDate,
            onDateSelected: (date) {
              setState(() {
                _cliffDate = date;
              });
            },
          ),
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
                  DateFormat('MMM dd, yyyy').format(_cliffDate),
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
          'No tokens will be claimable until after the cliff date',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildVestingPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vesting Schedule Preview',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            title: 'Start Date',
            date: _startDate,
            isActive: true,
          ),
          if (_hasCliff) ...[
            _buildTimelineItem(
              title: 'Cliff End',
              date: _cliffDate,
              isActive: false,
            ),
          ],
          _buildTimelineItem(
            title: 'End Date',
            date: _endDate,
            isActive: false,
            isLast: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Total Duration: ${_calculateDuration()}',
            style: AppTheme.bodyMedium,
          ),
          if (_hasCliff) ...[
            const SizedBox(height: 8),
            Text(
              'Cliff Duration: ${_calculateCliffDuration()}',
              style: AppTheme.bodyMedium,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required DateTime date,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.primaryColor : AppTheme.surfaceColor,
                border: Border.all(
                  color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppTheme.surfaceColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM dd, yyyy').format(date),
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _calculateDuration() {
    final duration = _endDate.difference(_startDate);
    final days = duration.inDays;
    
    if (days < 30) {
      return '$days days';
    } else if (days < 365) {
      final months = (days / 30).floor();
      final remainingDays = days % 30;
      return '$months months${remainingDays > 0 ? ', $remainingDays days' : ''}';
    } else {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).floor();
      return '$years years${remainingMonths > 0 ? ', $remainingMonths months' : ''}';
    }
  }

  String _calculateCliffDuration() {
    if (!_hasCliff) return 'None';
    
    final duration = _cliffDate.difference(_startDate);
    final days = duration.inDays;
    
    if (days < 30) {
      return '$days days';
    } else if (days < 365) {
      final months = (days / 30).floor();
      final remainingDays = days % 30;
      return '$months months${remainingDays > 0 ? ', $remainingDays days' : ''}';
    } else {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).floor();
      return '$years years${remainingMonths > 0 ? ', $remainingMonths months' : ''}';
    }
  }

  void _selectDate({
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    required Function(DateTime) onDateSelected,
  }) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? now,
      lastDate: lastDate ?? now.add(const Duration(days: 3650)), // ~10 years
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
      onDateSelected(selectedDate);
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

  Future<void> _createVesting() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      try {
        final amount = BigInt.from(double.parse(_amountController.text) * 
                      pow(10, widget.token.decimals).toInt());
        final startTime = _startDate.millisecondsSinceEpoch ~/ 1000; // Unix timestamp
        final endTime = _endDate.millisecondsSinceEpoch ~/ 1000; // Unix timestamp
        final cliffTime = _hasCliff 
                        ? _cliffDate.millisecondsSinceEpoch ~/ 1000
                        : startTime;
        
        final cliffDuration = cliffTime - startTime;
        final duration = endTime - startTime;
        
        final walletService = Provider.of<WalletService>(context, listen: false);
        
        final txHash = await walletService.createVesting(
          tokenAddress: widget.token.address,
          beneficiary: _beneficiaryController.text.trim(),
          amount: amount,
          startTime: startTime,
          cliffDuration: cliffDuration,
          duration: duration,
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vesting schedule created successfully! TX: ${Formatters.formatAddress(txHash)}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate back
        Navigator.pop(context);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating vesting schedule: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }
}
