import 'package:intl/intl.dart';

class Formatters {
  // Format large numbers with commas
  static String formatNumber(num number) {
    return NumberFormat.decimalPattern().format(number);
  }
  
  // Format token amount considering decimals
  static String formatTokenAmount(BigInt amount, int decimals, {int maxFractionDigits = 4}) {
    if (amount == BigInt.zero) return '0';
    
    final amountInEth = amount / BigInt.from(10).pow(decimals);
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: maxFractionDigits,
    );
    
    return formatter.format(amountInEth);
  }
  
  // Format address by shortening it (0x1234...5678)
  static String formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
  
  // Format date from timestamp
  static String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MMM dd, yyyy').format(date);
  }
  
  // Format date and time from timestamp
  static String formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }
  
  // Format remaining time in days, hours, minutes
  static String formatRemainingTime(int futureTimestamp) {
    final now = DateTime.now();
    final future = DateTime.fromMillisecondsSinceEpoch(futureTimestamp * 1000);
    final difference = future.difference(now);
    
    if (difference.isNegative) {
      return 'Completed';
    }
    
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    
    if (days > 0) {
      return '$days days, $hours hours';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes';
    } else {
      return '$minutes minutes';
    }
  }
  
  // Format percentage
  static String formatPercentage(double percentage, {bool showPlusSign = false}) {
    final formatter = NumberFormat.percentPattern();
    formatter.maximumFractionDigits = 2;
    
    if (showPlusSign && percentage > 0) {
      return '+${formatter.format(percentage / 100)}';
    }
    
    return formatter.format(percentage / 100);
  }
  
  // Format fiat currency value (USD)
  static String formatFiatValue(double value) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return formatter.format(value);
  }
  
  // Format gas price from wei to gwei
  static String formatGasPrice(BigInt gasPrice) {
    final gweiValue = gasPrice / BigInt.from(10).pow(9);
    return '${gweiValue.toStringAsFixed(2)} Gwei';
  }
}
