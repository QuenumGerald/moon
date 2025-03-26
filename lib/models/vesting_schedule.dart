class VestingSchedule {
  final String id;
  final String tokenAddress;
  final String tokenName;
  final String tokenSymbol;
  final BigInt totalAmount;
  final BigInt claimedAmount;
  final int startTime;
  final int cliffTime;
  final int endTime;
  final bool isActive;
  final String beneficiary;

  VestingSchedule({
    required this.id,
    required this.tokenAddress,
    required this.tokenName,
    required this.tokenSymbol,
    required this.totalAmount,
    required this.claimedAmount,
    required this.startTime,
    required this.cliffTime,
    required this.endTime,
    required this.isActive,
    required this.beneficiary,
  });

  factory VestingSchedule.fromJson(Map<String, dynamic> json) {
    return VestingSchedule(
      id: json['id'] as String,
      tokenAddress: json['tokenAddress'] as String,
      tokenName: json['tokenName'] as String,
      tokenSymbol: json['tokenSymbol'] as String,
      totalAmount: BigInt.parse(json['totalAmount'] ?? '0'),
      claimedAmount: BigInt.parse(json['claimedAmount'] ?? '0'),
      startTime: json['startTime'] as int,
      cliffTime: json['cliffTime'] as int,
      endTime: json['endTime'] as int,
      isActive: json['isActive'] as bool,
      beneficiary: json['beneficiary'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tokenAddress': tokenAddress,
      'tokenName': tokenName,
      'tokenSymbol': tokenSymbol,
      'totalAmount': totalAmount.toString(),
      'claimedAmount': claimedAmount.toString(),
      'startTime': startTime,
      'cliffTime': cliffTime,
      'endTime': endTime,
      'isActive': isActive,
      'beneficiary': beneficiary,
    };
  }

  // Calculate claimable amount based on current time
  BigInt getClaimableAmount(int currentTime) {
    if (currentTime < cliffTime || !isActive) {
      return BigInt.zero;
    }
    
    if (currentTime >= endTime) {
      return totalAmount - claimedAmount;
    }
    
    // Linear vesting after cliff
    final vestingDuration = endTime - cliffTime;
    final timeElapsed = currentTime - cliffTime;
    final vestedAmount = totalAmount * BigInt.from(timeElapsed) ~/ BigInt.from(vestingDuration);
    
    return vestedAmount - claimedAmount > BigInt.zero ? vestedAmount - claimedAmount : BigInt.zero;
  }
}
