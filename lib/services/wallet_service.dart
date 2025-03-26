import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/wallet.dart';
import '../models/token.dart';
import '../models/transaction.dart';
import 'web3_service.dart';

class WalletService extends ChangeNotifier {
  final Web3Service _web3Service = Web3Service();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _walletKey = 'wallet_data';
  static const String _tokenListKey = 'token_list';
  static const String _transactionListKey = 'transaction_list';
  
  Wallet? _currentWallet;
  List<Token> _tokens = [];
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  
  WalletService() {
    _loadWallet();
  }
  
  Wallet? get currentWallet => _currentWallet;
  List<Token> get tokens => _tokens;
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get hasWallet => _currentWallet != null;
  
  // Load wallet from secure storage
  Future<void> _loadWallet() async {
    _setLoading(true);
    try {
      final walletJson = await _secureStorage.read(key: _walletKey);
      if (walletJson != null) {
        _currentWallet = Wallet.fromJson(jsonDecode(walletJson));
        await _loadTokens();
        await _loadTransactions();
        await refreshWalletBalance();
      }
    } catch (e) {
      debugPrint('Error loading wallet: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Create a new wallet
  Future<void> createWallet() async {
    _setLoading(true);
    try {
      final wallet = await _web3Service.createWallet();
      await _saveWallet(wallet);
      _currentWallet = wallet;
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating wallet: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Import wallet from mnemonic
  Future<void> importWalletFromMnemonic(String mnemonic) async {
    _setLoading(true);
    try {
      final wallet = await _web3Service.importWalletFromMnemonic(mnemonic);
      await _saveWallet(wallet);
      _currentWallet = wallet;
      await refreshWalletBalance();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing wallet from mnemonic: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Import wallet from private key
  Future<void> importWalletFromPrivateKey(String privateKey) async {
    _setLoading(true);
    try {
      final wallet = await _web3Service.importWalletFromPrivateKey(privateKey);
      await _saveWallet(wallet);
      _currentWallet = wallet;
      await refreshWalletBalance();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing wallet from private key: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Refresh wallet balance
  Future<void> refreshWalletBalance() async {
    if (_currentWallet == null) return;
    
    _setLoading(true);
    try {
      final nativeBalance = await _web3Service.getNativeBalance(_currentWallet!.address);
      
      // Update token balances
      Map<String, BigInt> updatedBalances = {};
      for (final tokenAddress in _currentWallet!.tokenAddresses) {
        final balance = await _web3Service.getTokenBalance(
          tokenAddress,
          _currentWallet!.address,
        );
        updatedBalances[tokenAddress] = balance;
      }
      
      // Create updated wallet
      final updatedWallet = Wallet(
        address: _currentWallet!.address,
        privateKey: _currentWallet!.privateKey,
        publicKey: _currentWallet!.publicKey,
        mnemonic: _currentWallet!.mnemonic,
        tokenAddresses: _currentWallet!.tokenAddresses,
        balances: updatedBalances,
        nativeBalance: nativeBalance,
      );
      
      await _saveWallet(updatedWallet);
      _currentWallet = updatedWallet;
      await _refreshTokenDetails();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing wallet: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Add a token to the wallet
  Future<void> addToken(String tokenAddress) async {
    if (_currentWallet == null) return;
    if (_currentWallet!.tokenAddresses.contains(tokenAddress)) return;
    
    _setLoading(true);
    try {
      // Get token details first to validate it's a real token
      final token = await _web3Service.getTokenDetails(
        tokenAddress,
        _currentWallet!.address,
      );
      
      // Add token to the wallet
      final List<String> updatedTokenAddresses = List.from(_currentWallet!.tokenAddresses)
        ..add(tokenAddress);
      
      // Update balances
      final Map<String, BigInt> updatedBalances = Map.from(_currentWallet!.balances)
        ..addAll({tokenAddress: token.balance});
      
      // Create updated wallet
      final updatedWallet = Wallet(
        address: _currentWallet!.address,
        privateKey: _currentWallet!.privateKey,
        publicKey: _currentWallet!.publicKey,
        mnemonic: _currentWallet!.mnemonic,
        tokenAddresses: updatedTokenAddresses,
        balances: updatedBalances,
        nativeBalance: _currentWallet!.nativeBalance,
      );
      
      await _saveWallet(updatedWallet);
      _currentWallet = updatedWallet;
      
      // Add to token list
      _tokens.add(token);
      await _saveTokens();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding token: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Create new token
  Future<Token> createToken({
    required String name,
    required String symbol,
    required BigInt totalSupply,
    required BigInt decimals,
  }) async {
    if (_currentWallet == null) {
      throw Exception('No wallet available');
    }
    
    _setLoading(true);
    try {
      final tokenAddress = await _web3Service.createToken(
        name: name,
        symbol: symbol,
        totalSupply: totalSupply,
        decimals: decimals,
        wallet: _currentWallet!,
      );
      
      // Add the token to the wallet
      await addToken(tokenAddress);
      
      // Get token details
      final token = await _web3Service.getTokenDetails(
        tokenAddress,
        _currentWallet!.address,
      );
      
      // Add to recent transactions
      final transaction = Transaction(
        hash: tokenAddress, // Using token address as a placeholder
        from: _currentWallet!.address,
        to: tokenAddress,
        value: totalSupply,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        blockNumber: 0, // Placeholder
        type: TransactionType.createToken,
        status: TransactionStatus.confirmed,
        gasUsed: 0, // Placeholder
        gasPrice: BigInt.zero, // Placeholder
        tokenSymbol: symbol,
        contractAddress: tokenAddress,
      );
      
      _transactions.insert(0, transaction);
      await _saveTransactions();
      
      notifyListeners();
      return token;
    } catch (e) {
      debugPrint('Error creating token: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Lock tokens
  Future<String> lockTokens({
    required String tokenAddress,
    required BigInt amount,
    required int unlockTime,
  }) async {
    if (_currentWallet == null) {
      throw Exception('No wallet available');
    }
    
    _setLoading(true);
    try {
      final txHash = await _web3Service.lockTokens(
        tokenAddress: tokenAddress,
        amount: amount,
        unlockTime: unlockTime,
        wallet: _currentWallet!,
      );
      
      // Add to recent transactions
      final transaction = Transaction(
        hash: txHash,
        from: _currentWallet!.address,
        to: tokenAddress,
        value: amount,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        blockNumber: 0, // Will be updated later
        type: TransactionType.lockToken,
        status: TransactionStatus.pending,
        gasUsed: 0, // Will be updated later
        gasPrice: BigInt.zero, // Will be updated later
        tokenSymbol: _tokens.firstWhere((t) => t.address == tokenAddress).symbol,
        contractAddress: tokenAddress,
      );
      
      _transactions.insert(0, transaction);
      await _saveTransactions();
      
      notifyListeners();
      return txHash;
    } catch (e) {
      debugPrint('Error locking tokens: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Create vesting schedule
  Future<String> createVesting({
    required String tokenAddress,
    required String beneficiary,
    required BigInt amount,
    required int startTime,
    required int cliffDuration,
    required int duration,
  }) async {
    if (_currentWallet == null) {
      throw Exception('No wallet available');
    }
    
    _setLoading(true);
    try {
      final txHash = await _web3Service.createVesting(
        tokenAddress: tokenAddress,
        beneficiary: beneficiary,
        amount: amount,
        startTime: startTime,
        cliffDuration: cliffDuration,
        duration: duration,
        wallet: _currentWallet!,
      );
      
      // Add to recent transactions
      final transaction = Transaction(
        hash: txHash,
        from: _currentWallet!.address,
        to: beneficiary,
        value: amount,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        blockNumber: 0, // Will be updated later
        type: TransactionType.createVesting,
        status: TransactionStatus.pending,
        gasUsed: 0, // Will be updated later
        gasPrice: BigInt.zero, // Will be updated later
        tokenSymbol: _tokens.firstWhere((t) => t.address == tokenAddress).symbol,
        contractAddress: tokenAddress,
      );
      
      _transactions.insert(0, transaction);
      await _saveTransactions();
      
      notifyListeners();
      return txHash;
    } catch (e) {
      debugPrint('Error creating vesting: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Claim vested tokens
  Future<String> claimVestedTokens(String vestingContractAddress) async {
    if (_currentWallet == null) {
      throw Exception('No wallet available');
    }
    
    _setLoading(true);
    try {
      final txHash = await _web3Service.claimVestedTokens(
        vestingContractAddress: vestingContractAddress,
        wallet: _currentWallet!,
      );
      
      // Add to recent transactions
      final transaction = Transaction(
        hash: txHash,
        from: vestingContractAddress,
        to: _currentWallet!.address,
        value: BigInt.zero, // Not known at this point
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        blockNumber: 0, // Will be updated later
        type: TransactionType.claimVesting,
        status: TransactionStatus.pending,
        gasUsed: 0, // Will be updated later
        gasPrice: BigInt.zero, // Will be updated later
        contractAddress: vestingContractAddress,
      );
      
      _transactions.insert(0, transaction);
      await _saveTransactions();
      
      notifyListeners();
      return txHash;
    } catch (e) {
      debugPrint('Error claiming vested tokens: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update transaction status
  Future<void> updateTransactionStatus(String txHash) async {
    final index = _transactions.indexWhere((tx) => tx.hash == txHash);
    if (index == -1) return;
    
    try {
      final status = await _web3Service.getTransactionStatus(txHash);
      final updatedTx = Transaction(
        hash: _transactions[index].hash,
        from: _transactions[index].from,
        to: _transactions[index].to,
        value: _transactions[index].value,
        timestamp: _transactions[index].timestamp,
        blockNumber: _transactions[index].blockNumber,
        type: _transactions[index].type,
        status: status,
        gasUsed: _transactions[index].gasUsed,
        gasPrice: _transactions[index].gasPrice,
        tokenSymbol: _transactions[index].tokenSymbol,
        contractAddress: _transactions[index].contractAddress,
      );
      
      _transactions[index] = updatedTx;
      await _saveTransactions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating transaction status: $e');
    }
  }
  
  // Save wallet to secure storage
  Future<void> _saveWallet(Wallet wallet) async {
    await _secureStorage.write(key: _walletKey, value: jsonEncode(wallet.toJson()));
  }
  
  // Load tokens from local storage
  Future<void> _loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenListJson = prefs.getString(_tokenListKey);
      if (tokenListJson != null) {
        final List<dynamic> tokenList = jsonDecode(tokenListJson);
        _tokens = tokenList.map((item) => Token.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading tokens: $e');
    }
  }
  
  // Save tokens to local storage
  Future<void> _saveTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenListKey, jsonEncode(_tokens.map((t) => t.toJson()).toList()));
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }
  
  // Load transactions from local storage
  Future<void> _loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final txListJson = prefs.getString(_transactionListKey);
      if (txListJson != null) {
        final List<dynamic> txList = jsonDecode(txListJson);
        _transactions = txList.map((item) => Transaction.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }
  
  // Save transactions to local storage
  Future<void> _saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _transactionListKey, 
        jsonEncode(_transactions.map((t) => t.toJson()).toList())
      );
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }
  
  // Refresh token details
  Future<void> _refreshTokenDetails() async {
    if (_currentWallet == null) return;
    
    try {
      List<Token> updatedTokens = [];
      for (final tokenAddress in _currentWallet!.tokenAddresses) {
        final token = await _web3Service.getTokenDetails(
          tokenAddress,
          _currentWallet!.address,
        );
        updatedTokens.add(token);
      }
      
      _tokens = updatedTokens;
      await _saveTokens();
    } catch (e) {
      debugPrint('Error refreshing token details: $e');
    }
  }
  
  // Update loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
