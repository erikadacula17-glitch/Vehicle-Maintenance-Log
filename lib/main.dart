import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() => runApp(const MotoCareApp());

class MotoCareApp extends StatelessWidget {
  const MotoCareApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MotoCare',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEF6C35), brightness: Brightness.dark), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFF101216), cardTheme: const CardThemeData(color: Color(0xFF1B1F25), elevation: 0)),
    home: const HomePage(),
  );
}

enum RecordKind { oil, repair }

class MaintenanceRecord {
  MaintenanceRecord({required this.id, required this.kind, required this.date, required this.mileage, required this.title, required this.details, required this.cost, this.partsCost = 0, this.laborCost = 0});
  final String id;
  final RecordKind kind;
  final DateTime date;
  final int mileage;
  final String title;
  final String details;
  final double cost;
  final double partsCost;
  final double laborCost;
  Map<String, dynamic> toJson() => {'id':id,'kind':kind.name,'date':date.toIso8601String(),'mileage':mileage,'title':title,'details':details,'cost':cost,'partsCost':partsCost,'laborCost':laborCost};
  factory MaintenanceRecord.fromJson(Map<String,dynamic> j) => MaintenanceRecord(id:j['id'],kind:RecordKind.values.firstWhere((e)=>e.name==j['kind'],orElse:()=>RecordKind.repair),date:DateTime.parse(j['date']),mileage:j['mileage'] ?? 0,title:j['title'] ?? '',details:j['details'] ?? '',cost:(j['cost'] as num).toDouble(),partsCost:((j['partsCost'] ?? 0) as num).toDouble(),laborCost:((j['laborCost'] ?? 0) as num).toDouble());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _currency = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
  List<MaintenanceRecord> _records = [];
  String _bike = 'My Motorcycle';
  String _model = 'Add your motorcycle model';
  int _odometer = 12500;
  int _interval = 2000;
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('records') ?? '[]';
    setState(() {
      _records = (jsonDecode(raw) as List).map((e)=>MaintenanceRecord.fromJson(Map<String,dynamic>.from(e))).toList();
      _bike = p.getString('bike') ?? _bike;
      _model = p.getString('model') ?? _model;
      _odometer = p.getInt('odometer') ?? _odometer;
      _interval = p.getInt('interval') ?? _interval;
      _loading = false;
    });
  }
  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('records',jsonEncode(_records.map((e)=>e.toJson()).toList()));
    await p.setString('bike',_bike); await p.setString('model',_model);
    await p.setInt('odometer',_odometer); await p.setInt('interval',_interval);
  }
  double get _total => _records.fold(0,(s,r)=>s+r.cost);
  int? get _lastOilMileage {
    final oils=_records.where((r)=>r.kind==RecordKind.oil).toList()..sort((a,b)=>b.date.compareTo(a.date));
    return oils.isEmpty ? null : oils.first.mileage;
  }
  int get _nextOil => (_lastOilMileage ?? _odometer) + _interval;
  int get _remaining => _nextOil - _odometer;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Row(children:[Icon(Icons.two_wheeler,color:Color(0xFFEF6C35)),SizedBox(width:9),Text('MotoCare',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:.4))]),actions:[IconButton(tooltip:'Motorcycle settings',onPressed:_editBike,icon:const Icon(Icons.settings_outlined))]),
      body: SafeArea(child: IndexedStack(index:_tab,children:[_dashboard(),_history()])),
      floatingActionButton: FloatingActionButton.extended(onPressed:()=>_showRecordDialog(),icon:const Icon(Icons.add),label:const Text('Add record')),
      bottomNavigationBar: NavigationBar(selectedIndex:_tab,onDestinationSelected:(v)=>setState(()=>_tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Overview'),NavigationDestination(icon:Icon(Icons.history),label:'History')]),
    );
  }

  Widget _dashboard() => ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
    Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),gradient:const LinearGradient(colors:[Color(0xFFB84A24),Color(0xFFEF7A3D)],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('YOUR RIDE, WELL MAINTAINED',style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,letterSpacing:1.2,color:Colors.white70)),
      const SizedBox(height:12),Text(_bike,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w800,color:Colors.white)),
      Text(_model,style:const TextStyle(color:Colors.white70)),const SizedBox(height:24),
      Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('CURRENT ODOMETER',style:TextStyle(fontSize:10,color:Colors.white70)),Text(NumberFormat('#,##0').format(_odometer)+' km',style:const TextStyle(fontSize:27,fontWeight:FontWeight.bold,color:Colors.white))])),IconButton.filledTonal(onPressed:_editBike,icon:const Icon(Icons.edit,color:Colors.white),tooltip:'Edit motorcycle')])
    ])),
    const SizedBox(height:16),
    Row(children:[Expanded(child:_stat('Total spent',_currency.format(_total),Icons.payments_outlined)),const SizedBox(width:12),Expanded(child:_stat('Records',_records.length.toString(),Icons.receipt_long_outlined))]),
    const SizedBox(height:18),
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:const Color(0xFF1B1F25),borderRadius:BorderRadius.circular(18),border:Border.all(color:Colors.white10)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.oil_barrel,color:Color(0xFFEF8A50)),const SizedBox(width:8),const Expanded(child:Text('NEXT OIL CHANGE',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:.7))),Text(_remaining<=0?'DUE NOW':'IN '+NumberFormat('#,##0').format(_remaining)+' KM',style:TextStyle(color:_remaining<=0?Colors.orangeAccent:const Color(0xFF8BD6A6),fontWeight:FontWeight.bold,fontSize:11))]),
      const SizedBox(height:12),Text(NumberFormat('#,##0').format(_nextOil)+' km',style:const TextStyle(fontSize:28,fontWeight:FontWeight.bold)),
      const SizedBox(height:10),ClipRRect(borderRadius:BorderRadius.circular(20),child:LinearProgressIndicator(value:(_odometer/(_nextOil==0?1:_nextOil)).clamp(0.0,1.0),minHeight:8,backgroundColor:Colors.white12,color:const Color(0xFFEF7A3D))),
      const SizedBox(height:8),Text('Oil change interval: '+NumberFormat('#,##0').format(_interval)+' km',style:const TextStyle(color:Colors.white54,fontSize:12))
    ])),
    const SizedBox(height:22),
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[const Text('Recent activity',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),TextButton(onPressed:()=>setState(()=>_tab=1),child:const Text('See all'))]),
    if (_records.isEmpty) _empty('No maintenance records yet','Add your first oil change or repair to get started.')
    else ...(_records.toList()..sort((a,b)=>b.date.compareTo(a.date))).take(4).map(_recordTile),
  ]);

  Widget _stat(String label,String value,IconData icon)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF1B1F25),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:const Color(0xFFEF8A50)),const SizedBox(height:12),Text(value,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:19)),Text(label,style:const TextStyle(color:Colors.white54,fontSize:12))]));
  Widget _history()=>ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
    const Text('Maintenance history',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(_records.length.toString()+' saved records',style:const TextStyle(color:Colors.white54)),const SizedBox(height:16),
    if(_records.isEmpty)_empty('Your log is empty','Your oil changes and repairs will appear here.')
    else ...(_records.toList()..sort((a,b)=>b.date.compareTo(a.date))).map(_recordTile)
  ]);
  Widget _empty(String title,String sub)=>Container(padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:const Color(0xFF1B1F25),borderRadius:BorderRadius.circular(18)),child:Column(children:[const Icon(Icons.two_wheeler,size:38,color:Colors.white38),const SizedBox(height:12),Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(sub,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white54,fontSize:12))]));
  Widget _recordTile(MaintenanceRecord r)=>Card(child:ListTile(contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:7),leading:CircleAvatar(backgroundColor:r.kind==RecordKind.oil?const Color(0xFF4C3528):const Color(0xFF293B48),child:Icon(r.kind==RecordKind.oil?Icons.oil_barrel:Icons.build,color:r.kind==RecordKind.oil?const Color(0xFFFFA36C):const Color(0xFF83C9F0))),title:Text(r.title,style:const TextStyle(fontWeight:FontWeight.bold)),subtitle:Text(DateFormat('MMM d, yyyy').format(r.date)+' • '+NumberFormat('#,##0').format(r.mileage)+' km\n'+r.details,maxLines:2,overflow:TextOverflow.ellipsis),isThreeLine:true,trailing:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[Text(_currency.format(r.cost),style:const TextStyle(fontWeight:FontWeight.bold)),PopupMenuButton<String>(padding:EdgeInsets.zero,onSelected:(v)=>v=='edit'?_showRecordDialog(existing:r):_deleteRecord(r),itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:'delete',child:Text('Delete'))])])));

  Future<void> _editBike() async {
    final name=TextEditingController(text:_bike), model=TextEditingController(text:_model), odo=TextEditingController(text:_odometer.toString()), interval=TextEditingController(text:_interval.toString());
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Motorcycle profile'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[_field(name,'Motorcycle name'),_field(model,'Brand / model'),_field(odo,'Current mileage (km)',number:true),_field(interval,'Oil change interval (km)',number:true)])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save'))]));
    if(ok==true){setState(() {_bike=name.text.trim().isEmpty?'My Motorcycle':name.text.trim();_model=model.text.trim();_odometer=int.tryParse(odo.text)??_odometer;_interval=(int.tryParse(interval.text)??_interval).clamp(500,10000);});await _save();}
  }
  Widget _field(TextEditingController c,String label,{bool number=false})=>Padding(padding:const EdgeInsets.only(bottom:10),child:TextField(controller:c,keyboardType:number?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:label,border:const OutlineInputBorder())));

  Future<void> _showRecordDialog({MaintenanceRecord? existing}) async {
    var kind=existing?.kind??RecordKind.oil; var date=existing?.date??DateTime.now();
    final title=TextEditingController(text:existing?.title??(kind==RecordKind.oil?'Engine oil change':'')), mileage=TextEditingController(text:existing?.mileage.toString()??_odometer.toString()), details=TextEditingController(text:existing?.details??''), cost=TextEditingController(text:existing?.cost.toStringAsFixed(2)??''), parts=TextEditingController(text:existing?.partsCost.toStringAsFixed(2)??''), labor=TextEditingController(text:existing?.laborCost.toStringAsFixed(2)??'');
    final result=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:Text(existing==null?'Add maintenance record':'Edit maintenance record'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      SegmentedButton<RecordKind>(segments:const [ButtonSegment(value:RecordKind.oil,label:Text('Oil change'),icon:Icon(Icons.oil_barrel)),ButtonSegment(value:RecordKind.repair,label:Text('Repair'),icon:Icon(Icons.build))],selected:{kind},onSelectionChanged:(s)=>setD(()=>kind=s.first)),
      const SizedBox(height:14),_field(title,kind==RecordKind.oil?'Oil / service name':'Repair / service name'),
      _field(mileage,'Mileage (km)',number:true),
      _field(details,kind==RecordKind.oil?'Oil brand / type':'Parts replaced / work done'),
      if(kind==RecordKind.repair)...[_field(parts,'Parts cost (₱)',number:true),_field(labor,'Labor cost (₱)',number:true)],
      if(kind==RecordKind.oil)_field(cost,'Total cost (₱)',number:true),
      if(kind==RecordKind.repair)Align(alignment:Alignment.centerLeft,child:Text('Total: '+_currency.format((double.tryParse(parts.text)??0)+(double.tryParse(labor.text)??0)))),
      const SizedBox(height:8),OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:ctx,initialDate:date,firstDate:DateTime(2000),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)setD(()=>date=d);},icon:const Icon(Icons.calendar_month),label:Text(DateFormat('MMM d, yyyy').format(date)))
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Save record'))])));
    if(result!=true)return;
    final p=double.tryParse(parts.text)??0, l=double.tryParse(labor.text)??0;
    final total=kind==RecordKind.oil?(double.tryParse(cost.text)??0):p+l;
    final record=MaintenanceRecord(id:existing?.id??DateTime.now().microsecondsSinceEpoch.toString(),kind:kind,date:date,mileage:int.tryParse(mileage.text)??_odometer,title:title.text.trim().isEmpty?(kind==RecordKind.oil?'Oil change':'Repair'):title.text.trim(),details:details.text.trim(),cost:total,partsCost:p,laborCost:l);
    setState(() {_records.removeWhere((r)=>r.id==record.id);_records.add(record);});
    await _save();
  }
  Future<void> _deleteRecord(MaintenanceRecord r) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Delete record?'),content:Text('Remove "'+r.title+'" from your maintenance log?'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Delete'))]));
    if(ok==true){setState(()=>_records.removeWhere((x)=>x.id==r.id));await _save();}
  }
}
