import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../repositery/api/Orders/Create_order_Api.dart';
import '../../../repositery/model/Orders/createOrder_model.dart';
import '../../../services/notification_service.dart';

part 'create_order_event.dart';
part 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  final CreateOrderApi createOrderApi;

  CreateOrderBloc({required this.createOrderApi})
      : super(CreateOrderInitial()) {
    on<CreateOrderButtonPressed>(_onCreateOrder);
  }

  Future<void> _onCreateOrder(
    CreateOrderButtonPressed event,
    Emitter<CreateOrderState> emit,
  ) async {
    emit(CreateOrderLoading());

    try {
      // Order create - Node.js backend (no change)
      final response = await createOrderApi.createOrder(
        shippingAddress: event.shippingAddress,
        paymentMethod: event.paymentMethod,
        deliveryCharge: event.deliveryCharge,
      );

      if (response.success) {
        CreateOrderModel? createOrderModel;
        if (response.data != null && response.data is Map<String, dynamic>) {
          createOrderModel = CreateOrderModel.fromJson(response.data);
        }

        // Notification - Firebase FCM HTTP v1 API directly (no Node.js needed)
        _sendFirebaseNotificationToAdmin(createOrderModel);

        emit(CreateOrderSuccess(createOrderModel));
      } else {
        emit(CreateOrderFailure(
          response.message.isNotEmpty
              ? response.message
              : 'Order creation failed',
        ));
      }
    } catch (e) {
      emit(CreateOrderFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Send push notification to admin using Firebase FCM HTTP v1 API directly.
  /// - No Node.js changes needed
  /// - No Blaze plan needed
  /// - 100% Firebase
  Future<void> _sendFirebaseNotificationToAdmin(CreateOrderModel? order) async {
    try {
      final orderNo = order?.order?.orderNo ?? '';
      final totalAmount = order?.order?.finalAmount ?? 0;

      await FcmDirectService.instance.sendToAdminTopic(
        title: 'New Order Received!',
        body: 'Order $orderNo - Rs.$totalAmount',
        data: {
          'type': 'new_order',
          'orderId': order?.order?.id ?? '',
          'orderNo': orderNo,
          'amount': totalAmount.toString(),
        },
      );
    } catch (e) {
      // Non-critical - order is already created, notification failure is ok
      debugPrint('Notification failed (non-critical): $e');
    }
  }
}
