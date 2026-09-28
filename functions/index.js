const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
setGlobalOptions({ maxInstances: 10 });

/**
 * Firebase Callable Cloud Function: sendOrderNotificationToAdmin
 *
 * Called from Flutter app after order created.
 * Sends FCM notification to all admin devices on 'admin_orders' topic.
 */
exports.sendOrderNotificationToAdmin = onCall(
  { region: "asia-south1" },
  async (request) => {
    const { orderId, orderNo, totalAmount, customerName } = request.data;

    if (!orderId || !orderNo) {
      throw new HttpsError("invalid-argument", "orderId and orderNo are required.");
    }

    const message = {
      topic: "admin_orders",
      notification: {
        title: "New Order Received!",
        body: "Order " + orderNo + " - Rs." + (totalAmount ?? 0) + " from " + (customerName ?? "Customer"),
      },
      data: {
        type: "new_order",
        orderId: orderId.toString(),
        orderNo: orderNo.toString(),
        totalAmount: (totalAmount ?? 0).toString(),
        customerName: (customerName ?? "").toString(),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "order_channel",
          sound: "order_sound",
          defaultVibrateTimings: false,
          vibrateTimingsMillis: [0, 500, 200, 500, 200, 500],
          color: "#4CAF50",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "order_sound.aiff",
            badge: 1,
          },
        },
      },
    };

    try {
      const response = await getMessaging().send(message);
      console.log("Notification sent:", response);
      return { success: true, messageId: response };
    } catch (error) {
      console.error("FCM error:", error);
      throw new HttpsError("internal", "Failed to send notification: " + error.message);
    }
  }
);
