import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() => runApp(const SaraApp());

class SaraApp extends StatelessWidget {
  const SaraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sara Industries – GST',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B74B5), // brand blue
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B74B5),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

/* ---------------------------- LOGIN ---------------------------- */
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
      child: Center(child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

/* ---------------------- DASHBOARD + TABS ----------------------- */
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
            HomeTab(),     // colorful dashboard (matches sample image)
            InvoiceTab(),  // working invoice + Share PDF
            OrdersTab(),
            StockTab(),    // “Add Inward” button
            MaterialsTab(),
            AccountsTab(),
          ],
        ),
      ),
    );
  }
}

/* -------------------------- HOME TAB -------------------------- */
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    final tab = DefaultTabController.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Blue header with title + total sales
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

          // 2×2 colored tiles
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

          // Orange “Order Status” strip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                _StatusPill(label: "Open", value: "50", icon: Icons.water_drop),
                SizedBox(width: 16),
                _StatusPill(label: "In Progress", value: "8", icon: Icons.local_shipping),
                SizedBox(width: 16),
                _StatusPill(label: "Completed", value: "10", icon: Icons.verified),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Customer order list like sample
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                _OrderCard(
                  customer: "Sanjay Traders", qty: 500, status: "Open",
                  orderDate: "01/07/2024", inProgressDate: "03/07/2024", doneDate: "04/07/2024",
                ),
                _OrderCard(
                  customer: "Akash Enterprises", qty: 750, status: "Completed",
                  orderDate: "01/07/2024", inProgressDate: "03/07/2024", doneDate: "05/07/2024",
                ),
                _OrderCard(
                  customer: "Mehta Distributors", qty: 250, status: "In Progress",
                  orderDate: "02/07/2024", inProgressDate: "03/07/2024", doneDate: "—",
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// helpers for HomeTab
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
          const SizedBox(height: 8),
          Row(children: [
            _dot(Colors.blue), _line(Colors.orange),
            _dot(status!="Open" ? Colors.orange : Colors.black12), _line(Colors.green),
            _dot(status=="Completed" ? Colors.green : Colors.black12),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(orderDate, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Text(inProgressDate, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Text(doneDate, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
  Widget _dot(Color c) => Container(width: 16, height: 16, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  Widget _line(Color c) => Expanded(child: Container(height: 4, color: c.withOpacity(0.6)));
}

/* ------------------------ INVOICE TAB ------------------------- */
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
  void removeRow(int i){ setState(()=>rows.removeAt(i)); }

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

/* ------------------------- ORDERS TAB ------------------------- */
class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});
  @override
  Widget build(BuildContext c){
    final orders=[
      {"id":"ORD-1001","customer":"ABC Traders","qty":200,"status":"Open","date":"2025-08-10","eta":"2025-08-15"},
      {"id":"ORD-1002","customer":"Sai Distributors","qty":350,"status":"In Progress","date":"2025-08-11","eta":"2025-08-16"},
      {"id":"ORD-1003","customer":"City Mart","qty":150,"status":"Completed","date":"2025-08-08","eta":"2025-08-12"},
    ];
    Color chip(String s)=> s=="Open"?Colors.blue: s=="In Progress"?Colors.orange:Colors.green;
    return ListView.builder(padding: const EdgeInsets.all(12), itemCount: orders.length, itemBuilder:(ctx,i){
      final o=orders[i];
      return Card(child: ListTile(
        title: Text("${o["customer"]} • ${o["id"]}"),
        subtitle: Text("Qty: ${o["qty"]} • Order: ${o["date"]} • ETA: ${o["eta"]}"),
        trailing: Chip(label: Text(o["status"] as String, style: const TextStyle(color:Colors.white)), backgroundColor: chip(o["status"] as String)),
      ));
    });
  }
}

/* -------------------------- STOCK TAB ------------------------ */
class StockTab extends StatefulWidget { const StockTab({super.key}); @override State<StockTab> createState()=>_StockTabState(); }
class _StockTabState extends State<StockTab> {
  final raws=[{"name":"Preforms","uom":"pcs","qty":5000,"unitCost":5.2},
              {"name":"Caps","uom":"pcs","qty":5000,"unitCost":0.8},
              {"name":"Labels","uom":"pcs","qty":5000,"unitCost":0.5}];
  final finished=[{"name":"1L Water Bottle","uom":"pcs","qty":1200,"unitCost":0.0}];

  void addInwardDialog(){
    final name=TextEditingController(); final uom=TextEditingController(text:"pcs");
    final qty=TextEditingController(text:"0"); final unit=TextEditingController(text:"0");
    showDialog(context: context, builder:(_)=>AlertDialog(
      title: const Text("Add Inward"),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller:name, decoration: const InputDecoration(labelText:"Item name")),
        TextField(controller:uom, decoration: const InputDecoration(labelText:"UOM")),
        TextField(controller:qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Qty")),
        TextField(controller:unit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:"Unit cost (₹)")),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(onPressed: (){
          setState(()=> raws.add({"name":name.text,"uom":uom.text,
            "qty":double.tryParse(qty.text)??0,"unitCost":double.tryParse(unit.text)??0}));
          Navigator.pop(context);
        }, child: const Text("Add"))
      ],
    ));
  }

  @override
  Widget build(BuildContext c)=>Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed:addInwardDialog, icon: const Icon(Icons.add), label: const Text("Add Inward")),
    body: Padding(padding: const EdgeInsets.all(12), child: Column(children:[
      const Text("Raw Materials", style: TextStyle(color: Colors.black54)),
      Expanded(child: ListView(
        children: raws.map((r)=> ListTile(
          title: Text(r["name"].toString()),
          subtitle: Text("Qty: ${r["qty"]} ${r["uom"]}"),
          trailing: Text("₹${r["unitCost"]}"),
        )).toList(),
      )),
      const Divider(),
      const Text("Finished Goods", style: TextStyle(color: Colors.black54)),
      Expanded(child: ListView(
        children: finished.map((f)=> ListTile(
          title: Text(f["name"].toString()),
          subtitle: Text("Qty: ${f["qty"]} ${f["uom"]}"),
        )).toList(),
      )),
      const SizedBox(height:12),
    ])),
  );
}

/* ----------------------- MATERIALS TAB ----------------------- */
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

/* ------------------------ ACCOUNTS TAB ----------------------- */
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
