import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTransactionIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTransactionTitle(),
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatDateTime(transaction.timestamp),
                    style: AppTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getTransactionAmount(),
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getAmountColor(),
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon() {
    final IconData icon;
    final Color backgroundColor;
    final Color iconColor;

    switch (transaction.type) {
      case TransactionType.transfer:
        icon = Icons.swap_horiz;
        backgroundColor = AppTheme.primaryColor.withOpacity(0.2);
        iconColor = AppTheme.primaryColor;
        break;
      case TransactionType.tokenTransfer:
        icon = Icons.swap_horiz;
        backgroundColor = AppTheme.primaryColor.withOpacity(0.2);
        iconColor = AppTheme.primaryColor;
        break;
      case TransactionType.createToken:
        icon = Icons.add_circle_outline;
        backgroundColor = AppTheme.successColor.withOpacity(0.2);
        iconColor = AppTheme.successColor;
        break;
      case TransactionType.lockToken:
        icon = Icons.lock_outline;
        backgroundColor = AppTheme.warningColor.withOpacity(0.2);
        iconColor = AppTheme.warningColor;
        break;
      case TransactionType.createVesting:
        icon = Icons.timelapse_outlined;
        backgroundColor = AppTheme.infoColor.withOpacity(0.2);
        iconColor = AppTheme.infoColor;
        break;
      case TransactionType.claimVesting:
        icon = Icons.download_outlined;
        backgroundColor = AppTheme.successColor.withOpacity(0.2);
        iconColor = AppTheme.successColor;
        break;
      case TransactionType.approve:
        icon = Icons.check_circle_outline;
        backgroundColor = AppTheme.infoColor.withOpacity(0.2);
        iconColor = AppTheme.infoColor;
        break;
      case TransactionType.swap:
        icon = Icons.currency_exchange;
        backgroundColor = AppTheme.accentColor.withOpacity(0.2);
        iconColor = AppTheme.accentColor;
        break;
      case TransactionType.other:
      default:
        icon = Icons.help_outline;
        backgroundColor = AppTheme.textSecondaryColor.withOpacity(0.2);
        iconColor = AppTheme.textSecondaryColor;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getTransactionTitle() {
    switch (transaction.type) {
      case TransactionType.transfer:
        return 'Transfer';
      case TransactionType.tokenTransfer:
        return 'Token Transfer';
      case TransactionType.createToken:
        return 'Create Token';
      case TransactionType.lockToken:
        return 'Lock Token';
      case TransactionType.createVesting:
        return 'Create Vesting';
      case TransactionType.claimVesting:
        return 'Claim Vested Tokens';
      case TransactionType.approve:
        return 'Approve';
      case TransactionType.swap:
        return 'Swap';
      case TransactionType.other:
      default:
        return 'Transaction';
    }
  }

  String _getTransactionAmount() {
    if (transaction.value == BigInt.zero) {
      return '';
    }

    final String symbol = transaction.tokenSymbol ?? 'MATIC';
    final String sign = (transaction.type == TransactionType.claimVesting ||
            (transaction.from.toLowerCase() != transaction.to.toLowerCase()))
        ? '+'
        : '-';
    
    // Assuming 18 decimals for token calculations
    final String amount = Formatters.formatTokenAmount(
      transaction.value, 
      18,
      maxFractionDigits: 6,
    );
    
    return '$sign $amount $symbol';
  }

  Color _getAmountColor() {
    if (transaction.value == BigInt.zero) {
      return AppTheme.textPrimaryColor;
    }

    return (transaction.type == TransactionType.claimVesting ||
            (transaction.from.toLowerCase() != transaction.to.toLowerCase()))
        ? AppTheme.successColor
        : AppTheme.textPrimaryColor;
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (transaction.status) {
      case TransactionStatus.pending:
        color = AppTheme.warningColor;
        text = 'Pending';
        break;
      case TransactionStatus.confirmed:
        color = AppTheme.successColor;
        text = 'Confirmed';
        break;
      case TransactionStatus.failed:
        color = AppTheme.errorColor;
        text = 'Failed';
        break;
      case TransactionStatus.cancelled:
        color = AppTheme.textSecondaryColor;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
