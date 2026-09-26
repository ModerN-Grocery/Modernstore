import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

import '../../bloc/Orders/Get_All_Order/get_all_orders_bloc.dart';
import '../../repositery/api/User/getAllUsers_api.dart';
import '../../repositery/model/Orders/getAllOrders_model.dart';
import '../../repositery/model/login_model.dart';
import 'admin_order_details_page.dart';

/// Unified model for a customer/user in the admin dashboard
class AdminCustomer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final List<Orders> orders;
  final List<String> addresses;
  final double totalSpent;
  final DateTime? joinedDate;
  final DateTime? lastOrderDate;

  AdminCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.role = 'customer',
    required this.orders,
    required this.addresses,
    required this.totalSpent,
    this.joinedDate,
    this.lastOrderDate,
  });

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == 'Unknown User' || trimmed == 'Customer') {
      return 'U';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class AdminCustomersPage extends StatefulWidget {
  final int? totalUsersCount;

  const AdminCustomersPage({super.key, this.totalUsersCount});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  final GetAllUsersApi _usersApi = GetAllUsersApi();

  String _selectedFilter = 'All'; // 'All', 'With Orders', 'No Orders', 'Repeat (2+)'
  bool _isExporting = false;
  bool _isLoadingBackendUsers = false;
  List<User>? _backendUsers;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // 1. Refresh orders from Bloc
    context.read<GetAllOrdersBloc>().add(FetchGetAllOrders());

    // 2. Fetch all registered users from backend API if available
    _fetchBackendUsers();
  }

  Future<void> _fetchBackendUsers() async {
    setState(() => _isLoadingBackendUsers = true);
    try {
      final users = await _usersApi.getAllUsers();
      if (mounted) {
        setState(() {
          _backendUsers = users;
          _isLoadingBackendUsers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingBackendUsers = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA EXTRACTION & MERGING ---

  String _extractName(Orders order) {
    if (order.userId != null) {
      if (order.userId?.name != null &&
          order.userId!.name.toString().trim().isNotEmpty) {
        return order.userId!.name.toString().trim();
      }
      if (order.userId is Map) {
        final m = order.userId as Map;
        if (m['name'] != null && m['name'].toString().trim().isNotEmpty) {
          return m['name'].toString().trim();
        }
      }
    }
    if (order.shippingAddress is Map) {
      final m = order.shippingAddress as Map;
      if (m['name'] != null && m['name'].toString().trim().isNotEmpty) {
        return m['name'].toString().trim();
      }
    }
    return 'Customer';
  }

  String _extractPhone(Orders order) {
    if (order.userId is Map) {
      final m = order.userId as Map;
      if (m['phoneNumber'] != null &&
          m['phoneNumber'].toString().trim().isNotEmpty) {
        return m['phoneNumber'].toString().trim();
      }
    }
    try {
      final dynamic u = order.userId;
      if (u != null && u.phoneNumber != null) {
        final p = u.phoneNumber.toString().trim();
        if (p.isNotEmpty) return p;
      }
    } catch (_) {}

    if (order.shippingAddress is Map) {
      final m = order.shippingAddress as Map;
      if (m['phoneNumber'] != null &&
          m['phoneNumber'].toString().trim().isNotEmpty) {
        return m['phoneNumber'].toString().trim();
      }
      if (m['phone'] != null && m['phone'].toString().trim().isNotEmpty) {
        return m['phone'].toString().trim();
      }
    }
    return 'N/A';
  }

  String _extractEmail(Orders order) {
    if (order.userId != null) {
      if (order.userId?.email != null &&
          order.userId!.email.toString().trim().isNotEmpty) {
        return order.userId!.email.toString().trim();
      }
      if (order.userId is Map) {
        final m = order.userId as Map;
        if (m['email'] != null && m['email'].toString().trim().isNotEmpty) {
          return m['email'].toString().trim();
        }
      }
    }
    return 'N/A';
  }

  String _extractAddress(Orders order) {
    final sa = order.shippingAddress;
    if (sa == null) return 'N/A';
    if (sa is String && sa.trim().isNotEmpty) return sa.trim();
    if (sa is Map) {
      final addr = sa['address']?.toString().trim() ?? '';
      final city = sa['city']?.toString().trim() ?? '';
      final pincode = sa['pincode']?.toString().trim() ?? '';
      final parts = [addr, city, pincode].where((s) => s.isNotEmpty).toList();
      return parts.isNotEmpty ? parts.join(', ') : 'N/A';
    }
    return 'N/A';
  }

  List<AdminCustomer> _buildCustomersList(List<Orders> orders) {
    // 1. First, group orders by customer
    final Map<String, List<Orders>> ordersByUser = {};
    for (final order in orders) {
      String key = '';
      if (order.userId?.id != null && order.userId!.id!.isNotEmpty) {
        key = order.userId!.id!;
      } else if (order.userId is Map && (order.userId as Map)['_id'] != null) {
        key = (order.userId as Map)['_id'].toString();
      } else {
        final phone = _extractPhone(order);
        if (phone.isNotEmpty && phone != 'N/A') {
          key = phone;
        } else {
          key = order.id ?? UniqueKey().toString();
        }
      }
      ordersByUser.putIfAbsent(key, () => []).add(order);
    }

    final Map<String, AdminCustomer> customerMap = {};

    // 2. If we have all registered users from backend API:
    if (_backendUsers != null && _backendUsers!.isNotEmpty) {
      for (final user in _backendUsers!) {
        final userId = user.id ?? user.phoneNumber ?? UniqueKey().toString();
        final userOrders = ordersByUser[userId] ??
            (user.phoneNumber != null ? ordersByUser[user.phoneNumber] ?? [] : []);

        // Sort orders newest first
        userOrders.sort((a, b) {
          final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
          return db.compareTo(da);
        });

        double totalSpent = 0;
        final Set<String> addresses = {};
        for (final o in userOrders) {
          totalSpent += (o.finalAmount ?? 0).toDouble();
          final addr = _extractAddress(o);
          if (addr.isNotEmpty && addr != 'N/A') {
            addresses.add(addr);
          }
        }

        DateTime? lastDate;
        if (userOrders.isNotEmpty) {
          lastDate = DateTime.tryParse(userOrders.first.createdAt ?? '');
        }

        DateTime? joinedDate;
        if (user.createdAt != null) {
          joinedDate = DateTime.tryParse(user.createdAt!);
        }

        customerMap[userId] = AdminCustomer(
          id: userId,
          name: (user.name != null && user.name.toString().trim().isNotEmpty)
              ? user.name.toString().trim()
              : (user.phoneNumber != null ? 'User ${user.phoneNumber}' : 'Customer'),
          phone: user.phoneNumber ?? 'N/A',
          email: user.email?.toString() ?? 'N/A',
          role: user.role ?? 'customer',
          orders: userOrders,
          addresses: addresses.toList(),
          totalSpent: totalSpent,
          joinedDate: joinedDate,
          lastOrderDate: lastDate,
        );
      }
    } else {
      // 3. If backend users API not available yet, create from orders
      ordersByUser.forEach((key, userOrders) {
        userOrders.sort((a, b) {
          final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
          final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
          return db.compareTo(da);
        });

        String name = 'Customer';
        String phone = 'N/A';
        String email = 'N/A';
        final Set<String> addresses = {};
        double totalSpent = 0;

        for (final o in userOrders) {
          totalSpent += (o.finalAmount ?? 0).toDouble();
          if (name == 'Customer') {
            final n = _extractName(o);
            if (n.isNotEmpty && n != 'Customer') name = n;
          }
          if (phone == 'N/A') {
            final p = _extractPhone(o);
            if (p.isNotEmpty && p != 'N/A') phone = p;
          }
          if (email == 'N/A') {
            final e = _extractEmail(o);
            if (e.isNotEmpty && e != 'N/A') email = e;
          }
          final addr = _extractAddress(o);
          if (addr.isNotEmpty && addr != 'N/A') {
            addresses.add(addr);
          }
        }

        DateTime? lastDate;
        if (userOrders.isNotEmpty) {
          lastDate = DateTime.tryParse(userOrders.first.createdAt ?? '');
        }

        customerMap[key] = AdminCustomer(
          id: key,
          name: name,
          phone: phone,
          email: email,
          orders: userOrders,
          addresses: addresses.toList(),
          totalSpent: totalSpent,
          lastOrderDate: lastDate,
        );
      });
    }

    final list = customerMap.values.toList();

    // Sort: users with recent orders or latest registrations first
    list.sort((a, b) {
      final da = a.lastOrderDate ?? a.joinedDate ?? DateTime(1970);
      final db = b.lastOrderDate ?? b.joinedDate ?? DateTime(1970);
      return db.compareTo(da);
    });

    return list;
  }

  List<AdminCustomer> _filterCustomers(List<AdminCustomer> customers) {
    final query = _searchController.text.trim().toLowerCase();

    return customers.where((c) {
      // 1. Text Search
      if (query.isNotEmpty) {
        final matchName = c.name.toLowerCase().contains(query);
        final matchPhone = c.phone.toLowerCase().contains(query);
        final matchEmail = c.email.toLowerCase().contains(query);
        final matchAddress =
            c.addresses.any((a) => a.toLowerCase().contains(query));

        if (!matchName && !matchPhone && !matchEmail && !matchAddress) {
          return false;
        }
      }

      // 2. Chip Filter
      if (_selectedFilter == 'With Orders') {
        return c.orders.isNotEmpty;
      } else if (_selectedFilter == 'No Orders') {
        return c.orders.isEmpty;
      } else if (_selectedFilter == 'Repeat (2+)') {
        return c.orders.length >= 2;
      }

      return true;
    }).toList();
  }

  // --- EXCEL EXPORT ---

  Future<void> _exportCustomersToExcel(List<AdminCustomer> customers) async {
    if (customers.isEmpty) {
      Fluttertoast.showToast(
        msg: "No users to export",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Users List';

      final xlsio.Style headerStyle = workbook.styles.add('CustomerHeaderStyle');
      headerStyle.backColor = '#1C1C1C';
      headerStyle.fontColor = '#F5E9B5';
      headerStyle.bold = true;
      headerStyle.fontSize = 11;
      headerStyle.fontName = 'Calibri';
      headerStyle.hAlign = xlsio.HAlignType.center;
      headerStyle.vAlign = xlsio.VAlignType.center;
      headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      headerStyle.borders.all.color = '#444444';

      final xlsio.Style textStyle = workbook.styles.add('CustomerTextStyle');
      textStyle.fontSize = 10;
      textStyle.fontName = 'Calibri';
      textStyle.vAlign = xlsio.VAlignType.center;
      textStyle.hAlign = xlsio.HAlignType.left;
      textStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      textStyle.borders.all.color = '#CCCCCC';

      final xlsio.Style centerStyle = workbook.styles.add('CustomerCenterStyle');
      centerStyle.fontSize = 10;
      centerStyle.fontName = 'Calibri';
      centerStyle.vAlign = xlsio.VAlignType.center;
      centerStyle.hAlign = xlsio.HAlignType.center;
      centerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      centerStyle.borders.all.color = '#CCCCCC';

      final headers = [
        'Sl No.',
        'User Name',
        'Phone Number',
        'Email Address',
        'Role',
        'Total Orders',
        'Total Spent (₹)',
        'Last Order Date',
        'Primary Address'
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.getRangeByIndex(1, i + 1);
        cell.setText(headers[i]);
        cell.cellStyle = headerStyle;
      }
      sheet.setRowHeightInPixels(1, 32);

      for (int i = 0; i < customers.length; i++) {
        final c = customers[i];
        final row = i + 2;

        sheet.getRangeByIndex(row, 1)
          ..setNumber(i + 1)
          ..cellStyle = centerStyle;

        sheet.getRangeByIndex(row, 2)
          ..setText(c.name)
          ..cellStyle = textStyle;

        sheet.getRangeByIndex(row, 3)
          ..setText(c.phone)
          ..cellStyle = centerStyle;

        sheet.getRangeByIndex(row, 4)
          ..setText(c.email)
          ..cellStyle = textStyle;

        sheet.getRangeByIndex(row, 5)
          ..setText(c.role)
          ..cellStyle = centerStyle;

        sheet.getRangeByIndex(row, 6)
          ..setNumber(c.orders.length.toDouble())
          ..cellStyle = centerStyle;

        sheet.getRangeByIndex(row, 7)
          ..setNumber(c.totalSpent)
          ..cellStyle = centerStyle;

        final dateStr = c.lastOrderDate != null
            ? "${c.lastOrderDate!.day.toString().padLeft(2, '0')}/${c.lastOrderDate!.month.toString().padLeft(2, '0')}/${c.lastOrderDate!.year}"
            : 'No orders yet';
        sheet.getRangeByIndex(row, 8)
          ..setText(dateStr)
          ..cellStyle = centerStyle;

        final addressStr = c.addresses.isNotEmpty ? c.addresses.first : 'N/A';
        sheet.getRangeByIndex(row, 9)
          ..setText(addressStr)
          ..cellStyle = textStyle;

        sheet.setRowHeightInPixels(row, 24);
      }

      for (int c = 1; c <= headers.length; c++) {
        sheet.autoFitColumn(c);
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final dateTag =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}";
      final filePath = '${directory.path}/ModernStore_Users_$dateTag.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        Fluttertoast.showToast(
          msg: "Users list exported successfully!",
          backgroundColor: const Color(0xFF1B5E20),
          textColor: Colors.white,
        );
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Failed to export Excel: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  // --- DETAIL BOTTOM SHEET ---

  void _showCustomerDetailSheet(BuildContext context, AdminCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.80,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      children: [
                        // User Profile Header
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36.r,
                                backgroundColor: const Color(0xFFF5E9B5),
                                child: Text(
                                  customer.initials,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                customer.name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.w, vertical: 3.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF262626),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Text(
                                  customer.role.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFF5E9B5),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Contact Details Card
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: const Color(0xFF333333)),
                          ),
                          child: Column(
                            children: [
                              // Phone Row
                              Row(
                                children: [
                                  Icon(Icons.phone,
                                      color: const Color(0xFFF5E9B5),
                                      size: 20.sp),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Phone Number',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                        Text(
                                          customer.phone,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (customer.phone != 'N/A')
                                    IconButton(
                                      icon: const Icon(Icons.copy,
                                          color: Color(0xFFF5E9B5), size: 18),
                                      tooltip: 'Copy Phone',
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: customer.phone));
                                        Fluttertoast.showToast(
                                          msg: "Phone number copied!",
                                          backgroundColor:
                                              const Color(0xFF2E7D32),
                                          textColor: Colors.white,
                                        );
                                      },
                                    ),
                                ],
                              ),
                              if (customer.email != 'N/A') ...[
                                const Divider(color: Colors.white12, height: 20),
                                // Email Row
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined,
                                        color: const Color(0xFFF5E9B5),
                                        size: 20.sp),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Email Address',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white54,
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                          Text(
                                            customer.email,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Orders Overview
                        Row(
                          children: [
                            Expanded(
                              child: _buildModalStatCard(
                                title: 'Total Orders',
                                value: customer.orders.length.toString(),
                                icon: Icons.shopping_bag_outlined,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildModalStatCard(
                                title: 'Total Spent',
                                value:
                                    '₹${customer.totalSpent.toStringAsFixed(0)}',
                                icon: Icons.currency_rupee,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // Addresses Section
                        if (customer.addresses.isNotEmpty) ...[
                          Text(
                            'Delivery Addresses',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFF5E9B5),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          ...customer.addresses.map(
                            (addr) => Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: const Color(0xFF2A2A2A)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      color: const Color(0xFFF5E9B5),
                                      size: 18.sp),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      addr,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],

                        // Orders List
                        Text(
                          'Order History (${customer.orders.length})',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFF5E9B5),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        if (customer.orders.isEmpty)
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Center(
                              child: Text(
                                'This user has not placed any orders yet.',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          )
                        else
                          ...customer.orders.map((order) {
                            final status = order.orderStatus ?? 'Pending';
                            final orderNo = order.orderNo ??
                                order.id?.substring(0, 8) ??
                                'N/A';
                            final dateStr = order.createdAt != null
                                ? _formatDate(order.createdAt)
                                : '';
                            final itemsCount = order.orderItems?.length ?? 0;

                            return Container(
                              margin: EdgeInsets.only(bottom: 10.h),
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12.r),
                                border:
                                    Border.all(color: const Color(0xFF2E2E2E)),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AdminOrderDetailsPage(order: order),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Order #$orderNo',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        _buildStatusBadge(status),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '$itemsCount items  •  $dateStr',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${order.finalAmount ?? 0}',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFFF5E9B5),
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(width: 4.w),
                                            Icon(
                                              Icons.chevron_right,
                                              color: Colors.white38,
                                              size: 18.sp,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFF5E9B5), size: 20.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        color = Colors.green;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      case 'OUT_FOR_DELIVERY':
      case 'SHIPPED':
        color = Colors.orange;
        break;
      default:
        color = Colors.amber;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  // --- MAIN BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFF0A0909),
      body: SafeArea(
        child: BlocBuilder<GetAllOrdersBloc, GetAllOrdersState>(
          builder: (context, state) {
            final orders = (state is GetAllOrdersLoaded)
                ? (state.getAllOrdersModel.orders ?? [])
                : <Orders>[];

            final allCustomers = _buildCustomersList(orders);
            final filteredCustomers = _filterCustomers(allCustomers);

            final totalRegisteredCount = widget.totalUsersCount ?? 16;
            final isWaitingForBackendEndpoint =
                _backendUsers == null && allCustomers.length < totalRegisteredCount;

            return RefreshIndicator(
              color: const Color(0xFFF5E9B5),
              backgroundColor: const Color(0xFF1C1C1C),
              onRefresh: () async {
                _loadData();
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      child: _buildHeader(
                        totalCount: totalRegisteredCount,
                        customersToExport: filteredCustomers,
                      ),
                    ),
                  ),

                  // Backend API Info Banner (shown if backend route is pending)
                  if (isWaitingForBackendEndpoint)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 6.h),
                        child: _buildBackendNoticeCard(
                          totalRegistered: totalRegisteredCount,
                          showingCount: allCustomers.length,
                        ),
                      ),
                    ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
                      child: _buildSearchBar(),
                    ),
                  ),

                  // Filter Chips
                  SliverToBoxAdapter(
                    child: _buildFilterChips(),
                  ),

                  // Users List
                  if (_isLoadingBackendUsers && allCustomers.isEmpty)
                    SliverToBoxAdapter(child: _buildShimmerLoading())
                  else if (filteredCustomers.isEmpty)
                    SliverToBoxAdapter(child: _buildEmptyState())
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final customer = filteredCustomers[index];
                            return _buildCustomerCard(customer);
                          },
                          childCount: filteredCustomers.length,
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required int totalCount,
    required List<AdminCustomer> customersToExport,
  }) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Row(
            children: [
              Text(
                'Customers',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E9B5),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '$totalCount',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Export Excel Action
        if (_isExporting)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: SizedBox(
              width: 20.w,
              height: 20.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF5E9B5),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: IconButton(
              icon: const Icon(Icons.file_download_outlined,
                  color: Color(0xFFF5E9B5)),
              tooltip: 'Export Users List to Excel',
              onPressed: () => _exportCustomersToExcel(customersToExport),
            ),
          ),

        SizedBox(width: 8.w),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFF333333)),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ),
      ],
    );
  }

  Widget _buildBackendNoticeCard({
    required int totalRegistered,
    required int showingCount,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1C12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF6B5824)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              color: const Color(0xFFF5E9B5), size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total $totalRegistered Registered Users',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFF5E9B5),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Currently showing $showingCount users with order activity. To load all $totalRegistered users (including new signups without orders), add the "GET /api/user/all" endpoint to your backend.',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14.sp),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search user by name, phone, email...',
          hintStyle:
              GoogleFonts.poppins(color: Colors.white38, fontSize: 13.sp),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFFF5E9B5), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'With Orders', 'No Orders', 'Repeat (2+)'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ChoiceChip(
              label: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFF5E9B5),
              backgroundColor: const Color(0xFF1C1C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFF5E9B5)
                      : const Color(0xFF333333),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- USER CENTRIC CARD ---
  Widget _buildCustomerCard(AdminCustomer customer) {
    final hasOrders = customer.orders.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _showCustomerDetailSheet(context, customer),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // User Avatar Circle
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: Text(
                    customer.initials,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFF5E9B5),
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),

                // User Info Details (User-First)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Name + Role Tag
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: hasOrders
                                  ? const Color(0xFF1E3320)
                                  : const Color(0xFF282828),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: hasOrders
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF444444),
                              ),
                            ),
                            child: Text(
                              hasOrders
                                  ? '${customer.orders.length} ${customer.orders.length == 1 ? "Order" : "Orders"}'
                                  : 'No orders',
                              style: GoogleFonts.poppins(
                                color: hasOrders
                                    ? const Color(0xFF81C784)
                                    : Colors.white54,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // Phone Number
                      if (customer.phone != 'N/A')
                        Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                color: const Color(0xFFF5E9B5), size: 13.sp),
                            SizedBox(width: 4.w),
                            Text(
                              customer.phone,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),

                      // Email
                      if (customer.email != 'N/A') ...[
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(Icons.email_outlined,
                                color: Colors.white54, size: 12.sp),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                customer.email,
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (hasOrders) ...[
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              'Total Spent: ₹${customer.totalSpent.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFF5E9B5),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (customer.lastOrderDate != null) ...[
                              SizedBox(width: 8.w),
                              Text(
                                '• Last: ${_formatDate(customer.lastOrderDate!.toIso8601String())}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(width: 6.w),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 20.w),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.person_search_outlined,
                size: 64.sp, color: Colors.white24),
            SizedBox(height: 16.h),
            Text(
              'No Users Found',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No user matched "${_searchController.text}"'
                  : 'No users available for the selected filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Column(
          children: List.generate(
            5,
            (index) => Container(
              height: 80.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
