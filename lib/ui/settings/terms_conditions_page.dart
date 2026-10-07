import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modern_grocery/services/language_service.dart';
import 'package:provider/provider.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

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
              languageService.getString('terms_conditions'),
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
                      Icons.description_outlined,
                      color: Color(0xFFF5E9B5),
                      size: 34,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text(
                    "Terms and Conditions",
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
                    "Modern Store • Last updated: October 2026",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFCF8E8).withValues(alpha: 0.6),
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  "By downloading, accessing, or placing orders on Modern Store, you agree to comply with and be bound by the following Terms and Conditions.",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFCF8E8),
                    fontSize: 14.sp,
                    height: 1.55,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildSectionCard(
                  number: "1",
                  title: "Eligibility & Account Verification",
                  items: [
                    "Users must be at least 18 years old or under parental guidance.",
                    "Accounts are authenticated using your mobile phone number via One-Time Password (OTP).",
                    "You are responsible for keeping your login credentials and mobile device secure.",
                  ],
                ),
                _buildSectionCard(
                  number: "2",
                  title: "Product Listings, Pricing & Freshness",
                  items: [
                    "All prices are quoted in Indian Rupees (INR) and are inclusive of applicable taxes.",
                    "Fresh items (vegetables, fruits, milk, bakery goods) are subject to natural variations in size, weight, and seasonal availability.",
                    "If an item is out of stock after ordering, our support team will notify you promptly to offer a replacement or adjust the bill.",
                  ],
                ),
                _buildSectionCard(
                  number: "3",
                  title: "Delivery & Fulfillment",
                  items: [
                    "Modern Store operates within designated delivery coverage areas in Puthuparamba, Kottakkal, and neighboring Malappuram areas.",
                    "Customers must provide an accurate address and be present to receive the order.",
                    "Delivery times are estimates and may vary slightly due to traffic, adverse weather, or high order volumes.",
                  ],
                ),
                _buildSectionCard(
                  number: "4",
                  title: "Cancellations, Returns & Refunds",
                  items: [
                    "Order Cancellations: Orders can be cancelled prior to dispatch from the store.",
                    "Inspection upon Delivery: Please inspect all items upon arrival. Any defective, damaged, or spoiled products should be reported within 24 hours.",
                    "Refunds: Approved refunds are processed promptly via the original payment mode or adjusted in cash on Cash on Delivery orders.",
                  ],
                ),
                _buildSectionCard(
                  number: "5",
                  title: "Payments",
                  items: [
                    "We support Cash on Delivery (COD) as well as available digital payment options.",
                    "For Cash on Delivery orders, you agree to pay the total invoiced amount upon order delivery.",
                  ],
                ),
                _buildSectionCard(
                  number: "6",
                  title: "Governing Law & Dispute Resolution",
                  items: [
                    "These Terms are governed by the laws of India.",
                    "Any disputes arising from the use of the app or services shall be subject to the jurisdiction of the competent courts in Malappuram, Kerala.",
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
                        "Customer Support & Contact",
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
