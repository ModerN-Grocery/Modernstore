import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:modern_grocery/repositery/api/login/login_api.dart';
import 'package:modern_grocery/repositery/model/login_model.dart';
import 'package:modern_grocery/services/notification_service.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  Loginapi loginapi = Loginapi();
  late Loginmodel login;

  LoginBloc() : super(LoginInitial()) {
    on<fetchlogin>((event, emit) async {
      emit(loginBlocLoading());
      print('Bloc  Loading successfully ..............');

      try {
        login = await loginapi.getLogin(phoneNumber: event.phoneNumber!, otp: event.otp!);

        // 🔔 Subscribe/unsubscribe from admin_orders topic based on role
        final role = login.user?.role ?? '';
        if (role == 'admin') {
          await NotificationService.instance.subscribeToAdminTopic();
          debugPrint('Admin logged in → subscribed to admin_orders');
        } else {
          await NotificationService.instance.unsubscribeFromAdminTopic();
          debugPrint('User logged in → unsubscribed from admin_orders');
        }

        emit(loginBlocLoaded(login: login));
        print('Bloc Loaded successfully ..............');
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        emit(loginBlocError());
      }
    });
  }
}
