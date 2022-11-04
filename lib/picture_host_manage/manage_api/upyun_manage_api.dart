import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:f_logs/f_logs.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

import 'package:horopic/utils/global.dart';
import 'package:horopic/utils/sql_utils.dart';
import 'package:horopic/utils/common_functions.dart';
import 'package:horopic/picture_host_configure/upyun_configure.dart';

//又拍云的API文档，写的是真的简陋
class UpyunManageAPI {
  static Map<String?, String> tagConvert = {
    'download': '文件下载',
    'picture': '网页图片',
    'vod': '音视频点播',
    null: '未知',
  };

  static String upyunBaseURL = 'v0.api.upyun.com';
  static String upyunManageURL = 'https://api.upyun.com/';

  static Future<File> get _localFile async {
    final path = await _localPath;
    String defaultUser = await Global.getUser();
    return File('$path/${defaultUser}_upyun_config.txt');
  }

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> readUpyunConfig() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      FLog.error(
          className: 'UpyunManageAPI',
          methodName: 'readUpyunConfig',
          text: formatErrorMessage({}, e.toString()),
          dataLogType: DataLogType.ERRORS.toString());
      return "Error";
    }
  }

  static Future<Map> getConfigMap() async {
    String configStr = await readUpyunConfig();
    Map configMap = json.decode(configStr);
    return configMap;
  }

  static getUpyunManageConfigMap() async {
    var queryUpyunManage =
        await MySqlUtils.queryUpyunManage(username: Global.defaultUser);
    if (queryUpyunManage == 'Erorr' || queryUpyunManage == 'Empty') {
      return 'Error';
    } else {
      Map upyunManageConfigMap = {
        'email': queryUpyunManage['email'],
        'password': queryUpyunManage['password'],
        'token': queryUpyunManage['token'],
      };
      return upyunManageConfigMap;
    }
  }

  static isString(var variable) {
    return variable is String;
  }

  static isFile(var variable) {
    return variable is File;
  }

  //get MD5
  static getContentMd5(var variable) async {
    if (isString(variable)) {
      return base64.encode(md5.convert(utf8.encode(variable)).bytes);
    } else if (isFile(variable)) {
      List<int> bytes = await variable.readAsBytes();
      return base64.encode(md5.convert(bytes).bytes);
    } else {
      return "";
    }
  }

  //get authorization
  static Future<String> upyunAuthorization(
    String method,
    String uri,
    String contentMd5,
    String operatorName,
    String operatorPassword,
  ) async {
    try {
      String passwordMd5 =
          md5.convert(utf8.encode(operatorPassword)).toString();
      method = method.toUpperCase();
      String date = HttpDate.format(DateTime.now());
      String stringToSing = '';
      String codedUri = Uri.encodeFull(uri);
      if (contentMd5 == '') {
        stringToSing = '$method&$codedUri&$date';
      } else {
        stringToSing = '$method&$codedUri&$date&$contentMd5';
      }
      String signature = base64.encode(Hmac(sha1, utf8.encode(passwordMd5))
          .convert(utf8.encode(stringToSing))
          .bytes);

      String authorization = 'UPYUN $operatorName:$signature';
      return authorization;
    } catch (e) {
      FLog.error(
          className: 'UpyunManageAPI',
          methodName: 'upyunAuthorization',
          text: formatErrorMessage({
            'method': method,
            'uri': uri,
            'contentMd5': contentMd5,
          }, e.toString()),
          dataLogType: DataLogType.ERRORS.toString());
      return "";
    }
  }

  static getToken(String email, String password) async {
    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    String randomString = randomStringGenerator(32);
    String randomStringForName = randomStringGenerator(20);
    Dio dio = Dio(baseoptions);
    Map<String, dynamic> params = {
      'username': email,
      'password': password,
      'code': randomString,
      'name': randomStringForName,
      'scope': 'global',
    };
    try {
      var response = await dio.post(
        'https://api.upyun.com/oauth/tokens',
        data: jsonEncode(params),
      );
      if (response.statusCode == 200) {
        return ['success', response.data];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getToken",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getToken",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return ['failed'];
    }
  }

  static checkToken(String token) async {
    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.get(
        'https://api.upyun.com/oauth/tokens',
      );
      if (response.statusCode == 200) {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "checkToken",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "checkToken",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return ['failed'];
    }
  }

  static deleteToken(String token, String tokenname) async {
    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Map<String, dynamic> params = {
      'name': tokenname,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.delete(
        'https://api.upyun.com/oauth/tokens',
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteToken",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteToken",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return ['failed'];
    }
  }

  static getBucketList() async {
    var configMap = await getUpyunManageConfigMap();
    if (configMap == 'Error') {
      return ['failed'];
    }
    String token = configMap['token'];

    String host = 'https://api.upyun.com/buckets';

    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
      'limit': '100',
      'business_type': 'file',
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.get(
        host,
      );
      if (response.statusCode == 200) {
        return ['success', response.data['buckets']];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getBucketList",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getBucketList",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static getBucketInfo(String bucketName) async {
    var configMap = await getUpyunManageConfigMap();
    if (configMap == 'Error') {
      return ['failed'];
    }
    String token = configMap['token'];

    String host = 'https://api.upyun.com/buckets/info';

    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Map<String, dynamic> params = {
      'bucket_name': bucketName,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.get(
        host,
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        return ['success', response.data];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getBucketInfo",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getBucketInfo",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static deleteBucket(String bucketName) async {
    var configMap = await getUpyunManageConfigMap();
    if (configMap == 'Error') {
      return ['failed'];
    }
    String token = configMap['token'];
    String password = configMap['password'];
    String host = 'https://api.upyun.com/buckets/delete';

    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Map<String, dynamic> params = {
      'bucket_name': bucketName,
      'password': password,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        host,
        data: params,
      );
      if (response.statusCode == 200) {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteBucket",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteBucket",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static putBucket(String bucketName) async {
    var configMap = await getUpyunManageConfigMap();
    if (configMap == 'Error') {
      return ['failed'];
    }
    String token = configMap['token'];
    String host = 'https://api.upyun.com/buckets';

    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Map<String, dynamic> params = {
      'bucket_name': bucketName,
      'type': 'file',
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.put(
        host,
        data: params,
      );
      if (response.statusCode == 201) {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "putBucket",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "putBucket",
            text: formatErrorMessage({
              'bucketName': bucketName,
            }, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static getOperator(String bucketName) async {
    var configMap = await getUpyunManageConfigMap();
    if (configMap == 'Error') {
      return ['failed'];
    }
    String token = configMap['token'];
    String host = 'https://api.upyun.com/buckets/operators';

    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Map<String, dynamic> params = {
      'bucket_name': bucketName,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.get(
        host,
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        return ['success', response.data['operators']];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getOperator",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "getOperator",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static addOperator(String bucketName, String operatorName) async {
    var configMap = await getUpyunManageConfigMap();
    if (configMap == 'Error') {
      return ['failed'];
    }
    String token = configMap['token'];
    String host = 'https://api.upyun.com/buckets/operators';

    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Map<String, dynamic> params = {
      'bucket_name': bucketName,
      'operator_name': operatorName,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.put(
        host,
        data: params,
      );
      if (response.statusCode == 201) {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "putOperator",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "putOperator",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static deleteOperator(String bucketName, String operatorName) async {
    var configMap = await getUpyunManageConfigMap();
    if (configMap == 'Error') {
      return ['failed'];
    }
    String token = configMap['token'];
    String host = 'https://api.upyun.com/buckets/operators';

    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': 'Bearer $token',
    };
    Map<String, dynamic> params = {
      'bucket_name': bucketName,
      'operator_name': operatorName,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.delete(
        host,
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteOperator",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteOperator",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  //存储桶设为默认图床
  static setDefaultBucketFromListPage(
      Map element, Map upyunManageConfigMap, Map textMap) async {
    try {
      String bucket = element['bucket_name'];
      String usernameEmailBucket =
          '${Global.defaultUser}_${upyunManageConfigMap['email']}_${element['bucket_name']}';
      var queryOperator =
          await MySqlUtils.queryUpyunOperator(username: usernameEmailBucket);
      if (queryOperator == 'Error' || queryOperator == 'Empty') {
        return ['failed'];
      }
      String operatorName = queryOperator['operator'];
      String operatorPassword = queryOperator['password'];
      String httpPrefix = 'http://';
      String url = '';
      if (element['https'] == true) {
        httpPrefix = 'https://';
      }
      if (element['domains'] == null || element['domains'].length == 0) {
        return ['failed'];
      }
      if (element['domains'].toString().startsWith('https//') ||
          element['domains'].toString().startsWith('http//')) {
        url = element['domains'];
      } else {
        url = httpPrefix + element['domains'];
      }

      String options = textMap['option'];
      String path = textMap['path'];
      if (path.isEmpty || path.replaceAll(' ', '').isEmpty) {
        path = 'None';
      } else {
        if (!path.endsWith('/')) {
          path = '$path/';
        }
        if (path.startsWith('/')) {
          path = path.substring(1);
        }
      }

      List sqlconfig = [];
      sqlconfig.add(bucket);
      sqlconfig.add(operatorName);
      sqlconfig.add(operatorPassword);
      sqlconfig.add(url);
      sqlconfig.add(options);
      sqlconfig.add(path);
      String defaultUser = await Global.getUser();
      sqlconfig.add(defaultUser);
      var queryUpyun = await MySqlUtils.queryUpyun(username: defaultUser);
      var queryuser = await MySqlUtils.queryUser(username: defaultUser);

      if (queryuser == 'Empty') {
        return ['failed'];
      }
      var sqlResult = '';

      if (queryUpyun == 'Empty') {
        sqlResult = await MySqlUtils.insertUpyun(content: sqlconfig);
      } else {
        sqlResult = await MySqlUtils.updateUpyun(content: sqlconfig);
      }

      if (sqlResult == "Success") {
        final upyunConfig = UpyunConfigModel(
            bucket, operatorName, operatorPassword, url, options, path);
        final upyunConfigJson = jsonEncode(upyunConfig);
        final upyunConfigFile = await _localFile;
        await upyunConfigFile.writeAsString(upyunConfigJson);
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      FLog.error(
          className: "UpyunManageAPI",
          methodName: "setDefaultBucketFromListPage",
          text: formatErrorMessage({}, e.toString()),
          dataLogType: DataLogType.ERRORS.toString());
      return ['failed'];
    }
  }

  static queryBucketFiles(Map element, String prefix) async {
    String method = 'GET';
    String bucket = element['bucket'];
    String uri = '/$bucket$prefix';
    String operator = element['operator'];
    String password = element['password'];
    String authorization =
        await upyunAuthorization(method, uri, '', operator, password);
    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': authorization,
      'accept': 'application/json',
      'x-list-limit': '10000',
      'Date': HttpDate.format(DateTime.now()),
    };
    String url = 'http://$upyunBaseURL$uri';
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        return ['success', response.data['files']];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "queryBucketFiles",
            text: formatErrorMessage({
              'prefix': prefix,
            }, e.toString(), isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "queryBucketFiles",
            text: formatErrorMessage({
              'prefix': prefix,
            }, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  //判断是否为空存储桶
  static isEmptyBucket(Map element) async {
    var queryResult = await queryBucketFiles(element, '/');
    if (queryResult[0] == 'success') {
      if (queryResult[1].length == 0) {
        return ['empty'];
      } else {
        return ['notempty'];
      }
    } else {
      return ['error'];
    }
  }

  //新建文件夹
  static createFolder(Map element, String prefix, String newfolder) async {
    String method = 'POST';
    String bucket = element['bucket'];
    String operator = element['operator'];
    String password = element['password'];
    if (newfolder.startsWith('/')) {
      newfolder = newfolder.substring(1);
    }
    if (newfolder.endsWith('/')) {
      newfolder = newfolder.substring(0, newfolder.length - 1);
    }
    String uri = '/$bucket$prefix$newfolder/';
    String authorization =
        await upyunAuthorization(method, uri, '', operator, password);
    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': authorization,
      'folder': 'true',
      'Date': HttpDate.format(DateTime.now()),
    };

    String url = 'http://$upyunBaseURL$uri';

    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(url);
      if (response.statusCode == 200) {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "createFolder",
            text: formatErrorMessage({
              'prefix': prefix,
              'newfolder': newfolder,
            }, e.toString(), isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "createFolder",
            text: formatErrorMessage({
              'prefix': prefix,
              'newfolder': newfolder,
            }, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  //删除文件
  static deleteFile(Map element, String prefix, String key) async {
    String method = 'DELETE';
    String bucket = element['bucket'];
    String operator = element['operator'];
    String password = element['password'];
    if (!prefix.startsWith('/')) {
      prefix = '/$prefix';
    }
    if (!prefix.endsWith('/')) {
      prefix = '$prefix/';
    }
    String uri = '/$bucket$prefix$key';
    String authorization =
        await upyunAuthorization(method, uri, '', operator, password);
    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': authorization,
      'Date': HttpDate.format(DateTime.now()),
    };

    String url = 'http://$upyunBaseURL$uri';
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.delete(url);
      if (response.statusCode == 200) {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteFile",
            text: formatErrorMessage({
              'prefix': prefix,
              'key': key,
            }, e.toString(), isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteFile",
            text: formatErrorMessage({
              'prefix': prefix,
              'key': key,
            }, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  //删除文件夹
  static deleteFolder(Map element, String prefix) async {
    var queryResult = await queryBucketFiles(element, prefix);
    try {
      if (queryResult[0] == 'success') {
        List files = [];
        List folders = [];
        for (var item in queryResult[1]) {
          if (item['type'] == 'folder') {
            folders.add(item['name']);
          } else {
            files.add(item['name']);
          }
        }
        if (files.isNotEmpty) {
          for (var item in files) {
            var deleteResult = await deleteFile(element, prefix, item);
            if (deleteResult[0] != 'success') {
              return ['failed'];
            }
          }
        }
        if (folders.isNotEmpty) {
          for (var item in folders) {
            var deleteResult = await deleteFolder(element, '$prefix/$item');
            if (deleteResult[0] != 'success') {
              return ['failed'];
            }
          }
        }
        var deleteSelfResult = await deleteFile(
            element,
            prefix.substring(
                0, prefix.length - prefix.split('/').last.length - 1),
            prefix.split('/').last);
        if (deleteSelfResult[0] != 'success') {
          return ['failed'];
        }
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteFolder",
            text: formatErrorMessage({
              'prefix': prefix,
            }, e.toString(), isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "deleteFolder",
            text: formatErrorMessage({
              'prefix': prefix,
            }, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return ['failed'];
    }
  }

  //目录设为默认图床
  static setDefaultBucket(Map element, String? folder) async {
    try {
      Map configMap = await getConfigMap();
      String bucket = element['bucket'];
      String operatorName = element['operator'];
      String operatorPassword = element['password'];
      String url = element['url'];
      String options = configMap['options'];
      String path = '';
      if (folder == null) {
        path = configMap['path'];
      } else {
        path = folder;
      }
      if (path.isEmpty || path.replaceAll(' ', '').isEmpty) {
        path = 'None';
      } else {
        if (!path.endsWith('/')) {
          path = '$path/';
        }
        if (path.startsWith('/')) {
          path = path.substring(1);
        }
      }

      List sqlconfig = [];
      sqlconfig.add(bucket);
      sqlconfig.add(operatorName);
      sqlconfig.add(operatorPassword);
      sqlconfig.add(url);
      sqlconfig.add(options);
      sqlconfig.add(path);
      String defaultUser = await Global.getUser();
      sqlconfig.add(defaultUser);
      var queryUpyun = await MySqlUtils.queryUpyun(username: defaultUser);
      var queryuser = await MySqlUtils.queryUser(username: defaultUser);

      if (queryuser == 'Empty') {
        return ['failed'];
      }
      var sqlResult = '';

      if (queryUpyun == 'Empty') {
        sqlResult = await MySqlUtils.insertUpyun(content: sqlconfig);
      } else {
        sqlResult = await MySqlUtils.updateUpyun(content: sqlconfig);
      }

      if (sqlResult == "Success") {
        final upyunConfig = UpyunConfigModel(
            bucket, operatorName, operatorPassword, url, options, path);
        final upyunConfigJson = jsonEncode(upyunConfig);
        final upyunConfigFile = await _localFile;
        await upyunConfigFile.writeAsString(upyunConfigJson);
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      FLog.error(
          className: "UpyunManageAPI",
          methodName: "setDefaultBucket",
          text: formatErrorMessage({'folder': folder}, e.toString()),
          dataLogType: DataLogType.ERRORS.toString());
      return ['failed'];
    }
  }

  //重命名文件
  static renameFile(
      Map element, String prefix, String key, String newKey) async {
    String method = 'PUT';

    String bucket = element['bucket'];
    String operatorName = element['operator'];
    String operatorPassword = element['password'];
    if (newKey.startsWith('/')) {
      newKey = newKey.substring(1);
    }
    if (newKey.endsWith('/')) {
      newKey = newKey.substring(0, newKey.length - 1);
    }
    String xUpyunMoveSource = '/$bucket$prefix$key';
    String uri = '/$bucket$prefix$newKey';
    String authorization = await upyunAuthorization(
        method, uri, '', operatorName, operatorPassword);
    BaseOptions baseoptions = BaseOptions(
      sendTimeout: 30000,
      receiveTimeout: 30000,
      connectTimeout: 30000,
    );
    baseoptions.headers = {
      'Authorization': authorization,
      'Date': HttpDate.format(DateTime.now()),
      'X-Upyun-Move-Source': xUpyunMoveSource,
      'Content-Length': '0',
    };
    String url = 'http://$upyunBaseURL$uri';
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.put(url);
      if (response.statusCode == 200) {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "renameFile",
            text: formatErrorMessage(
                {'prefix': prefix, 'key': key, 'newKey': newKey}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "renameFile",
            text: formatErrorMessage(
                {'prefix': prefix, 'key': key, 'newKey': newKey}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  //查询是否有重名文件
  static queryDuplicateName(Map element, String prefix, String key) async {
    var queryResult = await queryBucketFiles(element, prefix);
    if (queryResult[0] == 'success') {
      for (var i = 0; i < queryResult[1].length; i++) {
        if (queryResult[1][i]['name'] == key) {
          return ['duplicate'];
        }
      }
      return ['notduplicate'];
    } else {
      return ['error'];
    }
  }

  //上传文件
  static uploadFile(
    Map element,
    String filename,
    String filepath,
    String prefix,
  ) async {
    String bucket = element['bucket'];
    String upyunOperator = element['operator'];
    String password = element['password'];
    String url = element['url'];

    if (url != "None") {
      if (!url.startsWith('http') && !url.startsWith('https')) {
        url = 'http://$url';
      }
    }
    String host = 'http://v0.api.upyun.com';
    //云存储的路径
    String urlpath = '';
    if (prefix != 'None') {
      urlpath = '/$prefix$filename';
    } else {
      urlpath = '/$filename';
    }
    String date = HttpDate.format(DateTime.now());
    File uploadFile = File(filepath);
    String uploadFileMd5 = await uploadFile.readAsBytes().then((value) {
      return md5.convert(value).toString();
    });
    Map<String, dynamic> uploadPolicy = {
      'bucket': bucket,
      'save-key': urlpath,
      'expiration': DateTime.now().millisecondsSinceEpoch + 1800000,
      'date': date,
      'content-md5': uploadFileMd5,
    };
    String base64Policy = base64.encode(utf8.encode(json.encode(uploadPolicy)));
    String stringToSign = 'POST&/$bucket&$date&$base64Policy&$uploadFileMd5';
    String passwordMd5 = md5.convert(utf8.encode(password)).toString();
    String signature = base64.encode(Hmac(sha1, utf8.encode(passwordMd5))
        .convert(utf8.encode(stringToSign))
        .bytes);
    String authorization = 'UPYUN $upyunOperator:$signature';
    FormData formData = FormData.fromMap({
      'authorization': authorization,
      'policy': base64Policy,
      'file': await MultipartFile.fromFile(filepath, filename: filename),
    });
    BaseOptions baseoptions = BaseOptions(
      //连接服务器超时时间，单位是毫秒.
      connectTimeout: 30000,
      //响应超时时间。
      receiveTimeout: 30000,
      sendTimeout: 30000,
    );
    String contentLength = await uploadFile.length().then((value) {
      return value.toString();
    });
    baseoptions.headers = {
      'Host': 'v0.api.upyun.com',
      'Content-Type':
          'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW',
      'Content-Length': contentLength,
      'Date': date,
      'Authorization': authorization,
      'Content-MD5': uploadFileMd5,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        '$host/$bucket',
        data: formData,
      );
      if (response.statusCode == 200) {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "uploadFile",
            text: formatErrorMessage({
              'filename': filename,
              'filepath': filepath,
              'prefix': prefix
            }, e.toString(), isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "uploadFile",
            text: formatErrorMessage(
                {'filename': filename, 'filepath': filepath, 'prefix': prefix},
                e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return ['error'];
    }
  }

  //从网络链接下载文件后上传
  static uploadNetworkFile(String fileLink, Map element, String prefix) async {
    try {
      String filename =
          fileLink.substring(fileLink.lastIndexOf("/") + 1, fileLink.length);
      filename = filename.substring(
          0, !filename.contains("?") ? filename.length : filename.indexOf("?"));
      String savePath = await getTemporaryDirectory().then((value) {
        return value.path;
      });
      String saveFilePath = '$savePath/$filename';
      Dio dio = Dio();
      Response response = await dio.download(fileLink, saveFilePath);
      if (response.statusCode == 200) {
        var uploadResult = await uploadFile(
          element,
          filename,
          saveFilePath,
          prefix,
        );
        if (uploadResult[0] == "success") {
          return ['success'];
        } else {
          return ['failed'];
        }
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "uploadNetworkFile",
            text: formatErrorMessage(
                {'fileLink': fileLink, 'prefix': prefix}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "UpyunManageAPI",
            methodName: "uploadNetworkFile",
            text: formatErrorMessage(
                {'fileLink': fileLink, 'prefix': prefix}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return ['failed'];
    }
  }

  static uploadNetworkFileEntry(
      List fileList, Map element, String prefix) async {
    int successCount = 0;
    int failCount = 0;

    for (String fileLink in fileList) {
      if (fileLink.isEmpty) {
        continue;
      }
      var uploadResult = await uploadNetworkFile(fileLink, element, prefix);
      if (uploadResult[0] == "success") {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (successCount == 0) {
      return Fluttertoast.showToast(
          msg: '上传失败',
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 2,
          fontSize: 16.0);
    } else if (failCount == 0) {
      return Fluttertoast.showToast(
          msg: '上传成功',
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 2,
          fontSize: 16.0);
    } else {
      return Fluttertoast.showToast(
          msg: '成功$successCount,失败$failCount',
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 2,
          fontSize: 16.0);
    }
  }
}
