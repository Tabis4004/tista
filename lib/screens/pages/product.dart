import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tista/providers/extension.dart';
import 'package:tista/providers/routing_config.dart';
import 'package:tista/providers/services.dart';
import 'package:tista/providers/theme.dart';
import 'package:tista/providers/utils.dart';
import '../../models/product.dart';
import '../widgets/header_page.dart';
import 'edit_product.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage>
    with AutomaticKeepAliveClientMixin {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  List<ProductModel> products = [];
  Stream<List<ProductModel>>? productStream;

  @override
  void initState() {
    super.initState();
    Services.instance.getProducts(company: appCode);
    initStream();
  }

  initStream() {
    productStream =
        Services.isar.productModels.where().watch(fireImmediately: true);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const HeaderPage("Nos produits")),
        body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
              leading: TextButton(
                  style: ButtonStyle(
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4))),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                      backgroundColor:
                          WidgetStateProperty.all(appSecondaryColor)),
                  child: const Text("Ajouter"),
                  onPressed: () {
                    navigateToBoard(context,
                        routeName: AppRouteConstants.editProduct,
                        page: const EditProduct(),
                        canBack: true);
                  })),
          Expanded(
              child: StreamBuilder(
                  stream: productStream,
                  builder: (cxt, snapshot) {
                    if ([ConnectionState.none, ConnectionState.waiting]
                        .contains(snapshot.connectionState)) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data == null || snapshot.hasError) {
                      return buildConnectionError(() {
                        setState(() {
                          initStream();
                        });
                      });
                    }
                    if (snapshot.data != null) products = snapshot.data!;
                    if (products.isEmpty) {
                      return const Center(
                          child: Text("Aucun produit",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 1),
                              textAlign: TextAlign.center));
                    }
                    return SmartRefresher(
                        enablePullDown: true,
                        physics: const BouncingScrollPhysics(),
                        header: const WaterDropHeader(
                            failed: Text("Chargement échoué",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            complete: Text("Products actualisées",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11))),
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                                padding: const EdgeInsets.all(14),
                                physics: const BouncingScrollPhysics(),
                                child: Table(
                                    defaultVerticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    columnWidths: const {
                                      0: FlexColumnWidth(),
                                      1: IntrinsicColumnWidth(),
                                      2: IntrinsicColumnWidth(),
                                      3: IntrinsicColumnWidth(),
                                      4: FixedColumnWidth(30)
                                    },
                                    children: _buildRow()))));
                  }))
        ]));
  }

  List<TableRow> _buildRow() {
    TextStyle style = const TextStyle(
        fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1);
    List<TableRow> rows = [];
    rows.add(TableRow(
        decoration: const BoxDecoration(color: Colors.grey),
        children: [
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Nom", style: style)),
          Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
              child: Text("Prix", style: style)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: Text("Stock", style: style),
          ),
          const SizedBox()
        ]));
    for (int i = 0, len = products.length; i < len; i++) {
      ProductModel product = products[i];
      rows.add(TableRow(
          decoration:
              BoxDecoration(color: i % 2 != 0 ? Colors.grey.shade200 : null),
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(product.name)),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(product.price?.currencyFormat() ?? '--')),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                child: Text(product.stock?.currencyFormat() ?? '--')),
            PopupMenuButton(
                icon: const Icon(Icons.more_horiz_outlined, size: 18),
                onSelected: (val) {
                  if (val == 'EDIT') {
                    navigateToBoard(context,
                        routeName: AppRouteConstants.editProduct,
                        page: EditProduct(product: product.toJson()),
                        extra: product.toJson(),
                        canBack: true);
                  } else if (val == 'DELETE') {
                    onDelete(product);
                  }
                },
                itemBuilder: (cxt) {
                  return <PopupMenuEntry>[
                    const PopupMenuItem(value: 'EDIT', child: Text("Editer")),
                    const PopupMenuItem(
                        value: 'DELETE', child: Text("Supprimer")),
                  ];
                })
          ]));
    }
    return rows;
  }

  void onDelete(ProductModel product) {
    showAlert(
            context,
            SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  const Text("Suppression d'un produit",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      "Vous êtes sur le point de supprimer le produit `${product.name}`.")
                ])),
            okMsg: 'Supprimer',
            cancel: true,
            cancelMsg: 'Annuler')
        .then((res) async {
      if (res != null) {
        if (mounted) showLoading(context);
        try {
          await Services.instance.deleteEntity('/api/product/${product.id}');
          await Services.isar.writeTxn(() async {
            Services.isar.productModels.delete(product.id);
          });
          if (mounted) showToast(context, "Produit supprimé");
        } catch (e) {
          String msg = "Une erreur s'est produite";
          if (mounted) showToast(context, msg);
        }
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  void _onRefresh() async {
    // monitor network fetch
    try {
      await Services.instance.getProducts();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }
}
