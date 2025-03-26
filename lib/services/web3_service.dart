import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
import '../models/token.dart';
import '../models/wallet.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

class Web3Service {
  late Web3Client _client;
  late EthereumAddress _contractAddress;
  
  Web3Service() {
    final rpcUrl = dotenv.env['POLYGON_RPC_URL'] ?? 'https://polygon-rpc.com';
    _client = Web3Client(rpcUrl, http.Client());
  }
  
  // Generate a new wallet with mnemonic
  Future<Wallet> createWallet() async {
    final mnemonic = bip39.generateMnemonic();
    return importWalletFromMnemonic(mnemonic);
  }
  
  // Import a wallet from mnemonic phrase
  Future<Wallet> importWalletFromMnemonic(String mnemonic) async {
    if (!bip39.validateMnemonic(mnemonic)) {
      throw Exception('Invalid mnemonic');
    }
    
    final seed = bip39.mnemonicToSeedHex(mnemonic);
    final privateKey = HEX.encode(List<int>.from(HEX.decode(seed)).sublist(0, 32));
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = await credentials.extractAddress();
    
    return Wallet(
      address: address.hex,
      privateKey: privateKey,
      publicKey: address.hexEip55,
      mnemonic: mnemonic,
      tokenAddresses: [],
      balances: {},
      nativeBalance: BigInt.zero,
    );
  }
  
  // Import wallet from private key
  Future<Wallet> importWalletFromPrivateKey(String privateKey) async {
    if (privateKey.startsWith('0x')) {
      privateKey = privateKey.substring(2);
    }
    
    final credentials = EthPrivateKey.fromHex(privateKey);
    final address = await credentials.extractAddress();
    
    return Wallet(
      address: address.hex,
      privateKey: privateKey,
      publicKey: address.hexEip55,
      mnemonic: '', // No mnemonic when importing from private key
      tokenAddresses: [],
      balances: {},
      nativeBalance: BigInt.zero,
    );
  }
  
  // Get native token (MATIC) balance
  Future<BigInt> getNativeBalance(String address) async {
    final balance = await _client.getBalance(EthereumAddress.fromHex(address));
    return balance.getInWei;
  }
  
  // Get token balance
  Future<BigInt> getTokenBalance(String tokenAddress, String walletAddress) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(await _loadAbi('erc20'), 'ERC20'), 
      EthereumAddress.fromHex(tokenAddress)
    );
    
    final balanceFunction = contract.function('balanceOf');
    final result = await _client.call(
      contract: contract,
      function: balanceFunction,
      params: [EthereumAddress.fromHex(walletAddress)],
    );
    
    return result.first as BigInt;
  }
  
  // Get token details
  Future<Token> getTokenDetails(String tokenAddress, String walletAddress) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(await _loadAbi('erc20'), 'ERC20'), 
      EthereumAddress.fromHex(tokenAddress)
    );
    
    final nameFunction = contract.function('name');
    final symbolFunction = contract.function('symbol');
    final decimalsFunction = contract.function('decimals');
    final totalSupplyFunction = contract.function('totalSupply');
    final balanceFunction = contract.function('balanceOf');
    
    final nameResult = await _client.call(
      contract: contract,
      function: nameFunction,
      params: [],
    );
    
    final symbolResult = await _client.call(
      contract: contract,
      function: symbolFunction,
      params: [],
    );
    
    final decimalsResult = await _client.call(
      contract: contract,
      function: decimalsFunction,
      params: [],
    );
    
    final totalSupplyResult = await _client.call(
      contract: contract,
      function: totalSupplyFunction,
      params: [],
    );
    
    final balanceResult = await _client.call(
      contract: contract,
      function: balanceFunction,
      params: [EthereumAddress.fromHex(walletAddress)],
    );
    
    return Token(
      address: tokenAddress,
      name: nameResult.first.toString(),
      symbol: symbolResult.first.toString(),
      decimals: (decimalsResult.first as BigInt).toInt(),
      totalSupply: totalSupplyResult.first as BigInt,
      balance: balanceResult.first as BigInt,
    );
  }
  
  // Create new token (ERC-20)
  Future<String> createToken({
    required String name,
    required String symbol,
    required BigInt totalSupply,
    required BigInt decimals,
    required Wallet wallet,
  }) async {
    final factoryAddress = dotenv.env['TOKEN_FACTORY_ADDRESS'] ?? '';
    if (factoryAddress.isEmpty) {
      throw Exception('Token factory address not configured');
    }
    
    final contract = DeployedContract(
      ContractAbi.fromJson(await _loadAbi('token_factory'), 'TokenFactory'), 
      EthereumAddress.fromHex(factoryAddress)
    );
    
    final createTokenFunction = contract.function('createToken');
    final credentials = wallet.getCredentials();
    
    final transaction = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: createTokenFunction,
        parameters: [name, symbol, totalSupply, decimals],
        maxGas: 3000000,
      ),
      chainId: ChainId.polygonMainnet,
    );
    
    // Wait for transaction to be mined
    final receipt = await _getTransactionReceipt(transaction);
    if (receipt == null) {
      throw Exception('Transaction failed');
    }
    
    // Extract token address from event logs
    final tokenCreatedEvent = contract.event('TokenCreated');
    final tokenCreatedLogs = receipt.logs
        .where((log) => log.topics!.first == tokenCreatedEvent.signature)
        .toList();
    
    if (tokenCreatedLogs.isEmpty) {
      throw Exception('Token creation event not found');
    }
    
    final decodedLogs = tokenCreatedEvent.decodeResults(
      tokenCreatedLogs.first.topics!,
      tokenCreatedLogs.first.data!,
    );
    
    final tokenAddress = (decodedLogs[1] as EthereumAddress).hex;
    return tokenAddress;
  }
  
  // Lock tokens
  Future<String> lockTokens({
    required String tokenAddress,
    required BigInt amount,
    required int unlockTime,
    required Wallet wallet,
  }) async {
    final lockerAddress = dotenv.env['TOKEN_LOCKER_ADDRESS'] ?? '';
    if (lockerAddress.isEmpty) {
      throw Exception('Token locker address not configured');
    }
    
    // First approve token spending
    await _approveTokens(
      tokenAddress: tokenAddress,
      spender: lockerAddress,
      amount: amount,
      wallet: wallet,
    );
    
    // Then lock tokens
    final contract = DeployedContract(
      ContractAbi.fromJson(await _loadAbi('token_locker'), 'TokenLocker'), 
      EthereumAddress.fromHex(lockerAddress)
    );
    
    final lockFunction = contract.function('lock');
    final credentials = wallet.getCredentials();
    
    final transaction = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: lockFunction,
        parameters: [
          EthereumAddress.fromHex(tokenAddress),
          amount,
          BigInt.from(unlockTime),
        ],
        maxGas: 2000000,
      ),
      chainId: ChainId.polygonMainnet,
    );
    
    // Wait for transaction to be mined
    final receipt = await _getTransactionReceipt(transaction);
    if (receipt == null) {
      throw Exception('Transaction failed');
    }
    
    return transaction;
  }
  
  // Create vesting schedule
  Future<String> createVesting({
    required String tokenAddress,
    required String beneficiary,
    required BigInt amount,
    required int startTime,
    required int cliffDuration,
    required int duration,
    required Wallet wallet,
  }) async {
    final vestingFactoryAddress = dotenv.env['VESTING_FACTORY_ADDRESS'] ?? '';
    if (vestingFactoryAddress.isEmpty) {
      throw Exception('Vesting factory address not configured');
    }
    
    // First approve token spending
    await _approveTokens(
      tokenAddress: tokenAddress,
      spender: vestingFactoryAddress,
      amount: amount,
      wallet: wallet,
    );
    
    // Then create vesting schedule
    final contract = DeployedContract(
      ContractAbi.fromJson(await _loadAbi('vesting_factory'), 'VestingFactory'), 
      EthereumAddress.fromHex(vestingFactoryAddress)
    );
    
    final createVestingFunction = contract.function('createVesting');
    final credentials = wallet.getCredentials();
    
    final transaction = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: createVestingFunction,
        parameters: [
          EthereumAddress.fromHex(tokenAddress),
          EthereumAddress.fromHex(beneficiary),
          amount,
          BigInt.from(startTime),
          BigInt.from(cliffDuration),
          BigInt.from(duration),
        ],
        maxGas: 3000000,
      ),
      chainId: ChainId.polygonMainnet,
    );
    
    // Wait for transaction to be mined
    final receipt = await _getTransactionReceipt(transaction);
    if (receipt == null) {
      throw Exception('Transaction failed');
    }
    
    return transaction;
  }
  
  // Claim vested tokens
  Future<String> claimVestedTokens({
    required String vestingContractAddress,
    required Wallet wallet,
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(await _loadAbi('vesting'), 'Vesting'), 
      EthereumAddress.fromHex(vestingContractAddress)
    );
    
    final claimFunction = contract.function('claim');
    final credentials = wallet.getCredentials();
    
    final transaction = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: claimFunction,
        parameters: [],
        maxGas: 1000000,
      ),
      chainId: ChainId.polygonMainnet,
    );
    
    // Wait for transaction to be mined
    final receipt = await _getTransactionReceipt(transaction);
    if (receipt == null) {
      throw Exception('Transaction failed');
    }
    
    return transaction;
  }
  
  // Get transaction status
  Future<TransactionStatus> getTransactionStatus(String txHash) async {
    final receipt = await _client.getTransactionReceipt(txHash);
    if (receipt == null) {
      return TransactionStatus.pending;
    }
    
    return receipt.status! ? TransactionStatus.confirmed : TransactionStatus.failed;
  }
  
  // Helper function to approve token spending
  Future<String> _approveTokens({
    required String tokenAddress,
    required String spender,
    required BigInt amount,
    required Wallet wallet,
  }) async {
    final contract = DeployedContract(
      ContractAbi.fromJson(await _loadAbi('erc20'), 'ERC20'), 
      EthereumAddress.fromHex(tokenAddress)
    );
    
    final approveFunction = contract.function('approve');
    final credentials = wallet.getCredentials();
    
    final transaction = await _client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: approveFunction,
        parameters: [EthereumAddress.fromHex(spender), amount],
        maxGas: 1000000,
      ),
      chainId: ChainId.polygonMainnet,
    );
    
    // Wait for transaction to be mined
    final receipt = await _getTransactionReceipt(transaction);
    if (receipt == null) {
      throw Exception('Approval transaction failed');
    }
    
    return transaction;
  }
  
  // Helper function to wait for transaction receipt
  Future<TransactionReceipt?> _getTransactionReceipt(String txHash, {int maxAttempts = 40}) async {
    for (var i = 0; i < maxAttempts; i++) {
      final receipt = await _client.getTransactionReceipt(txHash);
      if (receipt != null) {
        return receipt;
      }
      await Future.delayed(const Duration(seconds: 3));
    }
    return null;
  }
  
  // Load ABI from assets
  Future<String> _loadAbi(String name) async {
    return await rootBundle.loadString('assets/abi/$name.json');
  }
  
  // Cleanup resources
  void dispose() {
    _client.dispose();
  }
}
