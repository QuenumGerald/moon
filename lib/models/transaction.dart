class Transaction {
  final String hash;
  final String from;
  final String to;
  final BigInt value;
  final int timestamp;
  final int blockNumber;
  final TransactionType type;
  final TransactionStatus status;
  final int gasUsed;
  final BigInt gasPrice;
  final String? tokenSymbol;
  final String? contractAddress;

  Transaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.timestamp,
    required this.blockNumber,
    required this.type,
    required this.status,
    required this.gasUsed,
    required this.gasPrice,
    this.tokenSymbol,
    this.contractAddress,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      hash: json['hash'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      value: BigInt.parse(json['value'] ?? '0'),
      timestamp: json['timestamp'] as int,
      blockNumber: json['blockNumber'] as int,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.transfer,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.confirmed,
      ),
      gasUsed: json['gasUsed'] as int,
      gasPrice: BigInt.parse(json['gasPrice'] ?? '0'),
      tokenSymbol: json['tokenSymbol'] as String?,
      contractAddress: json['contractAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'from': from,
      'to': to,
      'value': value.toString(),
      'timestamp': timestamp,
      'blockNumber': blockNumber,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'gasUsed': gasUsed,
      'gasPrice': gasPrice.toString(),
      'tokenSymbol': tokenSymbol,
      'contractAddress': contractAddress,
    };
  }
}

enum TransactionType {
  transfer,
  tokenTransfer,
  createToken,
  lockToken,
  createVesting,
  claimVesting,
  approve,
  swap,
  other
}

enum TransactionStatus {
  pending,
  confirmed,
  failed,
  cancelled
}
