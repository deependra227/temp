import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:statusbar/statusbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() => runApp(MyApp());
bool connectionStatus;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App By Deependra Chansoliya',
      theme: ThemeData(primarySwatch: Colors.red),
      home: MyHomePage(title: 'Android App By Deependra Chansoliya'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _launchURL(url) {
    if (canLaunch(url) != null) {
      launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  bool isLoaded = false;
  var url = "https://www.gotestseries.com/";
  void initState() {
    super.initState();
    isLoaded = false;
    StatusBar.color(Color.fromRGBO(196, 40, 39, 0));
  }

  alertDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (
        BuildContext context,
      ) {
        return AlertDialog(
          content: Text("Check Your Internet Connection"),
          actions: [
            FlatButton(
              onPressed: () async {
                await che();
                if (connectionStatus == true) {
                  Navigator.of(context).pop();
                  _webView.loadUrl(url: url);
                } else {
                  Navigator.of(context).pop();
                  alertDialog(context, url);
                }
              },
              child: Text("Reload"),
            )
          ],
          elevation: 5,
        );
      },
    );
  }

  final Completer<InAppWebViewController> _controller =
      Completer<InAppWebViewController>();
  InAppWebViewController _webView;
  int cnt = 0;
  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      FutureBuilder<InAppWebViewController>(
        future: _controller.future,
        builder: (BuildContext context,
            AsyncSnapshot<InAppWebViewController> controller) {
          return web(context, controller);
        },  
      ),
      (isLoaded == false)
          ? Scaffold(
              backgroundColor: Color.fromRGBO(196, 40, 39, 1),
              body: Center(
                child: Image.asset('asset/logo.jpg'),
              ))
          : Container()
    ]);
  }

  backFunction(BuildContext context,
      AsyncSnapshot<InAppWebViewController> controller) async {
    if (controller.data.canGoBack() != null) {
      await che();
      if (connectionStatus == true) {
        controller.data.goBack();
      } else {
        var _url = await controller.data.getUrl();
        alertDialog(context, _url);
      }
    }
  }

  web(BuildContext context, AsyncSnapshot<InAppWebViewController> controller) {
    return WillPopScope(
      onWillPop: () => backFunction(context, controller),
      child: SafeArea(
        child: Scaffold(
          body: InAppWebView(
            initialOptions: InAppWebViewGroupOptions(
                android: AndroidInAppWebViewOptions(),
                crossPlatform: InAppWebViewOptions(
                  javaScriptEnabled: true,
                  horizontalScrollBarEnabled: false,
                  verticalScrollBarEnabled: false,
                  useShouldOverrideUrlLoading: true,
                  transparentBackground: true,
                  useOnLoadResource: true,
                  cacheEnabled: true,
                )),
            initialUrl: url,
            initialHeaders: {},
            onWebViewCreated: (InAppWebViewController controller) {
              _webView = controller;
              _controller.complete(controller);
            },
            onLoadStart: (controller, url) async {
              await che();
              if (connectionStatus == false) {
                controller.stopLoading();
                setState(() {
                  isLoaded = false;
                  cnt = 0;
                });
                alertDialog(context, url);
              }
              if (!url.startsWith('http')) {
                _launchURL(url);
              }
            },
            onLoadStop: (controller, url) {
              setState(() {
                _webView.isLoading().then((i) {
                  if (i == false) {
                    cnt++;
                  }
                  if (cnt >= 2) isLoaded = true;
                });
              });
            },
            shouldOverrideUrlLoading: (InAppWebViewController controller,
                ShouldOverrideUrlLoadingRequest
                    shouldOverrideUrlLoadingRequest) async {
              var _url = shouldOverrideUrlLoadingRequest.url;
              await che();
              if (connectionStatus == false) {
                alertDialog(context, _url);
                return ShouldOverrideUrlLoadingAction.CANCEL;
              }
              if (!_url.startsWith('http')) {
                _launchURL(_url);
                return ShouldOverrideUrlLoadingAction.CANCEL;
              } else
                return ShouldOverrideUrlLoadingAction.ALLOW;
            },
          ),
        ),
      ),
    );
  }
}

Future<bool> che() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      connectionStatus = true;
      return true;
    }
  } on SocketException catch (_) {
    connectionStatus = false;
    return false;
  }
  return false;
}
