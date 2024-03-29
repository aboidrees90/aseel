import 'dart:async';

import 'package:aseel/models/product_model.dart';
import 'package:aseel/pages/base.dart';
import 'package:aseel/providers/loader_provider.dart';
import 'package:aseel/providers/product_provider.dart';
import 'package:aseel/utils/enums.dart';
import 'package:aseel/utils/util.dart';
import 'package:aseel/widgets/widget_product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductsMenuPage extends BasePage {
  final int? categoryId;

  const ProductsMenuPage({super.key, this.categoryId});

  @override
  BasePageState<ProductsMenuPage> createState() => _ProductsMenuPageState();
}

class _ProductsMenuPageState extends BasePageState<ProductsMenuPage> {
  int _page = 1;
  final ScrollController _scrollController = ScrollController();
  final _searchQuery = TextEditingController();
  Timer? _debounce;
  final _sortByOptions = [
    SortBy("popularity", "الأكثر شعبية", "asc"),
    SortBy("modified", "الاحدث", "asc"),
    SortBy("price", "السعر: الأقيم إلى الارخص", "asc"),
    SortBy("price", "السعر: الارخص إلى الأقيم", "desc"),
  ];

  @override
  void initState() {
    var productController = Provider.of<ProductProvider>(context, listen: false);

    productController
      ..resetStream()
      ..setLoadingMoreStatus(LoadingStatus.initial)
      ..fetchProducts(
        _page,
        onCallback: () => Provider.of<LoaderProvider>(context, listen: false).setStatus(false),
      );

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        productController
          ..setLoadingMoreStatus(LoadingStatus.loading)
          ..fetchProducts(++_page);
      }
    });

    _searchQuery.addListener(() {
      if (_debounce != null && (_debounce?.isActive ?? false)) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        productController
          ..resetStream()
          ..setLoadingMoreStatus(LoadingStatus.initial)
          ..fetchProducts(_page, strSearch: _searchQuery.text);
      });
    });
    super.initState();
  }

  @override
  Widget pageUI() {
    return Column(
      children: [
        _productsFilter(),
        Flexible(child: Consumer<ProductProvider>(
          builder: (context, controller, child) {
            var noProductsCondition = controller.totalRecords == 0 && Utils.isStable(controller.loadingMoreStatus);
            var hasProductsCondition = controller.allProducts.isNotEmpty && !Utils.isInitial(controller.loadingMoreStatus);
            var isLoadingMoreCondition = Utils.isLoading(controller.loadingMoreStatus);

            if (noProductsCondition) return const Center(child: Text('No Products'));

            if (hasProductsCondition) {
              return _buildProductsList(controller.allProducts, isLoadingMoreCondition);
            }

            return const Center(child: CircularProgressIndicator());
          },
        )),
      ],
    );
  }

  Widget _buildProductsList(List<ProductModel> products, bool isLoadingMore) {
    return Column(
      children: [
        Flexible(
          child: GridView.count(
            shrinkWrap: false,
            crossAxisCount: 3,
            childAspectRatio: 0.76,
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            scrollDirection: Axis.vertical,
            children: products.map((product) => ProductCard(product: product)).toList(),
          ),
        ),
        Visibility(
          visible: isLoadingMore,
          child: Container(width: 50, height: 50, padding: const EdgeInsets.all(15), child: const CircularProgressIndicator()),
        )
      ],
    );
  }

  Widget _productsFilter() {
    return Container(
      height: 51,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 5),
      child: Row(
        children: [
          Flexible(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextFormField(
                controller: _searchQuery,
                decoration: InputDecoration(
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: const Icon(Icons.search_outlined),
                  hintText: "البحث عن منتج",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
                  fillColor: const Color(0xFFe6e6ec),
                  filled: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15.0),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFe6e6ec),
              borderRadius: BorderRadius.circular(9.0),
            ),
            child: PopupMenuButton(
              onSelected: (sortBy) => Provider.of<ProductProvider>(context, listen: false)
                ..resetStream()
                ..setSortOrder(sortBy)
                ..fetchProducts(_page),
              itemBuilder: (context) {
                return _sortByOptions.map((option) {
                  return PopupMenuItem(value: option, child: Text(option.text, textDirection: TextDirection.rtl));
                }).toList();
              },
            ),
          ),
        ],
      ),
    );
  }
}
