import '../../../../core/network/api_client.dart';

class WalletRepository {
  final ApiClient apiClient;

  WalletRepository(this.apiClient);

  Future<Map<String, dynamic>> getBalance() async {
    final response = await apiClient.dio.get('/wallet/balance');
    return response.data;
  }

  Future<Map<String, dynamic>> deposit(double amount, String phone) async {
    final response = await apiClient.dio.post('/wallet/deposit', data: {
      'amount': amount,
      'phone': phone,
    });
    return response.data;
  }

  Future<List<dynamic>> getTransactions() async {
    final response = await apiClient.dio.get('/wallet/transactions');
    return response.data as List<dynamic>;
  }
}
