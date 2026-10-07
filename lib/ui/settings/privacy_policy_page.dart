import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modern_grocery/services/language_service.dart';
import 'package:provider/provider.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0909),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0909),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFF5E9B5)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              languageService.getString('privacy_policy'),
              style: GoogleFonts.poppins(
                color: const Color(0xFFF5E9B5),
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141312),
                      border: Border.all(color: const Color(0xFFF5E9B5), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Color(0xFFF5E9B5),
                      size: 34,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    "Modern Store Privacy Policy",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFF5E9B5),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Center(
                  child: Text(
                    "Last updated: October 2026",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFCF8E8).withValues(alpha: 0.6),
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  "Modern Store is committed to protecting your privacy. This policy outlines how we collect, use, and protect your personal data when you use our grocery shopping and delivery app.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFCF8E8),
                    fontSize: 14.sp,
                    height: 1.55,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildSectionCard(
                  number: "1",
                  title: "Information We Collect",
                  items: [
                    "Phone Number: Collected as your primary account identifier for secure SMS OTP authentication.",
                    "Customer Name: Used to personalize invoices, account details, and delivery receipts.",
                    "Delivery Addresses & GPS: Street names, house numbers, and GPS pinpoints to enable delivery riders to reach your location accurately.",
                    "Order History: Items purchased, quantities, billing totals, and delivery timestamps.",
                    "Device & Push Tokens: Device model, OS version, and Firebase Cloud Messaging (FCM) token for real-time delivery tracking alerts.",
                  ],
                ),
                _buildSectionCard(
                  number: "2",
                  title: "How We Use Your Information",
                  items: [
                    "Account authentication and instant OTP verification.",
                    "Processing, packaging, and dispatching your grocery orders.",
                    "Coordinating with delivery drivers for doorstep delivery.",
                    "Real-time order status notifications (Order Placed, Out for Delivery, Completed).",
                    "Assisting with customer support queries, refunds, and replacements.",
                  ],
                ),
                _buildSectionCard(
                  number: "3",
                  title: "Data Sharing & Third Parties",
                  items: [
                    "We do not sell, rent, or trade your personal data to advertisers or third-party marketers.",
                    "Delivery Partners: We share only the recipient's name, phone number, and delivery address strictly for order drop-off.",
                    "Infrastructure Partners: Trusted service providers such as Firebase (Push Notifications) and SMS gateways.",
                    "Legal Authorities: Shared only when strictly required by applicable Indian law.",
                  ],
                ),
                _buildSectionCard(
                  number: "4",
                  title: "Device Permissions",
                  items: [
                    "Location: Used to pinpoint your delivery address on the map for accurate driver routing.",
                    "Camera & Photos: Used optionally when updating your profile photo or uploading product feedback.",
                    "Notifications: Used to deliver timely order status updates and delivery notices.",
                  ],
                ),
                _buildSectionCard(
                  number: "5",
                  title: "Data Security & Account Deletion",
                  items: [
                    "Network Security: All client-server communications are protected using secure HTTPS encryption.",
                    "Authentication: Secured with encrypted JSON Web Tokens (JWT).",
                    "Right to Delete: You have the right to request deletion of your account and personal data at any time under Profile settings or by emailing support.",
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141312),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFF5E9B5).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Contact & Grievance",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF5E9B5),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Modern Store (Modern Grocery)\nPuthuparamba Rd, Kottakkal, Puthuparambu Town, Malappuram, Kerala 676501, India\nPhone: +91 8139089227\nEmail: modernstoreputhupparamba@gmail.com",
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFCF8E8),
                          fontSize: 13.sp,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required List<String> items,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141312),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xffC4C1B4).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26.w,
                height: 26.w,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5E9B5),
                ),
                child: Text(
                  number,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFF5E9B5),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ",
                    style: TextStyle(
                      color: const Color(0xFFF5E9B5),
                      fontSize: 14.sp,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFCF8E8),
                        fontSize: 13.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
