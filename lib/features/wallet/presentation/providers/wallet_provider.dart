import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/wallet_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.read(apiClientProvider));
});

class WalletState {
  final double balance;
  final String currency;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<dynamic> transactions;

  WalletState({
    this.balance = 0.0,
    this.currency = 'XOF',
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.transactions = const [],
  });

  WalletState copyWith({
    double? balance,
    String? currency,
    bool? isLoading,
    String? error,
    String? successMessage,
    List<dynamic>? transactions,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repository;

  WalletNotifier(this._repository) : super(WalletState()) {
    fetchBalance();
    fetchTransactions();
  }

  Future<void> fetchBalance() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.getBalance();
      state = state.copyWith(
        balance: (data['balance'] as num).toDouble(),
        currency: data['currency'] ?? 'XOF',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur lors du chargement du solde.');
    }
  }

  Future<void> fetchTransactions() async {
    try {
      final list = await _repository.getTransactions();
      state = state.copyWith(transactions: list);
    } catch (e) {
      print('Erreur lors du chargement des transactions : $e');
    }
  }

  Future<void> deposit(double amount, String phone) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _repository.deposit(amount, phone);
      state = state.copyWith(
        balance: (data['balance'] as num).toDouble(),
        isLoading: false,
        successMessage: data['message'] ?? 'Dépôt effectué avec succès !',
      );
      await fetchTransactions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Échec du dépôt Mobile Money.');
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.read(walletRepositoryProvider));
});
