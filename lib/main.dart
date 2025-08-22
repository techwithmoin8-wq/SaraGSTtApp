import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/* ======================= APP STATE (GLOBAL) ======================= */

enum OrderStatus { open, inProgress, completed }

class Order {
  final String id;
  final String customer;
  int qty;
  OrderStatus status;
  final DateTime date;
  DateTime? eta;

  Order({
    required this.id,
    required this.customer,
    required this.qty,
    required this.status,
    required this.date,
    this.eta,
  });
}

class StockItem {
  final String name;
  final String uom;
  double qty;
  double unitCost; // optional, for reference

  StockItem({required this.name, required this.uom, required this.qty, this.unitCost = 0});
}

class AppState extends ChangeNotifier {
  /* Orders */
  final List<Order> orders = [
    Order(id: "ORD-1001", customer: "Sanjay Traders", qty: 500, status: OrderStatus.open, date: DateTime(2024, 7, 1)),
    Order(id: "ORD-1002", customer: "Akash Enterprises", qty: 750, status: OrderStatus.completed, date: DateTime(2024, 7, 1)),
    Order(id: "ORD-1003", customer: "Mehta Distributors", qty: 250, status: OrderStatus.inProgress, date: DateTime(2024, 7, 2)),
  ];

  int get ordersOpen => orders.where((o) => o.status == OrderStatus.open).length;
  int get ordersInProgress => orders.where((o) => o.status == OrderStatus.inProgress).length;
  int get ordersCompleted => orders.where((o) => o.status == OrderStatus.completed).length;

  void addOrder(String customer, int qty) {
    final nextNum = orders.length + 1001;
    orders.insert(
      0,
      Order(
        id: "ORD-$nextNum",
        customer: customer,
        qty: qty,
        status: OrderStatus.open,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void updateOrderStatus(Order order, OrderStatus status) {
    order.status = status;
    notifyListeners();
  }

  /* Stock */
  final List<StockItem> raw = [
    StockItem(name: "Preforms", uom: "pcs", qty: 5000, unitCost: 5.2),
    StockItem(name: "Caps", uom: "pcs", qty: 5000, unitCost: 0.8),
    StockItem(name: "Labels", uom: "pcs", qty: 5000, unitCost: 0.5),
  ];

  final List<StockItem> finished = [
    StockItem(name: "1L Water Bottle", uom: "pcs", qty: 1200),
  ];

  void inwardRaw({required String name, required String uom, required double qty, double? unitCost}) {
    final key = name.trim().toLowerCase();
    final idx = raw.indexWhere((r) => r.name.trim().toLowerCase() == key);
    if (idx >= 0) {
      raw[idx].qty += qty;
      if (unitCost != null && unitCost > 0) raw[idx].unitCost = unitCost;
    } else {
      raw.add(StockItem(name: name.trim(), uom: uom.trim(), qty: qty, unitCost: unitCost ?? 0));
    }
    notifyListeners();
  }
}

/* InheritedNotifier wrapper so every page can read AppState without packages */
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required Widget child})
      : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!.notifier!;
  }
}

/* ============================ APP ROOT ============================ */

void main() => runApp(const SaraRoot());

class SaraRoot extends StatefulWidget {
  const SaraRoot({super.key});
  @override
  State<SaraRoot> createState() => _SaraRootState();
}

class _SaraRootState extends State<SaraRoot> {
  final AppState state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: MaterialApp(
        title: 'Sara Industries – GST',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0B74B5),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0B74B5),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          // Flutter 3.35 uses CardThemeData
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}

/* ============================== LOGIN ============================== */

class LoginPage extends StatefulWidget { const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState(); }
class _LoginPageState extends State<LoginPage> {
  final userCtrl=TextEditingController(), passCtrl=TextEditingController(); String? err;
  @override
  Widget build(BuildContext c)=>Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors:[Color(0xFFE0FBFC),Color(0xFFD1FAE5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(child: Card(
        child: Padding(padding: const EdgeInsets.all(24),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360),
            child: Column(mainAxisSize: MainAxisSize.min, children:[
              Text("Sara Industries", style: GoogleFonts.inter(fontSize:22,fontWeight:FontWeight.w800)),
              const SizedBox(height:12),
              TextField(controller:userCtrl, decoration: const InputDecoration(labelText:"Username")),
              const SizedBox(height:8),
              TextField(controller:passCtrl, obscureText:true, decoration: const InputDecoration(labelText:"Password")),
              if(err!=null) Padding(padding: const EdgeInsets.only(top:6),
                child: Text(err!, style: const TextStyle(color:Colors.red))),
              const SizedBox(height:8),
              FilledButton(onPressed: (){
                if(userCtrl.text.trim().toLowerCase()=="admin" && passCtrl.text.trim()=="1234"){
                  Navigator.pushReplacement(c, MaterialPageRoute(builder:(_)=>const DashboardPage()));
                } else { setState(()=>err="Invalid (use admin / 1234)"); }
              }, child: const Text("Login")),
              const SizedBox(height:6),
              const Text("Default: admin / 1234", style: TextStyle(fontSize:12,color:Colors.black54)),
            ]),
          ),
        ),
      )),
    ),
  );
}

/* ======================= DASHBOARD + TABS ======================= */

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6, // Home + 5 tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SARA INDUSTRIES"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "Home"),
              Tab(text: "Invoice"),
              Tab(text: "Orders"),
              Tab(text: "Stock"),
              Tab(text: "Materials"),
              Tab(text: "Accounts"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HomeTab(),
            InvoiceTab(),
            OrdersTab(),
            StockTab(),
            MaterialsTab(),
            AccountsTab(),
          ],
        ),
      ),
    );
  }
}

/* ============================ HOME TAB ============================ */

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final tab = DefaultTabController.of(context);

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Blue header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                color: const Color(0xFF0B74B5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("SARA INDUSTRIES",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text("Total Sales", style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 2),
                    Text("₹ 12,40,000",
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              // 2×2 tiles
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.4,
                  ),
                  children: [
                    _DashTile(
                      color: const Color(0xFF1E9E6A),
                      icon: Icons.receipt_long,
                      title: "Invoice\nManagement",
                      onTap: () => tab?.animateTo(1),
                    ),
                    _DashTile(
                      color: const Color(0xFFF39C12),
                      icon: Icons.move_to_inbox,
                      title: "Stock\nInward",
                      onTap: () => tab?.animateTo(3),
                    ),
                    _DashTile(
                      color: const Color(0xFF2D77EA),
                      icon: Icons.bar_chart_rounded,
                      title: "Accounts",
                      onTap: () => tab?.animateTo(5),
                    ),
                    _DashTile(
                      color: const Color(0xFF6C47C9),
                      icon: Icons.warehouse_outlined,
                      title: "Material\nManagement",
                      onTap: () => tab?.animateTo(4),
                    ),
                  ],
                ),
              ),

              // Orange Order Status (linked to actual state)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF57C00),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _StatusPill(label: "Open", value: "${state.ordersOpen}", icon: Icons.water_drop),
                    const SizedBox(width: 16),
                    _StatusPill(label: "In Progress", value: "${state.ordersInProgress}", icon: Icons.local_shipping),
                    const SizedBox(width: 16),
                    _StatusPill(label: "Completed", value: "${state.ordersCompleted}", icon: Icons.verified),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Recent orders list (from state)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: state.orders.take(3).map((o) => _OrderCard(
                    customer: o.customer,
                    qty: o.qty,
                    status: _statusText(o.status),
                    orderDate: DateFormat('dd/MM/yyyy').format(o.date),
                    inProgressDate: "", // timeline sample (optional)
                    doneDate: o.status == OrderStatus.completed ? DateFormat('dd/MM/yyyy').format(o.date) : "—",
                  )).toList(),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  static String _statusText(OrderStatus s) =>
      s == OrderStatus.open ? "Open" : s == OrderStatus.inProgress ? "In Progress" : "Completed";
}

class _DashTile extends StatelessWidget {
  final Color color; final IconData icon; final String title; final VoidCallback onTap;
  const _DashTile({required this.color, required this.icon, required this.title, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ]),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Colors.white, size: 32),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label, value; final IconData icon;
  const _StatusPill({required this.label, required this.value, required this.icon, super.key});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(children: [
      Icon(icon, color: Colors.white),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    ]),
  );
}

class _OrderCard extends StatelessWidget {
  final String customer, status, orderDate, inProgressDate, doneDate; final int qty;
  const _OrderCard({super.key, required this.customer, required this.qty, required this.status,
    required this.orderDate, required this.inProgressDate, required this.doneDate});

  Color get _statusColor => status=="Open" ? Colors.blue : status=="In Progress" ? Colors.orange : Colors.green;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(customer, style: const TextStyle(fontWeight: FontWeight.w700)),
            Chip(label: Text(status, style: const TextStyle(color: Colors.white)), backgroundColor: _statusColor),
          ]),
          Text("$qty Water Bottles", style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(orderDate, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Text(inProgressDate.isEmpty ? "—" : inProgressDate, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Text(doneDate, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}

/* =========================== INVOICE TAB =========================== */

class InvoiceTab extends StatefulWidget { const InvoiceTab({super.key}); @override State<InvoiceTab> createState()=>_InvoiceTabState(); }
class _InvoiceTabState extends State<InvoiceTab> {
  String invNo="S/2025/001";
  final buyerName=TextEditingController(text:"Test Depot");
  final buyerGstin=TextEditingController(text:"27ABCDE1234F1Z5");
  final buyerAddr=TextEditingController(text:"KGN layout, Ramtek");
  DateTime date=DateTime.now();

  final List<InvRow> rows=[InvRow("Water Bottle","373527",100,10)];
  double get amount=>rows.fold(0.0,(s,r)=>s + r.qty*r.rate);
  double get cgst=>amount*0.09; double get sgst=>amount*0.09; double get total=>amount+cgst+sgst;

  void addRow(){ setState(()=>rows.add(InvRow("Water Bottle","373527",1,0))); }

  Future<void> sharePdf() async {
    final doc=pw.Document(); final fmt=NumberFormat.currency(locale:"en_IN", symbol:"₹");
    doc.addPage(pw.Page(build:(_)=>pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
      pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize:18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height:6),
      pw.Text("Seller: Sara Industries (GSTIN: AB12786Z1)"),
      pw.Text("Address: KGN layout, Ramtek"),
      pw.Text("Invoice: $invNo   Date: ${DateFormat('dd-MM-yyyy').format(date)}"),
      pw.Text("Buyer: ${buyerName.text} (${buyerGstin.text})"),
      pw.Text("Addr: ${buyerAddr.text}"),
      pw.SizedBox(height:8),
      pw.Table.fromTextArray(headers:["#","Description","HSN","Qty","Rate","Amount"], data:[
        for(int i=0;i<rows.length;i++)
          ["${i+1}", rows[i].desc, rows[i].hsn, rows[i].qty.toStringAsFixed(0),
           fmt.format(rows[i].rate), fmt.format(rows[i].qty*rows[i].rate)]
      ]),
      pw.SizedBox(height:8),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children:[ pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
          pw.Text("Subtotal: ${fmt.format(amount)}"),
          pw.Text("CGST @ 9%: ${fmt.format(cgst)}"),
          pw.Text("SGST @ 9%: ${fmt.format(sgst)}"),
          pw.Text("Total: ${fmt.format(total)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ])]),
      pw.SizedBox(height:12),
      pw.Text("Amount in words: ${NumberFormat.compact().format(total)} Rupees only"),
    ])));
    await Printing.sharePdf(bytes: await doc.save(), filename: "${invNo.replaceAll('/', '_')}.pdf");
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.extended(
          heroTag: "shareBtn",
          onPressed: sharePdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text("Share PDF"),
          ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: "addItemBtn",
          onPressed: addRow,
          icon: const Icon(Icons.add),
          label: const Text("Add item"),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children:[
          Row(children:[
            Expanded(child: TextField(
              decoration: const InputDecoration(labelText:"Invoice No"),
              controller: TextEditingController(text:invNo),
              onChanged:(v)=>invNo=v,
            )),
            const SizedBox(width:12),
            Expanded(child: Text(DateFormat('dd-MM-yyyy').format(date))),
          ]),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child: TextField(decoration: const InputDecoration(labelText:"Buyer Name"), controller: buyerName)),
            const SizedBox(width:12),
            Expanded(child: TextField(decoration: const InputDecoration(labelText:"Buyer GSTIN"), controller: buyerGstin)),
          ]),
          const SizedBox(height:8),
          TextField(decoration: const InputDecoration(labelText:"Buyer Address"), controller: buyerAddr),
          const SizedBox(height:8),

          Expanded(child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            itemBuilder:(ctx,i){
              final r=rows[i];
              return Card(child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children:[
                  Expanded(flex:3, child: TextField(
                    decoration: const InputDecoration(labelText:"Description"),
                    controller: TextEditingController(text:r.desc),
                    onChanged:(v)=>r.desc=v,
                  )),
                  const SizedBox(width:6),
                  Expanded(child: TextField(
                    decoration: const InputDecoration(labelText:"HSN"),
                    controller: TextEditingController(text:r.hsn),
                    onChanged:(v)=>r.hsn=v,
                  )),
                  const SizedBox(width:6),
                  Expanded(child: TextField(
                    decoration: const InputDecoration(labelText:"Qty"),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text:r.qty.toStringAsFixed(0)),
                    onChanged:(v)=>r.qty=double.tryParse(v)??r.qty,
                  )),
                  const SizedBox(width:6),
                  Expanded(child: TextField(
                    decoration: const InputDecoration(labelText:"Rate"),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(text:r.rate.toStringAsFixed(2)),
                    onChanged:(v)=>r.rate=double.tryParse(v)??r.rate,
                  )),
                  IconButton(onPressed: ()=>setState(()=>rows.removeAt(i)), icon: const Icon(Icons.delete_outline)),
                ]),
              ));
            },
          )),

          const SizedBox(height:8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Amt: ₹${amount.toStringAsFixed(2)}  |  "
              "CGST: ₹${cgst.toStringAsFixed(2)}  |  "
              "SGST: ₹${sgst.toStringAsFixed(2)}  |  "
              "Total: ₹${total.toStringAsFixed(2)}",
            ),
          ),
          const SizedBox(height:72),
        ]),
      ),
    ),
  );
}
class InvRow{ String desc; String hsn; double qty; double rate; InvRow(this.desc,this.hsn,this.qty,this.rate); }

/* ============================ ORDERS TAB ============================ */

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddOrderDialog(context),
            icon: const Icon(Icons.add),
            label: const Text("New Order"),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: state.orders.length,
            itemBuilder: (ctx, i) {
              final o = state.orders[i];
              return Card(
                child: ListTile(
                  title: Text("${o.customer} • ${o.id}"),
                  subtitle: Text("Qty: ${o.qty} • Date: ${DateFormat('dd-MM-yyyy').format(o.date)}"),
                  trailing: DropdownButton<OrderStatus>(
                    value: o.status,
                    underline: const SizedBox.shrink(),
                    onChanged: (val) {
                      if (val != null) state.updateOrderStatus(o, val);
                    },
                    items: const [
                      DropdownMenuItem(value: OrderStatus.open, child: Text("Open")),
                      DropdownMenuItem(value: OrderStatus.inProgress, child: Text("In Progress")),
                      DropdownMenuItem(value: OrderStatus.completed, child: Text("Completed")),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddOrderDialog(BuildContext context) {
    final state = AppScope.of(context);
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "100");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Order"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Customer name")),
          TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (name.isNotEmpty && qty > 0) {
                state.addOrder(name, qty);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

/* ============================= STOCK TAB ============================= */

class StockTab extends StatelessWidget {
  const StockTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addInwardDialog(context),
            icon: const Icon(Icons.add),
            label: const Text("Add Inward"),
          ),
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text("Raw Materials", style: TextStyle(color: Colors.black54)),
                Expanded(
                  child: ListView(
                    children: state.raw
                        .map((r) => ListTile(
                              title: Text(r.name),
                              subtitle: Text("Qty: ${r.qty.toStringAsFixed(0)} ${r.uom}"),
                              trailing: Text(r.unitCost > 0 ? "₹${r.unitCost}" : ""),
                            ))
                        .toList(),
                  ),
                ),
                const Divider(),
                const Text("Finished Goods", style: TextStyle(color: Colors.black54)),
                Expanded(
                  child: ListView(
                    children: state.finished
                        .map((f) => ListTile(
                              title: Text(f.name),
                              subtitle: Text("Qty: ${f.qty.toStringAsFixed(0)} ${f.uom}"),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addInwardDialog(BuildContext context) {
    final state = AppScope.of(context);
    final name = TextEditingController();
    final uom = TextEditingController(text: "pcs");
    final qty = TextEditingController(text: "0");
    final unit = TextEditingController(text: "0");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Inward"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: "Item name")),
          TextField(controller: uom, decoration: const InputDecoration(labelText: "UOM")),
          TextField(controller: qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qty")),
          TextField(controller: unit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Unit cost (₹)")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(
            onPressed: () {
              final n = name.text.trim();
              final u = uom.text.trim().isEmpty ? "pcs" : uom.text.trim();
              final q = double.tryParse(qty.text.trim()) ?? 0;
              final c = double.tryParse(unit.text.trim());
              if (n.isNotEmpty && q > 0) {
                state.inwardRaw(name: n, uom: u, qty: q, unitCost: c);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

/* =========================== MATERIALS TAB =========================== */

class MaterialsTab extends StatelessWidget { const MaterialsTab({super.key});
  @override Widget build(BuildContext c){
    const preform=5.2, cap=0.8, label=0.5, utilities=0.35, labour=0.50;
    final total=preform+cap+label+utilities+labour;
    return Padding(padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        const Text("Unit Cost (per bottle)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height:8),
        Text("Preform: ₹${preform.toStringAsFixed(2)}"),
        Text("Cap: ₹${cap.toStringAsFixed(2)}"),
        Text("Label: ₹${label.toStringAsFixed(2)}"),
        Text("Utilities: ₹${utilities.toStringAsFixed(2)}"),
        Text("Labour: ₹${labour.toStringAsFixed(2)}"),
        const SizedBox(height:8),
        Text("Total Unit Cost: ₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

/* ============================ ACCOUNTS TAB ============================ */

class AccountsTab extends StatelessWidget { const AccountsTab({super.key});
  @override Widget build(BuildContext c){
    final payments=[
      {"date":DateFormat('dd-MM-yyyy').format(DateTime.now()),
       "customer":"Test Depot","mode":"UPI","amount":1000.0},
      {"date":DateFormat('dd-MM-yyyy').format(DateTime.now().subtract(const Duration(days:1))),
       "customer":"ABC Traders","mode":"Cash","amount":2500.0},
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: payments.length,
      separatorBuilder:(_,__)=>const Divider(height:1),
      itemBuilder:(ctx,i){
        final p=payments[i];
        return ListTile(
          title: Text("${p["customer"]} • ${p["mode"]}"),
          subtitle: Text(p["date"].toString()),
          trailing: Text("₹${(p["amount"] as double).toStringAsFixed(2)}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
