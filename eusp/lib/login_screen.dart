import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:http/http.dart' as http;
import 'package:oauth1/oauth1.dart' as oauth1;
import 'package:flutter_easyrefresh/material_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webviewx/webviewx.dart';
import 'package:eusp/constants.dart' as constants; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final EasyRefreshController _refreshController = EasyRefreshController();
  WebViewXController? _webViewController;
  Size get _screenSize => MediaQuery.of(context).size;
  
  final clientCredentials = oauth1.ClientCredentials(
    constants.API_TOKEN_KEY,
    constants.API_TOKEN_KEY_SECRET,
  );
  final platform = oauth1.Platform(
    constants.API_ENDPOINT_REQUEST_TOKEN,
    constants.API_ENDPOINT_AUTHORIZE,
    constants.API_ENDPOINT_ACCESS_TOKEN,
    oauth1.SignatureMethods.hmacSha1,
  );
  var auth = oauth1.Authorization(
    oauth1.ClientCredentials(
      constants.API_TOKEN_KEY,
      constants.API_TOKEN_KEY_SECRET,
    ),
    oauth1.Platform(
      constants.API_ENDPOINT_REQUEST_TOKEN,
      constants.API_ENDPOINT_AUTHORIZE,
      constants.API_ENDPOINT_ACCESS_TOKEN,
      oauth1.SignatureMethods.hmacSha1,
    ),
  );
  
  oauth1.AuthorizationResponse? authRes;
  String _authUrl = "";
  
  
  void requestAuthUrl() {
    debugPrint('request temporary credentials (request tokens)');
    auth.requestTemporaryCredentials().then((res) {
      authRes = res;
      _setWebViewUrl(auth.getResourceOwnerAuthorizationURI(res.credentials.token));
    });
  }
  
  void completeAuth(String token, String verifier) async {
    //_invokeRefreshIndicator();
    if (token != (authRes?.credentials.token ?? '')) {
      _onProcessError('token doesnt match: $token and ${authRes?.credentials.token}');
      return;
    }
    
    
    oauth1.AuthorizationResponse authorizationRes = await auth.requestTokenCredentials(authRes!.credentials, verifier);
    debugPrint('got token credentials => create Client object');
    final oauth1.Client client = oauth1.Client(
        platform.signatureMethod, 
        clientCredentials, 
        authorizationRes.credentials
    );

    
    debugPrint('Now can access protected resources via client');
    http.Response res = await client.post(Uri.parse(constants.API_ENDPOINT_USER_ACCESS));
    if (res.statusCode != 200) {
      _onProcessError('an error occurred');
      return;
    }
    
    
    debugPrint('Got access to permanent token and basic user info');
    final parsed = json.decode(res.body);
    String wsUserid = parsed['wsuserid'];
    String numberUSP = parsed['loginUsuario'];
    String userName = parsed['nomeUsuario'];

    
    debugPrint('Going to register/subscribe received token');   
    Map<String, String> subscribeBody = {
      'token' : wsUserid, 
      'app': "AppEcard",
    };
    http.Response subscribeRes = await http.post(
      Uri.parse(constants.API_ENDPOINT_REGISTER),
      headers: {'Content-Type' : 'application/json;charset=utf-8'},
      body: json.encode(subscribeBody),
      encoding: Encoding.getByName("utf-8"),
    );
    if (subscribeRes.statusCode != 200) {
      _onProcessError('error when subscribing; ${subscribeRes.statusCode}; ${subscribeRes.body};');
      return;
    }

    
    debugPrint('Subscription was successful, now saving information!'); 
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(constants.PREF_WS_USER_ID, wsUserid);
    prefs.setString(constants.PREF_NUMBER_USP, numberUSP);
    prefs.setString(constants.PREF_USER_NAME, userName);
    
    Navigator.pop(context);
  }
  
  @override
  void initState() {
    super.initState();
    requestAuthUrl();
  }

  @override
  void dispose() {
    _webViewController?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(statusBarColor: Colors.orange),
        backgroundColor: Colors.orange,
      ),
      body: EasyRefresh(
        header: MaterialHeader(),
        child: _buildWebView(),
        controller: _refreshController,
        enableControlFinishRefresh: true,
        enableControlFinishLoad: true,
        onRefresh: () async {
          debugPrint('on refresh');
          requestAuthUrl();
        },
        onLoad: () async {
          debugPrint('on load');
        },
      ),
    );
  }

  Widget _buildWebView() {
    return WebViewX(
      key: const ValueKey('webviewx'),
      height: _screenSize.height,
      width: _screenSize.width,
      onWebViewCreated: (controller) {
        _webViewController = controller;
        _setWebViewUrl(_authUrl);
      },
      onWebResourceError: (error) {
        debugPrint('onWebResourceError $error');
      },
      
      navigationDelegate: (navigation) {
        debugPrint("navigationDelegate ${navigation.content.source}");
        debugPrint(navigation.content.sourceType.toString());
        
        final src = navigation.content.source;
        Uri uri = Uri.parse(src);

        if (uri.authority.startsWith("localhost")) {
          debugPrint('credentials inputted, now completing auth');
          completeAuth(
            uri.queryParameters['oauth_token'] ?? '',
            uri.queryParameters['oauth_verifier'] ?? '',
          );
          return NavigationDecision.prevent;
        }
        else if (src != _authUrl) {
          debugPrint('updating url to new one');
          _setWebViewUrl(_authUrl);
          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
    );
  }

  void _setWebViewUrl(String newUrl) {
    if (newUrl == '') return;
    
    _authUrl = newUrl;
    _webViewController?.loadContent(
      newUrl,
      SourceType.url,
    );
    _refreshController.resetRefreshState();
  }
  
  void _invokeRefreshIndicator() {
    _refreshController.callRefresh();
  }
  
  void _onProcessError(String msg) {
    debugPrint(msg);
    _refreshController.finishRefresh(success: true, noMore: true);
  }
}
