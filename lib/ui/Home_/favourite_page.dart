import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modern_grocery/bloc/wishList/GetToWishlist_bloc/get_to_wishlist_bloc.dart';
import 'package:modern_grocery/bloc/wishList/remove%20towish/removetowishlist_bloc.dart';
import 'package:modern_grocery/repositery/model/Wishlist/getToWishlist_model.dart';
import 'package:modern_grocery/services/language_service.dart';
import 'package:modern_grocery/ui/bottom_navigationbar.dart';
import 'package:modern_grocery/ui/cart_/success_cart.dart';
import 'package:modern_grocery/widgets/app_color.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../bloc/cart_/addCart_bloc/add_cart_bloc.dart';
import '../../localization/app_localizations.dart';
import '../../widgets/utils.dart';

class FavouritePage extends StatefulWidget {
  final VoidCallback? onFavTap;

  const FavouritePage({super.key, this.onFavTap});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage>
    with AutomaticKeepAliveClientMixin {
  late GetToWishlistModel data;
  bool _isLoading = false;
  final Set<String> _selectedItems = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    BlocProvider.of<GetToWishlistBloc>(context).add(fetchGetToWishlistEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
              final lang = languageService.currentLanguage;
        return BlocListener<AddCartBloc, AddCartState>(
          listener: (context, state) {

 if (state is AddCartLoading) {
              setState(() {
                _isLoading = true;
              });
            }
            if (state is AddCartLoaded) {
              if (state.response.success) {
                setState(() {
                  _isLoading = false;
                });
                // ✅ Show success screen and pop back
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SuccessCart()),
                );
                Future.delayed(const Duration(seconds: 2), () {
                  Navigator.of(context).pop();
                });
              } else {
                Utils.showToast(
                  state.response.message.isNotEmpty
                      ? state.response.message
                      : AppLocalizations.getString(
                          'failed_add_to_cart',
                          lang,
                        ),
                );
              }
            } else if (state is AddCartError) {
               setState(() {
                  _isLoading = false;
                });
              Utils.showToast('Add to cart failed: ${state.message}');
            }


            // TODO: implement listener
          },
          child: Scaffold(
            backgroundColor: Color(0XFF0A0909),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  SizedBox(height: 64.h),
                  Row(
                    children: [
                      // SizedBox(width: 24.w),
                      BackButton(
                        color: appColor.primaryText,
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NavigationBarWidget(initialIndex: 0,),
                            ),
                          );
                        },
                      ),
                      Spacer(),
                      Center(
                        child: Text(
                          languageService.getString('favorites'),
                          style: GoogleFonts.poppins(
                            color: appColor.primaryText,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.24,
                          ),
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          size: 22.sp,
                          color: appColor.primaryText,
                        ),
                        onPressed: () {
                          if (widget.onFavTap != null) {
                            widget.onFavTap!();
                          }
                        },
                      ),
                      // SizedBox(width: 24.w),
                    ],
                  ),
                  SizedBox(height: 9.h),
                  SizedBox(height: 16.h),
                  BlocBuilder<GetToWishlistBloc, GetToWishlistState>(
                      builder: (context, state) {
                    if (state is GetToWishlistLoading) {
                      return Expanded(
                        child: Column(
                          children: List.generate(5, (index) => buildShimmer()),
                        ),
                      );
                    }
                    if (state is GetToWishlistError) {
                      return Center(
                          child: Text(languageService.getString('error')));
                    }

                    if (state is GetToWishlistLoaded) {
                      final favourites =
                          BlocProvider.of<GetToWishlistBloc>(context)
                              .getToWishlistModel;
                      final wishlistItems = favourites.wishlists ?? [];

                      if (wishlistItems.isEmpty) {
                        return Center(
                          child: Text(
                            languageService.getString('no_favorites'),
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        );
                      }

                      final allProductIds = wishlistItems
                          .map((e) => e.productId?.id)
                          .where((id) => id != null)
                          .cast<String>()
                          .toSet();
                      final bool isAllSelected = allProductIds.isNotEmpty &&
                          _selectedItems.containsAll(allProductIds);

                      return Expanded(
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(6.r),
                                    onTap: () {
                                      setState(() {
                                        if (isAllSelected) {
                                          _selectedItems.clear();
                                        } else {
                                          _selectedItems.addAll(allProductIds);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 4.w, vertical: 4.h),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 20.w,
                                            height: 20.w,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                              border: Border.all(
                                                color: isAllSelected
                                                    ? const Color(0xFFF5E9B5)
                                                    : const Color(0xCEB4B2A9),
                                                width: 1.5,
                                              ),
                                              color: isAllSelected
                                                  ? const Color(0xFFF5E9B5)
                                                  : Colors.transparent,
                                            ),
                                            child: isAllSelected
                                                ? const Icon(Icons.check,
                                                    size: 15,
                                                    color: Colors.black)
                                                : null,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(
                                            isAllSelected
                                                ? languageService
                                                    .getString('deselect_all')
                                                : languageService
                                                    .getString('select_all'),
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFFFCF8E8),
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_selectedItems.isNotEmpty)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10.w, vertical: 3.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5E9B5)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      child: Text(
                                        '${_selectedItems.length} ${languageService.getString('items_selected')}',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFF5E9B5),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: wishlistItems.length,
                                itemBuilder: (context, index) {
                                  final item = wishlistItems[index];
                                  return FavouriteItemCard(
                                    item: item.toJson(),
                                    languageService: languageService,
                                    isSelected: _selectedItems.contains(
                                        item.productId?.id), // Check if item is selected
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedItems.add(item.productId!.id!);
                                        } else {
                                          _selectedItems.remove(item.productId!.id!);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ),

                            /// ✅ Button only shows if wishlist has items
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: SizedBox(
                                height: 48.h,
                                width: 380.w,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedItems.isEmpty
                                        ? const Color(0x40F5E9B5)
                                        : const Color(0xffF5E9B5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ), // Disable button if no items are selected or if loading
                                  onPressed:
                                      _selectedItems.isEmpty || _isLoading
                                          ? null
                                          : () {
                                              for (var productId
                                                  in _selectedItems) {
                                                context.read<AddCartBloc>().add(
                                                    FetchAddCart(
                                                        productId: productId,
                                                        quantity: 1));
                                              }
                                            },
                                  child: Center(
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : Text(
                                            _selectedItems.isEmpty
                                                ? languageService
                                                    .getString('add_to_cart')
                                                : '${languageService.getString('add_to_cart')} (${_selectedItems.length})',
                                            style: GoogleFonts.poppins(
                                              color: _selectedItems.isEmpty
                                                  ? Colors.white38
                                                  : Colors.black,
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container();
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FavouriteItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final LanguageService languageService;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const FavouriteItemCard({
    super.key,
    required this.item,
    required this.languageService,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<FavouriteItemCard> createState() => _FavouriteItemCardState();
}

class _FavouriteItemCardState extends State<FavouriteItemCard> {
  @override
  Widget build(BuildContext context) {
    final product = widget.item['productId'];
    if (product == null) {
      return const SizedBox.shrink();
    }

    final String name =
        product['name'] ?? widget.languageService.getString('no_name');
    final List<String> images =
        product['images'] != null ? List<String>.from(product['images']) : [];
    final String imageUrl = images.isNotEmpty ? images.first : '';
    final int basePrice = product['basePrice'] ?? 0;
    final int discountPercentage = product['discountPercentage'] ?? 0;
    final int discountedPrice =
        basePrice - (basePrice * discountPercentage / 100).round();

    return GestureDetector(
      onTap: () {
        widget.onSelected(!widget.isSelected);
      },
      child: Container(
        height: 113.h,
        margin: EdgeInsets.symmetric(
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF161514)
              : const Color(0xFF0A0808),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: widget.isSelected
                ? const Color(0xFFF5E9B5)
                : const Color(0x38FCF8E8),
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 121.w,
              height: 113.h,
              decoration: BoxDecoration(
                color: const Color(0xF4CCC9BC),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Center(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                            width: 120.w,
                            height: 80.h,
                            memCacheWidth: 250,
                            memCacheHeight: 250,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(color: Colors.grey[800]),
                            ),
                            errorWidget: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported,
                                  color: Colors.grey);
                            },
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: GestureDetector(
                      onTap: () {
                        widget.onSelected(!widget.isSelected);
                      },
                      child: Container(
                        height: 24.w,
                        width: 24.w,
                        decoration: BoxDecoration(
                          color: widget.isSelected
                              ? const Color(0xFFF5E9B5)
                              : Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isSelected
                                ? const Color(0xFFF5E9B5)
                                : Colors.white70,
                            width: 1.5,
                          ),
                        ),
                        child: widget.isSelected
                            ? Icon(Icons.check,
                                size: 16.sp, color: Colors.black)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 18.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFCF8E8),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Text(
                        '${widget.languageService.getString('mrp')} ₹$basePrice',
                        style: GoogleFonts.poppins(
                          color: const Color(0xCEB4B2A9),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: const Color(0xCEB4B2A9),
                          decorationThickness: 1.5,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        '₹${discountedPrice.toString()}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFCF8E8),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (discountPercentage > 0)
                    Text(
                      '$discountPercentage% ${widget.languageService.getString('discount_20_off').split(' ').last}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xCE7FFC83),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () {
                        final productId = widget.item['productId'];
                        final id = productId?['_id'];
                        if (id != null) {
                          context
                              .read<RemovetowishlistBloc>()
                              .add(fetchRemovetowishlistEvent(id));
                          Future.delayed(const Duration(milliseconds: 300), () {
                            context
                                .read<GetToWishlistBloc>()
                                .add(fetchGetToWishlistEvent());
                          });
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 6.h),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        widget.languageService.getString('remove'),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[900]!,
    highlightColor: Colors.grey[700]!,
    child: Container(
      height: 113.w,
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0808),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            color: Colors.grey[800],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  color: Colors.grey[800],
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 14,
                  width: 100.w,
                  color: Colors.grey[800],
                ),
                SizedBox(height: 8.h),
                Container(
                  height: 14,
                  width: 50.w,
                  color: Colors.grey[800],
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Container(
            width: 24,
            height: 24,
            color: Colors.grey[800],
          ),
        ],
      ),
    ),
  );
}
