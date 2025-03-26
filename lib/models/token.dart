class Token {
  final String address;
  final String name;
  final String symbol;
  final int decimals;
  final BigInt totalSupply;
  final BigInt balance;

  Token({
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.totalSupply,
    required this.balance,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      address: json['address'] as String,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      decimals: json['decimals'] as int,
      totalSupply: BigInt.parse(json['totalSupply'] ?? '0'),
      balance: BigInt.parse(json['balance'] ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'name': name,
      'symbol': symbol,
      'decimals': decimals,
      'totalSupply': totalSupply.toString(),
      'balance': balance.toString(),
    };
  }
}
