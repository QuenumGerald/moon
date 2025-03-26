import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vesting_schedule.dart';
import '../../services/wallet_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class ClaimScreen extends StatefulWidget {
  const ClaimScreen({super.key});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  bool _isLoading = false;
  bool _isClaiming = false;
  final TextEditingController _contractAddressController = TextEditingController();
  
  // This would typically come from your wallet service
  // For now, we'll use a dummy list for UI development
  final List<VestingSchedule> _vestingSchedules = [];

  @override
  void dispose() {
    _contractAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Claim Vested Tokens'),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading 
          ? _buildLoadingView() 
          : _vestingSchedules.isEmpty 
            ? _buildEmptyView() 
            : _buildVestingSchedulesList(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check Claimable Tokens',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'If someone has created a vesting schedule for you, enter the contract address to check your claimable tokens.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text(
            'Vesting Contract Address',
            style: AppTheme.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contractAddressController,
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
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Check Contract',
            onPressed: _checkVestingContract,
            type: ButtonType.primary,
          ),
          const SizedBox(height: 40),
          _buildVestingExplainer(),
        ],
      ),
    );
  }

  Widget _buildVestingExplainer() {
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
            'How Token Vesting Works',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          _buildExplainerItem(
            icon: Icons.schedule_outlined,
            title: 'Gradual Release',
            description: 'Tokens are released gradually over time according to a vesting schedule',
          ),
          const SizedBox(height: 16),
          _buildExplainerItem(
            icon: Icons.lock_clock_outlined,
            title: 'Cliff Period',
            description: 'Some schedules include a cliff period before any tokens can be claimed',
          ),
          const SizedBox(height: 16),
          _buildExplainerItem(
            icon: Icons.download_outlined,
            title: 'Claiming',
            description: 'You can claim your vested tokens at any time after they are released',
          ),
        ],
      ),
    );
  }

  Widget _buildExplainerItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVestingSchedulesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vestingSchedules.length,
      itemBuilder: (context, index) {
        final schedule = _vestingSchedules[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildVestingCard(schedule),
        );
      },
    );
  }

  Widget _buildVestingCard(VestingSchedule schedule) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final claimableAmount = schedule.getClaimableAmount(now);
    final tokenSymbol = schedule.tokenSymbol;
    final progress = _calculateVestingProgress(schedule);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLightColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    tokenSymbol.isNotEmpty
                        ? tokenSymbol.substring(0, tokenSymbol.length > 2 ? 2 : tokenSymbol.length)
                        : '??',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.tokenName,
                      style: AppTheme.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getVestingStatus(schedule),
                      style: AppTheme.bodySmall.copyWith(
                        color: _getVestingStatusColor(schedule),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVestingProgressBar(progress),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.formatTokenAmount(schedule.totalAmount, 18)} $tokenSymbol',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Claimable Now',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.formatTokenAmount(claimableAmount, 18)} $tokenSymbol',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: claimableAmount > BigInt.zero 
                          ? AppTheme.successColor 
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'End Date',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatDate(schedule.endTime),
                    style: AppTheme.bodyMedium,
                  ),
                ],
              ),
              if (claimableAmount > BigInt.zero)
                CustomButton(
                  text: 'Claim Tokens',
                  onPressed: _isClaiming ? null : () => _claimTokens(schedule),
                  isLoading: _isClaiming,
                  type: ButtonType.primary,
                  width: 140,
                  height: 40,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVestingProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vesting Progress',
              style: AppTheme.bodyMedium,
            ),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.surfaceColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  String _getVestingStatus(VestingSchedule schedule) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    if (!schedule.isActive) {
      return 'Inactive';
    }
    
    if (now < schedule.cliffTime) {
      return 'In Cliff Period';
    }
    
    if (now >= schedule.endTime) {
      return 'Fully Vested';
    }
    
    return 'Vesting Active';
  }

  Color _getVestingStatusColor(VestingSchedule schedule) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    if (!schedule.isActive) {
      return AppTheme.errorColor;
    }
    
    if (now < schedule.cliffTime) {
      return AppTheme.warningColor;
    }
    
    if (now >= schedule.endTime) {
      return AppTheme.successColor;
    }
    
    return AppTheme.infoColor;
  }

  double _calculateVestingProgress(VestingSchedule schedule) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    if (now <= schedule.startTime) {
      return 0.0;
    }
    
    if (now >= schedule.endTime) {
      return 1.0;
    }
    
    return (now - schedule.startTime) / (schedule.endTime - schedule.startTime);
  }

  Future<void> _checkVestingContract() async {
    final address = _contractAddressController.text.trim();
    if (address.isEmpty || !address.startsWith('0x') || address.length != 42) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid contract address'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, you would fetch vesting schedule details from the blockchain
      // For now, we'll simulate this with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // This is where you would fetch and add the actual vesting schedule
      
      // For now, we'll just clear existing schedules
      // If you had real data, you would add it to _vestingSchedules
      setState(() {
        // _vestingSchedules.add(someRealVestingSchedule);
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking vesting contract: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _claimTokens(VestingSchedule schedule) async {
    setState(() {
      _isClaiming = true;
    });
    
    try {
      final walletService = Provider.of<WalletService>(context, listen: false);
      final txHash = await walletService.claimVestedTokens(schedule.id);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tokens claimed successfully! TX: ${Formatters.formatAddress(txHash)}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      
      // Update the vesting schedule (this would be handled by your service in a real app)
      setState(() {
        // Update the claimed amount in the schedule
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming tokens: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }
}
