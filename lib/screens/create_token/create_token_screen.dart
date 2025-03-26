import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/wallet_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class CreateTokenScreen extends StatefulWidget {
  const CreateTokenScreen({super.key});

  @override
  State<CreateTokenScreen> createState() => _CreateTokenScreenState();
}

class _CreateTokenScreenState extends State<CreateTokenScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();
  final TextEditingController _totalSupplyController = TextEditingController();
  int _decimals = 18;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _totalSupplyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Token'),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                Text(
                  'Token Information',
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Token Name',
                  hintText: 'e.g., Moon Token',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Token name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _symbolController,
                  label: 'Token Symbol',
                  hintText: 'e.g., MOON',
                  maxLength: 8,
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Token symbol is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _totalSupplyController,
                  label: 'Total Supply',
                  hintText: 'e.g., 1000000',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Total supply is required';
                    }
                    
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Total supply must be a positive number';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDecimalSelector(),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Create Token',
                  onPressed: _isCreating ? null : _createToken,
                  isLoading: _isCreating,
                  type: ButtonType.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.infoColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.infoColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About Creating Tokens',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You are creating an ERC-20 compatible token on the Polygon network. This token can be used for various purposes like rewards, governance, or fundraising.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Creating a token requires a small amount of MATIC for gas fees.',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            counter: const SizedBox.shrink(),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.errorColor,
                width: 2,
              ),
            ),
          ),
          style: AppTheme.bodyLarge,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDecimalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Token Decimals',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _decimals.toString(),
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _decimals.toDouble(),
          min: 0,
          max: 18,
          divisions: 18,
          activeColor: AppTheme.primaryColor,
          inactiveColor: AppTheme.surfaceColor,
          onChanged: (value) {
            setState(() {
              _decimals = value.toInt();
            });
          },
        ),
        Text(
          'Standard ERC-20 tokens use 18 decimals. Only change this if you have a specific requirement.',
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _createToken() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isCreating = true;
      });

      try {
        final name = _nameController.text.trim();
        final symbol = _symbolController.text.trim().toUpperCase();
        final totalSupply = BigInt.parse(_totalSupplyController.text.trim()) * 
                            BigInt.from(10).pow(_decimals);
        
        final walletService = Provider.of<WalletService>(context, listen: false);
        
        final token = await walletService.createToken(
          name: name,
          symbol: symbol,
          totalSupply: totalSupply,
          decimals: BigInt.from(_decimals),
        );
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token $name created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate back to wallet screen
        Navigator.pop(context);
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating token: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isCreating = false;
          });
        }
      }
    }
  }
}
