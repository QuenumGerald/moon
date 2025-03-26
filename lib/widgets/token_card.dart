import 'package:flutter/material.dart';
import '../models/token.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class TokenCard extends StatelessWidget {
  final Token token;
  final VoidCallback? onTap;
  final bool showActions;

  const TokenCard({
    super.key,
    required this.token,
    this.onTap,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                      token.symbol.isNotEmpty 
                          ? token.symbol.substring(0, token.symbol.length > 2 ? 2 : token.symbol.length) 
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
                        token.name,
                        style: AppTheme.headingSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        token.symbol,
                        style: AppTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Balance',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatTokenAmount(token.balance, token.decimals),
              style: AppTheme.headingMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    context,
                    Icons.lock_outline,
                    'Lock',
                    () => navigateToLock(context),
                  ),
                  _buildActionButton(
                    context,
                    Icons.timelapse_outlined,
                    'Vest',
                    () => navigateToVest(context),
                  ),
                  _buildActionButton(
                    context,
                    Icons.send_outlined,
                    'Send',
                    () => navigateToSend(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, 
    IconData icon, 
    String label, 
    VoidCallback onTap
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void navigateToLock(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.lockTokens,
      arguments: token,
    );
  }

  void navigateToVest(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.createVesting,
      arguments: token,
    );
  }

  void navigateToSend(BuildContext context) {
    // Navigate to send tokens screen
  }
}
