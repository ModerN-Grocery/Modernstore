import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modern_grocery/repositery/model/Orders/getAllOrders_model.dart';

import '../../bloc/Orders/Update order/update_order_status_bloc.dart';

class AdminOrderDetailsPage extends StatefulWidget {
  final Orders order;

  const AdminOrderDetailsPage({super.key, required this.order});

  @override
  State<AdminOrderDetailsPage> createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  late String currentStatus;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.order.orderStatus ?? "Pending";
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UpdateOrderStatusBloc(),
      child: BlocListener<UpdateOrderStatusBloc, UpdateOrderStatusState>(
        listener: (context, state) {
          if (state is UpdateOrderStatusSuccess) {
            Utils.showToast(state.message);
          } else if (state is UpdateOrderStatusFailure) {
            Utils.showToast(state.error);
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0XFF0A0909),
          appBar: AppBar(
            backgroundColor: const Color(0XFF0A0909),
            elevation: 0,
            leading: const BackButton(color: Color(0xffFCF8E8)),
            title: Text(
              "Order Details",
              style: GoogleFonts.poppins(
                color: const Color(0xFFFCF8E8),
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section (ID, Date, Status)
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow("Order ID",
                          widget.order.orderNo ?? widget.order.id?.substring(0, 8) ?? "N/A"),
                      SizedBox(height: 10.h),
                      _buildInfoRow("Date", _formatDate(widget.order.createdAt)),
                      SizedBox(height: 10.h),
                      _buildInfoRow("Customer", widget.order.userId?.name ?? "N/A"),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Status",
                            style: GoogleFonts.poppins(
                                color: Colors.white70, fontSize: 14.sp),
                          ),
                          Row(
                            children: [
                              _buildStatusBadge(currentStatus),
                              SizedBox(width: 8.w),
                              Builder(
                                builder: (context) {
                                  return GestureDetector(
                                    onTap: () => _showStatusChangeDialog(context),
                                    child: Icon(Icons.edit,
                                        color: Colors.white70, size: 20.sp),
                                  );
                                }
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Items Section
                Text(
                  "Items",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFCF8E8),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12.h),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.order.orderItems?.length ?? 0,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final item = widget.order.orderItems![index];
                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      child: InkWell(
                        onTap: () => _showProductDetailsDialog(context, item),
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Row(
                            children: [
                              if (item.productId?.images != null &&
                                  item.productId!.images!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6.r),
                                  child: Container(
                                    width: 44.w,
                                    height: 44.h,
                                    color: Colors.white10,
                                    child: Image.network(
                                      item.productId!.images!.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.white38,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Product : ${item.productId?.name ?? 'N/A'}",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 14.sp),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      "Qty: ${item.quantity}",
                                      style: GoogleFonts.poppins(
                                          color: Colors.white54, fontSize: 12.sp),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "₹${item.itemTotalAmount?.toStringAsFixed(2) ?? '0.00'}",
                                style: GoogleFonts.poppins(
                                    color: const Color(0xFFF5E9B5),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24.h),

                // Shipping & Payment
                _buildInfoRow(
                    "Address", _getAddressString(widget.order.shippingAddress)),
                SizedBox(height: 10.h),
                _buildInfoRow("Payment Method", widget.order.paymentMethod ?? "N/A"),

                SizedBox(height: 24.h),
                Divider(color: Colors.white24),
                SizedBox(height: 10.h),

                // Price Breakdown
                _buildInfoRow("Subtotal",
                    "₹${widget.order.itemsTotalAmount?.toStringAsFixed(2) ?? '0.00'}"),
                SizedBox(height: 12.h),
                _buildInfoRow(
                  "Grand Total",
                  "₹${((widget.order.itemsTotalAmount != null && widget.order.itemsTotalAmount! > 0) ? widget.order.itemsTotalAmount! : ((widget.order.finalAmount ?? 0) - (widget.order.deliveryCharge ?? 0))).toStringAsFixed(2)}",
                  isBold: true,
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAddressString(dynamic addressData) {
    if (addressData == null) return "N/A";
    if (addressData is String) return addressData;
    if (addressData is Map) {
      return addressData['address'] ?? "N/A";
    }
    return "N/A";
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(width: 120.w,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: isBold ? 16.sp : 14.sp,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              color: isBold ? const Color(0xFFF5E9B5) : Colors.white,
              fontSize: isBold ? 16.sp : 14.sp,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status.toLowerCase() == 'delivered'
        ? Colors.green
        : (status.toLowerCase().contains('cancel') ? Colors.red : Colors.orange);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color),
      ),
      child: Text(status,
          style: GoogleFonts.poppins(
              color: color, fontWeight: FontWeight.bold, fontSize: 12.sp)),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  void _showStatusChangeDialog(BuildContext context) {
    List<String> statuses = [];

    switch (currentStatus.toLowerCase()) {
      case 'pending':
      case 'order_placed':
        statuses = ['Confirmed'];
        break;
      case 'confirmed':
        statuses = ['Shipped'];
        break;
      case 'shipped':
        statuses = ['Out_for_Delivery'];
        break;
      case 'out_for_delivery':
        statuses = ['Delivered'];
        break;
    }

    if (statuses.isEmpty) {
      Utils.showToast('No further status updates allowed.');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Update Status",
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20.h),
              ...statuses.map((status) => ListTile(
                    title: Text(
                      status,
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    trailing: currentStatus == status
                        ? const Icon(Icons.check, color: Color(0xFFF5E9B5))
                        : null,
                    onTap: () {
                      context.read<UpdateOrderStatusBloc>().add(
                          UpdateOrderStatus(
                              orderId: widget.order.id!, status: status.toUpperCase()));
                      setState(() {
                        currentStatus = status;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showProductDetailsDialog(BuildContext context, OrderItems item) {
    final product = item.productId;
    final String productName = product?.name ?? 'N/A';
    final List<String> images = product?.images ?? [];
    final String? imageUrl = images.isNotEmpty ? images.first : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: const BorderSide(color: Colors.white12),
          ),
          contentPadding: EdgeInsets.all(16.w),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Product Details",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFCF8E8),
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                  ),
                  child: Icon(Icons.close, color: Colors.white70, size: 18.sp),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: double.infinity,
                    height: 180.h,
                    color: Colors.white.withOpacity(0.05),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFF5E9B5),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported_outlined,
                                      size: 40.sp, color: Colors.white38),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "No Image Available",
                                    style: GoogleFonts.poppins(
                                        color: Colors.white38, fontSize: 11.sp),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported_outlined,
                                    size: 40.sp, color: Colors.white38),
                                SizedBox(height: 6.h),
                                Text(
                                  "No Image Available",
                                  style: GoogleFonts.poppins(
                                      color: Colors.white38, fontSize: 11.sp),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Product Name
                Text(
                  productName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (product?.unit != null && product!.unit!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    "Unit: ${product.unit}",
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12.sp,
                    ),
                  ),
                ],

                SizedBox(height: 12.h),

                // Quantity and Total Price Box
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Ordered Qty:",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13.sp,
                            ),
                          ),
                          Text(
                            "${item.quantity ?? 1}",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (product?.basePrice != null) ...[
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Base Price / MRP:",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              "₹${product!.basePrice}",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (product?.discountPercentage != null &&
                          product!.discountPercentage! > 0) ...[
                        SizedBox(height: 6.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Discount:",
                              style: GoogleFonts.poppins(
                                color: Colors.greenAccent,
                                fontSize: 12.sp,
                              ),
                            ),
                            Text(
                              "${product!.discountPercentage}% OFF",
                              style: GoogleFonts.poppins(
                                color: Colors.greenAccent,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      Divider(color: Colors.white12, height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Item Total:",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "₹${item.itemTotalAmount?.toStringAsFixed(2) ?? '0.00'}",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFF5E9B5),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5E9B5),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  "Close",
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}