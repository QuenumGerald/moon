import 'package:web3dart/web3dart.dart';

class Wallet {
  final String address;
  final String privateKey;
  final String publicKey;
  final String mnemonic;
  final List<String> tokenAddresses;
  final Map<String, BigInt> balances;
  final BigInt nativeBalance;

  Wallet({
    required this.address,
    required this.privateKey,
    required this.publicKey,
    required this.mnemonic,
    required this.tokenAddresses,
    required this.balances,
    required this.nativeBalance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      address: json['address'] as String,
      privateKey: json['privateKey'] as String,
      publicKey: json['publicKey'] as String,
      mnemonic: json['mnemonic'] as String,
      tokenAddresses: List<String>.from(json['tokenAddresses'] ?? []),
      balances: (json['balances'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, BigInt.parse(value.toString())),
          ) ??
          {},
      nativeBalance: BigInt.parse(json['nativeBalance'] ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'privateKey': privateKey,
      'publicKey': publicKey,
      'mnemonic': mnemonic,
      'tokenAddresses': tokenAddresses,
      'balances': balances.map((key, value) => MapEntry(key, value.toString())),
      'nativeBalance': nativeBalance.toString(),
    };
  }

  Credentials getCredentials() {
    return EthPrivateKey.fromHex(privateKey);
  }
}
