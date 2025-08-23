import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/* ======================= MODELS & APP STATE ======================= */

enum OrderStatus { open, inProgress, completed }

class Order {
  final String id;
  final String customer;
  int qty;
  OrderStatus status;
  final DateTime date;
  Order({required this.id, required this.customer, required this.qty, required this.status, required this.date});
}

class StockItem {
  final String name;
  final String uom;
  double qty;
  double unitCost;
  StockItem({required this.name, required this.uom, required this.qty, this.unitCost = 0});
}

class CostPart {
  String name;
  double value;
  CostPart(this.name, this.value);
}

class Txn {
  final DateTime date;
  final bool isCredit;
  final double amount;
  final String note;
  Txn({required this.date, required this.isCredit, required this.amount, required this.note});
}

class AppState extends ChangeNotifier {
  /* -------- Orders -------- */
  final List<Order> orders = [
    Order(id: "ORD-1001", customer: "Sanjay Traders",  qty: 500, status: OrderStatus.open,       date: DateTime(2024,7,1)),
    Order(id: "ORD-1002", customer: "Akash Enterprises",qty: 750, status: OrderStatus.completed,  date: DateTime(2024,7,1)),
    Order(id: "ORD-1003", customer: "Mehta Distributors",qty:250, status: OrderStatus.inProgress, date: DateTime(2024,7,2)),
  ];
  int get ordersOpen       => orders.where((o)=>o.status==OrderStatus.open).length;
  int get ordersInProgress => orders.where((o)=>o.status==OrderStatus.inProgress).length;
  int get ordersCompleted  => orders.where((o)=>o.status==OrderStatus.completed).length;
  int get qtyOpen          => orders.where((o)=>o.status==OrderStatus.open).fold(0,(s,o)=>s+o.qty);
  int get qtyInProgress    => orders.where((o)=>o.status==OrderStatus.inProgress).fold(0,(s,o)=>s+o.qty);
  int get qtyCompleted     => orders.where((o)=>o.status==OrderStatus.completed).fold(0,(s,o)=>s+o.qty);

  void addOrder(String customer, int qty){
    final next = orders.length + 1001;
    orders.insert(0, Order(id:"ORD-$next", customer:customer, qty:qty, status:OrderStatus.open, date:DateTime.now()));
    notifyListeners();
  }

  /* -------- Stock -------- */
  final List<StockItem> raw = [
    StockItem(name:"Preforms", uom:"pcs", qty:5000, unitCost:5.2),
    StockItem(name:"Caps",     uom:"pcs", qty:5000, unitCost:0.8),
    StockItem(name:"Labels",   uom:"pcs", qty:5000, unitCost:0.5),
  ];
  final List<StockItem> finished = [ StockItem(name:"1L Water Bottle", uom:"pcs", qty:1200) ];

  void inwardRaw({required String name, required String uom, required double qty, double? unitCost}){
    final key=name.trim().toLowerCase();
    final i = raw.indexWhere((r)=>r.name.trim().toLowerCase()==key);
    if(i>=0){ raw[i].qty += qty; if(unitCost!=null && unitCost>0) raw[i].unitCost=unitCost; }
    else { raw.add(StockItem(name:name.trim(), uom:uom.trim(), qty:qty, unitCost:unitCost??0)); }
    notifyListeners();
  }

  // Simple BOM: 1 Preform + 1 Cap + 1 Label -> 1 Finished Bottle
  void _applyCompletionDelta(int qty, int factor){
    // finished goods
    final fi = finished.indexWhere((f)=>f.name.toLowerCase()=="1l water bottle");
    if(fi>=0){ finished[fi].qty = (finished[fi].qty + factor*qty).clamp(0, double.infinity); }
    // raw consumption on completion; revert if moving away from completed
    void consume(String name){
      final i = raw.indexWhere((r)=>r.name.toLowerCase()==name.toLowerCase());
      if(i>=0){ raw[i].qty = (raw[i].qty - factor*qty).clamp(0, double.infinity); }
    }
    consume("Preforms"); consume("Caps"); consume("Labels");
  }

  void updateOrderStatus(Order o, OrderStatus newStatus){
    if(o.status != OrderStatus.completed && newStatus==OrderStatus.completed){
      _applyCompletionDelta(o.qty, 1);   // apply production
    } else if(o.status == OrderStatus.completed && newStatus!=OrderStatus.completed){
      _applyCompletionDelta(o.qty, -1);  // revert
    }
    o.status = newStatus; notifyListeners();
  }

  /* -------- Materials (unit cost) -------- */
  final List<CostPart> costParts = [
    CostPart("Preform", 5.20), CostPart("Cap", .80), CostPart("Label", .50),
    CostPart("Utilities", .35), CostPart("Labour", .50),
  ];
  double get unitCostTotal => costParts.fold(0.0, (s,c)=>s+c.value);
  void addCostPart(String name,double v){ costParts.add(CostPart(name,v)); notifyListeners(); }
  void updateCostPart(int i,String name,double v){ costParts[i].name=name; costParts[i].value=v; notifyListeners(); }
  void deleteCostPart(int i){ costParts.removeAt(i); notifyListeners(); }

  /* -------- Accounts -------- */
  final List<Txn> txns = [
    Txn(date: DateTime.now(), isCredit:true,  amount:1000, note:"Test Depot"),
    Txn(date: DateTime.now().subtract(const Duration(days:1)), isCredit:false, amount:800, note:"Caps purchase"),
  ];
  void addTxn({required bool isCredit, required double amount, required String note}){
    txns.insert(0, Txn(date:DateTime.now(), isCredit:isCredit, amount:amount, note:note)); notifyListeners();
  }
  Map<String, Map<String,double>> periodSums(){
    double cD=0,dD=0,cW=0,dW=0,cM=0,dM=0;
    final now=DateTime.now(), sod=DateTime(now.year,now.month,now.day),
          sow=sod.subtract(Duration(days:sod.weekday-1)), som=DateTime(now.year,now.month,1);
    for(final t in txns){
      final d=DateTime(t.date.year,t.date.month,t.date.day);
      final td=!d.isBefore(sod), wk=!d.isBefore(sow), mo=!d.isBefore(som);
      if(td){ t.isCredit? cD+=t.amount : dD+=t.amount; }
      if(wk){ t.isCredit? cW+=t.amount : dW+=t.amount; }
      if(mo){ t.isCredit? cM+=t.amount : dM+=t.amount; }
    }
    return {"Today":{"Credit":cD,"Debit":dD,"Net":cD-dD},
            "Week":{"Credit":cW,"Debit":dW,"Net":cW-dW},
            "Month":{"Credit":cM,"Debit":dM,"Net":cM-dM}};
  }
}

/* ---------------- Inherited scope ---------------- */
class AppScope extends InheritedNotifier<AppState>{
  const AppScope({super.key, required AppState notifier, required Widget child})
    : super(notifier:notifier, child:child);
  static AppState of(BuildContext c)=> c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/* ======================= APP ROOT ======================= */

void main()=> runApp(const SaraApp());

class SaraApp extends StatefulWidget{ const SaraApp({super.key}); @override State<SaraApp> createState()=>_SaraAppState();}
class _SaraAppState extends State<SaraApp>{
  final AppState state=AppState();
  @override Widget build(BuildContext context){
    return AppScope(
      notifier: state,
      child: MaterialApp(
        debugShowCheckedModeBanner:false,
        title:"Sara Industries – GST",
        theme: ThemeData(
          useMaterial3:true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B74B5)),
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0B74B5), foregroundColor: Colors.white),
          cardTheme: const CardTheme( // ✅ correct type for ThemeData.cardTheme
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const LoginPage(),
      ),
    );
  }
}

/* ======================= LOGIN ======================= */

class LoginPage extends StatefulWidget{ const LoginPage({super.key}); @override State<LoginPage> createState()=>_LoginPageState();}
class _LoginPageState extends State<LoginPage>{
  final u=TextEditingController(), p=TextEditingController(); String? err;
  @override Widget build(BuildContext c)=> Scaffold(
    body: Center(child: Card(child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth:360),
        child: Column(mainAxisSize: MainAxisSize.min, children:[
          Text("Sara Industries", style: GoogleFonts.inter(fontSize:22,fontWeight:FontWeight.w800)),
          const SizedBox(height:8),
          TextField(controller:u, decoration: const InputDecoration(labelText:"Username")),
          const SizedBox(height:8),
          TextField(controller:p, obscureText:true, decoration: const InputDecoration(labelText:"Password")),
          if(err!=null) Padding(padding: const EdgeInsets.only(top:6), child: Text(err!, style: const TextStyle(color:Colors.red))),
          const SizedBox(height:8),
          FilledButton(onPressed:(){
            if(u.text.trim()=="admin" && p.text=="1234"){
              Navigator.pushReplacement(c, MaterialPageRoute(builder:(_)=>const Dashboard()));
            } else { setState(()=>err="Invalid (use admin / 1234)"); }
          }, child: const Text("Login")),
        ]),
      ),
    ))),
  );
}

/* ======================= DASHBOARD (TABS) ======================= */

class Dashboard extends StatelessWidget{
  const Dashboard({super.key});
  @override Widget build(BuildContext context){
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SARA INDUSTRIES"),
          bottom: const TabBar(isScrollable:true, tabs:[
            Tab(text:"Home"), Tab(text:"Invoice"), Tab(text:"Orders"),
            Tab(text:"Stock"), Tab(text:"Materials"), Tab(text:"Accounts"),
          ]),
        ),
        body: const TabBarView(children:[
          HomeTab(), InvoiceTab(), OrdersTab(), StockTab(), MaterialsTab(), AccountsTab(),
        ]),
      ),
    );
  }
}

/* ======================= HOME ======================= */

class HomeTab extends StatelessWidget{
  const HomeTab({super.key});
  @override Widget build(BuildContext context){
    final s = AppScope.of(context);
    final tabs = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: s,
      builder:(_,__)=> SingleChildScrollView(child: Column(children:[
        // Clean header (removed misleading total)
        Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(20,22,20,18),
          color: const Color(0xFF0B74B5),
          child: const Text("SARA INDUSTRIES", style: TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w800))),
        // Quick tiles
        Padding(padding: const EdgeInsets.all(16), child: GridView(
          shrinkWrap:true, physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2, mainAxisSpacing:12,crossAxisSpacing:12, childAspectRatio:1.4),
          children:[
            _DashTile(color: const Color(0xFF1E9E6A), icon: Icons.receipt_long, title:"Invoice\nManagement", onTap:()=>tabs?.animateTo(1)),
            _DashTile(color: const Color(0xFFF39C12), icon: Icons.move_to_inbox,  title:"Stock\nInward",     onTap:()=>tabs?.animateTo(3)),
            _DashTile(color: const Color(0xFF2D77EA), icon: Icons.bar_chart_rounded,title:"Accounts",         onTap:()=>tabs?.animateTo(5)),
            _DashTile(color: const Color(0xFF6C47C9), icon: Icons.warehouse_outlined, title:"Material\nManagement", onTap:()=>tabs?.animateTo(4)),
          ],
        )),
        // Orange status bar (no overlap, shows orders + bottles)
        Container(margin: const EdgeInsets.symmetric(horizontal:16), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF57C00), borderRadius: BorderRadius.circular(16)),
          child: Wrap(spacing:16, runSpacing:8, children: [
            _StatusChip(icon: Icons.water_drop,     label:"Open",       line1:"${s.ordersOpen} orders",       line2:"${s.qtyOpen} bottles"),
            _StatusChip(icon: Icons.local_shipping, label:"In Progress", line1:"${s.ordersInProgress} orders", line2:"${s.qtyInProgress} bottles"),
            _StatusChip(icon: Icons.verified,       label:"Completed",   line1:"${s.ordersCompleted} orders",  line2:"${s.qtyCompleted} bottles"),
          ])),
        const SizedBox(height:12),
        // Recent orders
        Padding(padding: const EdgeInsets.symmetric(horizontal:16),
          child: Column(children: s.orders.take(3).map((o)=>_OrderCard(
            customer:o.customer, qty:o.qty,
            status:o.status==OrderStatus.open? "Open" : o.status==OrderStatus.inProgress? "In Progress":"Completed",
            orderDate: DateFormat('dd/MM/yyyy').format(o.date),
          )).toList())),
        const SizedBox(height:24),
      ])),
    );
  }
}
class _DashTile extends StatelessWidget{
  final Color color; final IconData icon; final String title; final VoidCallback onTap;
  const _DashTile({required this.color, required this.icon, required this.title, required this.onTap, super.key});
  @override Widget build(BuildContext context)=> InkWell(
    onTap:onTap, borderRadius: BorderRadius.circular(16),
    child: Container(decoration: BoxDecoration(color:color, borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color:Colors.black12, blurRadius:6, offset:Offset(0,3))]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Icon(icon, color:Colors.white, size:32), const Spacer(),
        Text(title, style: const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w700)),
      ]),
    ),
  );
}
class _StatusChip extends StatelessWidget{
  final IconData icon; final String label; final String line1; final String line2;
  const _StatusChip({super.key, required this.icon, required this.label, required this.line1, required this.line2});
  @override Widget build(BuildContext context)=> Container(
    padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children:[
      Icon(icon, color:Colors.white, size:18), const SizedBox(width:8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(label, style: const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),
        Text("$line1 • $line2", style: const TextStyle(color:Colors.white, fontSize:12)),
      ]),
    ]),
  );
}
class _OrderCard extends StatelessWidget{
  final String customer, status, orderDate; final int qty;
  const _OrderCard({super.key, required this.customer, required this.qty, required this.status, required this.orderDate});
  Color get _c => status=="Open"? Colors.blue : status=="In Progress"? Colors.orange : Colors.green;
  @override Widget build(BuildContext context)=> Card(
    margin: const EdgeInsets.only(top:12),
    child: ListTile(
      title: Text(customer, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text("$qty Water Bottles  •  $orderDate"),
      trailing: Chip(label: Text(status, style: const TextStyle(color:Colors.white)), backgroundColor: _c),
    ),
  );
}

/* ======================= INVOICE ======================= */

class InvRow{
  final TextEditingController desc=TextEditingController(text:"Water Bottle");
  final TextEditingController hsn =TextEditingController(text:"373527");
  final TextEditingController qty =TextEditingController(text:"100");
  final TextEditingController rate=TextEditingController(text:"10.00");
}

class InvoiceTab extends StatefulWidget{ const InvoiceTab({super.key}); @override State<InvoiceTab> createState()=>_InvoiceTabState();}
class _InvoiceTabState extends State<InvoiceTab>{
  final invNo=TextEditingController(text:"S/2025/001");
  final buyerName=TextEditingController(text:"Test Depot");
  final buyerGstin=TextEditingController(text:"27ABCDE1234F1Z5");
  final buyerAddr=TextEditingController(text:"KGN layout, Ramtek");
  final cgstCtrl=TextEditingController(text:"9"), sgstCtrl=TextEditingController(text:"9");
  DateTime date=DateTime.now();
  final List<InvRow> rows=[InvRow()];

  double _n(TextEditingController c){ final v=double.tryParse(c.text.trim()); return v??0.0; }
  double get amount => rows.fold(0.0,(s,r)=> s + _n(r.qty)*_n(r.rate));
  double get cgst => amount*(_n(cgstCtrl)/100);
  double get sgst => amount*(_n(sgstCtrl)/100);
  double get total => amount+cgst+sgst;

  void _addRow()=> setState(()=> rows.add(InvRow()));
  void _delRow(int i)=> setState(()=> rows.removeAt(i));

  Future<void> _sharePdf() async{
    final doc=pw.Document(); final fmt=NumberFormat.currency(locale:"en_IN",symbol:"₹");
    doc.addPage(pw.Page(build:(_)=> pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
      pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize:18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height:6),
      pw.Text("Seller: Sara Industries (GSTIN: AB12786Z1)"),
      pw.Text("Address: KGN layout, Ramtek"),
      pw.Text("Invoice: ${invNo.text}   Date: ${DateFormat('dd-MM-yyyy').format(date)}"),
      pw.Text("Buyer: ${buyerName.text} (${buyerGstin.text})"),
      pw.Text("Addr: ${buyerAddr.text}"),
      pw.SizedBox(height:8),
      pw.Table.fromTextArray(headers:["#","Description","HSN","Qty","Rate","Amount"], data:[
        for(int i=0;i<rows.length;i++)
          ["${i+1}", rows[i].desc.text, rows[i].hsn.text, _n(rows[i].qty).toStringAsFixed(0),
            fmt.format(_n(rows[i].rate)), fmt.format(_n(rows[i].qty)*_n(rows[i].rate))]
      ]),
      pw.SizedBox(height:8),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children:[ pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
        pw.Text("Subtotal: ${fmt.format(amount)}"),
        pw.Text("CGST @ ${cgstCtrl.text}%: ${fmt.format(cgst)}"),
        pw.Text("SGST @ ${sgstCtrl.text}%: ${fmt.format(sgst)}"),
        pw.Text("Total: ${fmt.format(total)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ])]),
    ])));
    await Printing.sharePdf(bytes: await doc.save(), filename: "${invNo.text.replaceAll('/','_')}.pdf");
  }

  @override Widget build(BuildContext c){
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children:[
        FloatingActionButton.extended(onPressed:_sharePdf, icon: const Icon(Icons.picture_as_pdf), label: const Text("Share PDF")),
        const SizedBox(height:12),
        FloatingActionButton.extended(onPressed:_addRow, icon: const Icon(Icons.add), label: const Text("Add item")),
      ]),
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(12,12,12,140),
        child: ListView(children:[
          _twoCol(
            TextField(controller:invNo, decoration: const InputDecoration(labelText:"Invoice No"), onChanged:(_)=>setState((){})),
            TextField(readOnly:true, decoration: InputDecoration(labelText:"Date", hintText: DateFormat('dd-MM-yyyy').format(date))),
          ),
          const SizedBox(height:8),
          _twoCol(
            TextField(controller:buyerName, decoration: const InputDecoration(labelText:"Buyer Name"), onChanged:(_)=>setState((){})),
            TextField(controller:buyerGstin, decoration: const InputDecoration(labelText:"Buyer GSTIN"), onChanged:(_)=>setState((){})),
          ),
          const SizedBox(height:8),
          TextField(controller:buyerAddr, decoration: const InputDecoration(labelText:"Buyer Address"), onChanged:(_)=>setState((){})),
          const SizedBox(height:12),

          Card(child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children:[
              Row(children: const [
                Expanded(flex:32, child: Text("Description", style: TextStyle(fontWeight: FontWeight.w700))),
                Expanded(flex:14, child: Text("HSN", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700))),
                Expanded(flex:12, child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700))),
                Expanded(flex:12, child: Text("Rate", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700))),
                Expanded(flex:14, child: Text("Amount", textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.w700))),
                SizedBox(width:36),
              ]),
              const Divider(),
              for(int i=0;i<rows.length;i++) _itemRow(i),
            ]),
          )),

          const SizedBox(height:8),
          _twoCol(
            TextField(controller: cgstCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"CGST %"), onChanged:(_)=>setState((){})),
            TextField(controller: sgstCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"SGST %"), onChanged:(_)=>setState((){})),
          ),

          const SizedBox(height:8),
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text("Subtotal: ₹${amount.toStringAsFixed(2)}"),
              Text("CGST (${cgstCtrl.text}%): ₹${cgst.toStringAsFixed(2)}"),
              Text("SGST (${sgstCtrl.text}%): ₹${sgst.toStringAsFixed(2)}"),
              const SizedBox(height:4),
              Text("Grand Total: ₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          )),
        ]),
      )),
    );
  }

  Widget _itemRow(int i){
    final r=rows[i]; final double amt=_n(r.qty)*_n(r.rate);
    return Padding(
      padding: const EdgeInsets.only(bottom:8),
      child: Row(children:[
        Expanded(flex:32, child: TextField(controller:r.desc, decoration: const InputDecoration(isDense:true, labelText:""))),
        const SizedBox(width:6),
        Expanded(flex:14, child: TextField(controller:r.hsn, textAlign: TextAlign.center, decoration: const InputDecoration(isDense:true, labelText:""), onChanged:(_)=>setState((){}))),
        const SizedBox(width:6),
        Expanded(flex:12, child: TextField(controller:r.qty, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense:true, labelText:""), onChanged:(_)=>setState((){}))),
        const SizedBox(width:6),
        Expanded(flex:12, child: TextField(controller:r.rate, keyboardType: TextInputType.number, textAlign: TextAlign.center, decoration: const InputDecoration(isDense:true, labelText:""), onChanged:(_)=>setState((){}))),
        const SizedBox(width:6),
        Expanded(flex:14, child: Text("₹${amt.toStringAsFixed(2)}", textAlign: TextAlign.end)),
        IconButton(onPressed:()=>_delRow(i), icon: const Icon(Icons.delete_outline)),
      ]),
    );
  }

  Widget _twoCol(Widget a, Widget b)=> LayoutBuilder(builder:(ctx,cons){
    final wide=cons.maxWidth>540;
    return wide? Row(children:[Expanded(child:a), const SizedBox(width:12), Expanded(child:b)])
               : Column(children:[a, const SizedBox(height:8), b]);
  });
}

/* ======================= ORDERS ======================= */

class OrdersTab extends StatelessWidget{
  const OrdersTab({super.key});
  @override Widget build(BuildContext context){
    final s = AppScope.of(context);
    return AnimatedBuilder(
      animation:s,
      builder:(_,__)=> Scaffold(
        floatingActionButton: FloatingActionButton.extended(onPressed:()=>_add(context), icon: const Icon(Icons.add), label: const Text("New Order")),
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: s.orders.length,
          itemBuilder:(_,i){
            final o=s.orders[i];
            return Card(child: ListTile(
              title: Text("${o.customer} • ${o.id}"),
              subtitle: Text("Qty: ${o.qty} • ${DateFormat('dd-MM-yyyy').format(o.date)}"),
              trailing: DropdownButton<OrderStatus>(
                value:o.status, underline: const SizedBox.shrink(),
                onChanged:(v){ if(v!=null) s.updateOrderStatus(o, v); },
                items: const [
                  DropdownMenuItem(value: OrderStatus.open, child: Text("Open")),
                  DropdownMenuItem(value: OrderStatus.inProgress, child: Text("In Progress")),
                  DropdownMenuItem(value: OrderStatus.completed, child: Text("Completed")),
                ],
              ),
            ));
          }),
      ),
    );
  }
  void _add(BuildContext c){
    final s = AppScope.of(c);
    final name=TextEditingController(), qty=TextEditingController(text:"100");
    showDialog(context:c, builder:(_)=>AlertDialog(
      title: const Text("Add Order"),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller:name, decoration: const InputDecoration(labelText:"Customer")),
        TextField(controller:qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Quantity")),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c), child: const Text("Cancel")),
        FilledButton(onPressed:(){
          final n=name.text.trim(); final q=int.tryParse(qty.text.trim())??0;
          if(n.isNotEmpty && q>0){ s.addOrder(n,q); Navigator.pop(c); }
        }, child: const Text("Add")),
      ],
    ));
  }
}

/* ======================= STOCK ======================= */

class StockTab extends StatelessWidget{
  const StockTab({super.key});
  @override Widget build(BuildContext context){
    final s = AppScope.of(context);
    return AnimatedBuilder(
      animation:s,
      builder:(_,__)=> Scaffold(
        floatingActionButton: FloatingActionButton.extended(onPressed:()=>_inward(context), icon: const Icon(Icons.add), label: const Text("Add Inward")),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children:[
            const Text("Raw Materials", style: TextStyle(color:Colors.black54)),
            Expanded(child: ListView(children: s.raw.map((r)=>ListTile(
              title: Text(r.name), subtitle: Text("Qty: ${r.qty.toStringAsFixed(0)} ${r.uom}"),
              trailing: Text(r.unitCost>0? "₹${r.unitCost}" : ""),
            )).toList())),
            const Divider(),
            const Text("Finished Goods", style: TextStyle(color:Colors.black54)),
            Expanded(child: ListView(children: s.finished.map((f)=>ListTile(
              title: Text(f.name), subtitle: Text("Qty: ${f.qty.toStringAsFixed(0)} ${f.uom}"),
            )).toList())),
          ]),
        ),
      ),
    );
  }
  void _inward(BuildContext c){
    final s = AppScope.of(c);
    final name=TextEditingController(), uom=TextEditingController(text:"pcs"),
          qty=TextEditingController(text:"0"), cost=TextEditingController(text:"0");
    showDialog(context:c, builder:(_)=>AlertDialog(
      title: const Text("Add Inward"),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller:name, decoration: const InputDecoration(labelText:"Item name")),
        TextField(controller:uom,  decoration: const InputDecoration(labelText:"UOM")),
        TextField(controller:qty,  keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Qty")),
        TextField(controller:cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Unit cost (₹)")),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c), child: const Text("Cancel")),
        FilledButton(onPressed:(){
          final n=name.text.trim(); final u=uom.text.trim().isEmpty? "pcs":uom.text.trim();
          final q=double.tryParse(qty.text.trim())??0; final pr=double.tryParse(cost.text.trim());
          if(n.isNotEmpty && q>0){ s.inwardRaw(name:n,uom:u,qty:q,unitCost:pr); Navigator.pop(c); }
        }, child: const Text("Add")),
      ],
    ));
  }
}

/* ======================= MATERIALS (UNIT COST) ======================= */

class MaterialsTab extends StatelessWidget{
  const MaterialsTab({super.key});
  @override Widget build(BuildContext context){
    final s = AppScope.of(context); final cur=NumberFormat.currency(locale:"en_IN", symbol:"₹");
    return AnimatedBuilder(
      animation:s,
      builder:(_,__)=> Scaffold(
        floatingActionButton: FloatingActionButton.extended(onPressed:()=>_addPart(context), icon: const Icon(Icons.add), label: const Text("Add Item")),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            const Text("Unit Cost Calculator (per bottle)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height:8),
            Expanded(child: ListView.separated(
              itemCount: s.costParts.length,
              separatorBuilder:(_,__)=> const Divider(height:1),
              itemBuilder:(_,i){
                final cp=s.costParts[i];
                return Row(children:[
                  Expanded(child: TextField(
                    controller: TextEditingController(text: cp.name),
                    decoration: const InputDecoration(labelText:"Item"),
                    onChanged:(v)=> s.updateCostPart(i, v.trim().isEmpty? cp.name:v.trim(), cp.value),
                  )),
                  const SizedBox(width:8),
                  SizedBox(width:120, child: TextField(
                    controller: TextEditingController(text: cp.value.toStringAsFixed(2)),
                    keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Cost (₹)"),
                    onChanged:(v)=> s.updateCostPart(i, cp.name, double.tryParse(v.trim()) ?? cp.value),
                  )),
                  IconButton(onPressed:()=> s.deleteCostPart(i), icon: const Icon(Icons.delete_outline)),
                ]);
              },
            )),
            Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text("Grand Total (per bottle): ${cur.format(s.unitCostTotal)}",
                style: const TextStyle(fontWeight: FontWeight.w700)),
            )),
            const SizedBox(height:80),
          ]),
        ),
      ),
    );
  }
  void _addPart(BuildContext c){
    final s = AppScope.of(c);
    final name=TextEditingController(), val=TextEditingController(text:"0");
    showDialog(context:c, builder:(_)=>AlertDialog(
      title: const Text("Add cost item"),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller:name, decoration: const InputDecoration(labelText:"Name")),
        TextField(controller:val, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Cost (₹)")),
      ]),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c), child: const Text("Cancel")),
        FilledButton(onPressed:(){
          final n=name.text.trim(); final v=double.tryParse(val.text.trim())??0;
          if(n.isNotEmpty){ s.addCostPart(n,v); Navigator.pop(c); }
        }, child: const Text("Add")),
      ],
    ));
  }
}

/* ======================= ACCOUNTS ======================= */

class AccountsTab extends StatefulWidget{ const AccountsTab({super.key}); @override State<AccountsTab> createState()=>_AccountsTabState();}
class _AccountsTabState extends State<AccountsTab>{
  DateTime? from, to;
  @override Widget build(BuildContext context){
    final s = AppScope.of(context); final cur=NumberFormat.currency(locale:"en_IN", symbol:"₹");
    return AnimatedBuilder(
      animation:s,
      builder:(_,__){
        final sums=s.periodSums();
        final filtered=s.txns.where((t){
          final d=DateTime(t.date.year,t.date.month,t.date.day);
          final okF = from==null || !d.isBefore(DateTime(from!.year,from!.month,from!.day));
          final okT = to==null   || !d.isAfter(DateTime(to!.year,to!.month,to!.day));
          return okF && okT;
        }).toList();
        final fCr = filtered.where((t)=>t.isCredit).fold(0.0,(s,t)=>s+t.amount);
        final fDr = filtered.where((t)=>!t.isCredit).fold(0.0,(s,t)=>s+t.amount);

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(onPressed:()=>_addTxn(context), icon: const Icon(Icons.add), label: const Text("Add Entry")),
          body: Column(children:[
            const SizedBox(height:8),
            SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:12), child: Row(children:[
              _sum("Today", sums["Today"]!, cur), _sum("Week", sums["Week"]!, cur), _sum("Month", sums["Month"]!, cur),
            ])),
            const SizedBox(height:8),
            Padding(padding: const EdgeInsets.symmetric(horizontal:12), child: Row(children:[
              Expanded(child: OutlinedButton(onPressed:() async{
                final now=DateTime.now();
                final d=await showDatePicker(context:context, firstDate:DateTime(2020), lastDate:DateTime(now.year+1), initialDate:from??now);
                if(d!=null) setState(()=>from=d);
              }, child: Text(from==null? "From date" : DateFormat('dd-MM-yyyy').format(from!)))),
              const SizedBox(width:8),
              Expanded(child: OutlinedButton(onPressed:() async{
                final now=DateTime.now();
                final d=await showDatePicker(context:context, firstDate:DateTime(2020), lastDate:DateTime(now.year+1), initialDate:to??now);
                if(d!=null) setState(()=>to=d);
              }, child: Text(to==null? "To date" : DateFormat('dd-MM-yyyy').format(to!)))),
              IconButton(onPressed:()=> setState(()=>{from=null,to=null}), icon: const Icon(Icons.clear)),
            ])),
            Padding(padding: const EdgeInsets.fromLTRB(12,8,12,4),
              child: Align(alignment: Alignment.centerLeft, child:
                Text("Selected: Credit ${cur.format(fCr)} • Debit ${cur.format(fDr)} • Net ${cur.format(fCr-fDr)}",
                  style: const TextStyle(fontWeight: FontWeight.w600)))),
            const Divider(height:1),
            Expanded(child: ListView.separated(
              itemCount: filtered.length, separatorBuilder:(_,__)=> const Divider(height:1),
              itemBuilder:(_,i){ final t=filtered[i];
                return ListTile(
                  leading: Icon(t.isCredit? Icons.trending_up: Icons.trending_down, color: t.isCredit? Colors.green: Colors.red),
                  title: Text("${t.isCredit? "Credit":"Debit"} • ${cur.format(t.amount)}"),
                  subtitle: Text("${DateFormat('dd-MM-yyyy HH:mm').format(t.date)} • ${t.note}"),
                );
              },
            )),
          ]),
        );
      },
    );
  }

  Widget _sum(String title, Map<String,double> m, NumberFormat cur)=> Card(
    margin: const EdgeInsets.only(right:10),
    child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height:6),
      Text("Credit: ${cur.format(m["Credit"]??0)}"),
      Text("Debit:  ${cur.format(m["Debit"] ??0)}"),
      const SizedBox(height:2),
      Text("Net:    ${cur.format(m["Net"]   ??0)}",
        style: TextStyle(fontWeight: FontWeight.bold, color: (m["Net"]??0)>=0? Colors.green: Colors.red)),
    ])),
  );

  void _addTxn(BuildContext c){
    final s = AppScope.of(c);
    final amt=TextEditingController(), note=TextEditingController(); bool isCredit=true;
    showDialog(context:c, builder:(_)=> StatefulBuilder(
      builder:(_,setLocal)=> AlertDialog(
        title: const Text("Add Account Entry"),
        content: Column(mainAxisSize: MainAxisSize.min, children:[
          Row(children:[
            ChoiceChip(label: const Text("Credit"), selected:isCredit, onSelected:(_)=> setLocal(()=> isCredit=true)),
            const SizedBox(width:8),
            ChoiceChip(label: const Text("Debit"),  selected:!isCredit, onSelected:(_)=> setLocal(()=> isCredit=false)),
          ]),
          const SizedBox(height:8),
          TextField(controller:amt, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Amount (₹)")),
          TextField(controller:note, decoration: const InputDecoration(labelText:"Description / Particular")),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(c), child: const Text("Cancel")),
          FilledButton(onPressed:(){
            final a=double.tryParse(amt.text.trim())??-1;
            if(a>0){ s.addTxn(isCredit:isCredit, amount:a, note:note.text.trim()); Navigator.pop(c); }
          }, child: const Text("Save")),
        ],
      ),
    ));
  }
}
