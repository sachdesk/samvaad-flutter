import 'package:flutter/material.dart';
import 'package:samvaad_widget/samvaad_widget.dart';

// Your Samvaad tenant id and chat host. Pass your own with
// --dart-define=SAMVAAD_TENANT_ID=... --dart-define=SAMVAAD_HOST=...
const String tenantId = String.fromEnvironment(
  'SAMVAAD_TENANT_ID',
  defaultValue: '6f1c2b8e-4a3d-4e2f-9b7a-1c5d8e0f2a34',
);
const String host = String.fromEnvironment(
  'SAMVAAD_HOST',
  defaultValue: 'yobruh.samvaads.com',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Samvaad.configure(tenantId: tenantId, host: host);
  runApp(const YobruhShopApp());
}

class YobruhShopApp extends StatelessWidget {
  const YobruhShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yobruh Shop',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const ShopHomePage(),
    );
  }
}

class ShopHomePage extends StatelessWidget {
  const ShopHomePage({super.key});

  Future<void> _openHelp() {
    return Samvaad.present(message: 'Help with order YB-1042');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yobruh Shop'),
        actions: <Widget>[
          StreamBuilder<int>(
            stream: Samvaad.onUnreadChange,
            initialData: 0,
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
              final int count = snapshot.data ?? 0;
              return IconButton(
                tooltip: 'Help',
                onPressed: _openHelp,
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.support_agent),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Order YB-1042 is on its way.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _openHelp,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Help'),
            ),
          ],
        ),
      ),
    );
  }
}
