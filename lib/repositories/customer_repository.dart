import 'package:hive/hive.dart';

import '../hive/hive_boxes.dart';
import '../models/customer.dart';

class CustomerRepository {
  final Box<Customer> _box = Hive.box<Customer>(HiveBoxes.customerBox);

  /// ============================
  /// Lấy tất cả khách hàng
  /// ============================
  List<Customer> getAll() {
    final customers = _box.values.toList();

    customers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return customers;
  }

  /// ============================
  /// Lấy theo ID
  /// ============================
  Customer? getById(String id) {
    try {
      return _box.values.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// ============================
  /// Thêm khách hàng
  /// ============================
  Future<Customer> add({
    required String name,
    required String phone,
    String note = "",
  }) async {
    final customer = Customer(
      id: _generateId(),
      name: name.trim(),
      phone: phone.trim(),
      note: note.trim(),
      createdAt: DateTime.now(),
    );

    await _box.add(customer);

    return customer;
  }

  /// ============================
  /// Cập nhật
  /// ============================
  Future<void> update(Customer customer) async {
    await customer.save();
  }

  /// ============================
  /// Xóa
  /// ============================
  Future<void> delete(Customer customer) async {
    await customer.delete();
  }

  /// ============================
  /// Tìm kiếm
  /// ============================
  List<Customer> search(String keyword) {
    keyword = keyword.toLowerCase().trim();

    return _box.values.where((customer) {
      return customer.name.toLowerCase().contains(keyword) ||
          customer.phone.contains(keyword);
    }).toList();
  }

  /// ============================
  /// Kiểm tra SĐT tồn tại
  /// ============================
  bool phoneExists(String phone) {
    return _box.values.any((e) => e.phone.trim() == phone.trim());
  }

  /// ============================
  /// Tìm theo số điện thoại
  /// ============================
  Customer? findByPhone(String phone) {
    try {
      return _box.values.firstWhere((e) => e.phone.trim() == phone.trim());
    } catch (_) {
      return null;
    }
  }

  /// ============================
  /// Tạo hoặc lấy khách hàng
  /// ============================
  Future<Customer> getOrCreate({
    required String name,
    required String phone,
  }) async {
    final existed = findByPhone(phone);

    if (existed != null) {
      return existed;
    }

    return await add(name: name, phone: phone);
  }

  /// ============================
  /// Sinh ID
  /// CUS0001
  /// ============================
  String _generateId() {
    final count = _box.length + 1;

    return "CUS${count.toString().padLeft(4, '0')}";
  }
}
