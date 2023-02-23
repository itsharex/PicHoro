import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:f_logs/f_logs.dart';
import 'package:path_provider/path_provider.dart';

import 'package:horopic/utils/global.dart';
import 'package:horopic/utils/sql_utils.dart';
import 'package:horopic/utils/common_functions.dart';
import 'package:horopic/picture_host_configure/configure_page/alist_configure.dart';

class AlistManageAPI {
  static Map driverTranslate = {
    '115 Cloud': '115网盘',
    '123Pan': '123云盘',
    '139Yun': '中国移动云盘',
    '189Cloud': '天翼云盘',
    '189CloudPC': '天翼云盘客户端',
    'AList V2': 'Alist V2',
    'AList V3': 'Alist V3',
    'Aliyundrive': '阿里云盘',
    'AliyundriveShare': '阿里云盘分享',
    'BaiduNetdisk': '百度网盘',
    'BaiduPhoto': '一刻相册',
    'FTP': 'FTP',
    'GoogleDrive': '谷歌云盘',
    'GooglePhoto': '谷歌相册',
    'Lanzou': '蓝奏云',
    'Local': '本机存储',
    'MediaTrack': '分秒帧',
    'Mega_nz': 'MEGA.nz',
    'Onedrive': 'OneDrive',
    'PikPak': 'PikPak',
    'Quark': '夸克',
    'S3': 'S3',
    'SFTP': 'SFTP',
    'SMB': 'SMB',
    'Teambition': 'Teambition网盘',
    'Thunder': '迅雷',
    'ThunderExpert': '迅雷专家版',
    'USS': '又拍云存储',
    'Virtual': '虚拟存储',
    'WebDav': 'WebDav',
    'YandexDisk': 'YandexDisk',
  };

  static Future<File> get _localFile async {
    final path = await _localPath;
    String defaultUser = await Global.getUser();
    return File('$path/${defaultUser}_alist_config.txt');
  }

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<String> readAlistConfig() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return contents;
    } catch (e) {
      FLog.error(
          className: 'AlistManageAPI',
          methodName: 'readAlistConfig',
          text: formatErrorMessage({}, e.toString()),
          dataLogType: DataLogType.ERRORS.toString());
      return "Error";
    }
  }

  static Future<Map> getConfigMap() async {
    String configStr = await readAlistConfig();
    Map configMap = json.decode(configStr);
    return configMap;
  }

  static isString(var variable) {
    return variable is String;
  }

  static isFile(var variable) {
    return variable is File;
  }

  static getToken(String host, String username, String password) async {
    String url = '$host/api/auth/login';
    Map<String, dynamic> queryParameters = {
      'Password': password,
      'Username': username,
    };

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Content-Type": "application/json",
    };
    Dio dio = Dio(baseoptions);

    try {
      var response = await dio.post(url, data: queryParameters);
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return ['success', response.data['data']['token']];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getToken",
            text: formatErrorMessage({
              'host': host,
            }, e.toString(), isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getToken",
            text: formatErrorMessage({
              'host': host,
            }, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static refreshToken() async {
    Map configMap = await getConfigMap();
    String uploadPath = configMap['uploadPath'];
    String token = configMap['token'];
    var res = await AlistManageAPI.getToken(
        configMap['host'], configMap['alistusername'], configMap['password']);
    if (res[0] == 'success') {
      token = res[1];
      String sqlResult = '';
      try {
        List sqlconfig = [];
        sqlconfig.add(configMap['host']);
        sqlconfig.add(configMap['alistusername']);
        sqlconfig.add(configMap['password']);
        sqlconfig.add(token);
        sqlconfig.add(uploadPath);
        String defaultUser = await Global.getUser();
        sqlconfig.add(defaultUser);
        var queryalist = await MySqlUtils.queryAlist(username: defaultUser);
        var queryuser = await MySqlUtils.queryUser(username: defaultUser);
        if (queryuser == 'Empty') {
          return ['failed'];
        } else if (queryalist == 'Empty') {
          sqlResult = await MySqlUtils.insertAlist(content: sqlconfig);
        } else {
          sqlResult = await MySqlUtils.updateAlist(content: sqlconfig);
        }
      } catch (e) {
        return ['failed'];
      }
      if (sqlResult == "Success") {
        final alistConfig = AlistConfigModel(
          configMap['host'],
          configMap['alistusername'],
          configMap['password'],
          token,
          uploadPath,
        );
        final alistConfigJson = jsonEncode(alistConfig);
        final alistConfigFile = await AlistConfigState().localFile;
        alistConfigFile.writeAsString(alistConfigJson);
      } else {
        return ['failed'];
      }
      return ['success', token];
    } else {
      return ['failed'];
    }
  }

  static getBucketList() async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/admin/storage/list';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
    };
    Dio dio = Dio(baseoptions);

    try {
      var response = await dio.get(
        url,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return ['success', response.data['data']];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getBucketList",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getBucketList",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static changeBucketState(Map element, bool enable) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String enableUrl = '$host/api/admin/storage/enable';
    String disableUrl = '$host/api/admin/storage/disable';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
    };
    Map<String, dynamic> queryParameters = {
      'id': element['id'],
    };
    Dio dio = Dio(baseoptions);
    try {
      Response response;
      if (enable) {
        response = await dio.post(
          enableUrl,
          queryParameters: queryParameters,
        );
      } else {
        response = await dio.post(
          disableUrl,
          queryParameters: queryParameters,
        );
      }
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "changeBucketState",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "changeBucketState",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static deleteBucket(Map element) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/admin/storage/delete';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
    };
    Map<String, dynamic> queryParameters = {
      'id': element['id'],
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        queryParameters: queryParameters,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "deleteBucket",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "deleteBucket",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static createBucket(Map newBucketConfig) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/admin/storage/create';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        data: newBucketConfig,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "createBucket",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "createBucket",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static updateBucket(Map newBucketConfig) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/admin/storage/update';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        data: newBucketConfig,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return [
          'success',
        ];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "updateBucket",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "updateBucket",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static setDefaultBucket(String path) async {
    try {
      Map configMap = await getConfigMap();
      String host = configMap['host'];
      String alistusername = configMap['alistusername'];
      String password = configMap['password'];
      String token = configMap['token'];
      String uploadPath = path;

      if (uploadPath == '/' || uploadPath == '') {
        uploadPath = 'None';
      }
      List sqlconfig = [];
      sqlconfig.add(host);
      sqlconfig.add(alistusername);
      sqlconfig.add(password);
      sqlconfig.add(token);
      sqlconfig.add(uploadPath);
      String defaultUser = await Global.getUser();
      sqlconfig.add(defaultUser);
      var queryAlist = await MySqlUtils.queryAlist(username: defaultUser);
      var queryuser = await MySqlUtils.queryUser(username: defaultUser);

      if (queryuser == 'Empty') {
        return ['failed'];
      }
      var sqlResult = '';

      if (queryAlist == 'Empty') {
        sqlResult = await MySqlUtils.insertAlist(content: sqlconfig);
      } else {
        sqlResult = await MySqlUtils.updateAlist(content: sqlconfig);
      }

      if (sqlResult == "Success") {
        final alistConfig = AlistConfigModel(
          host,
          alistusername,
          password,
          token,
          uploadPath,
        );
        final alistConfigJson = jsonEncode(alistConfig);
        final alistConfigFile = await _localFile;
        await alistConfigFile.writeAsString(alistConfigJson);
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      FLog.error(
          className: "AlistManageAPI",
          methodName: "setDefaultBucket",
          text: formatErrorMessage({
            'path': path,
          }, e.toString()),
          dataLogType: DataLogType.ERRORS.toString());
      return ['failed'];
    }
  }

  static getTotalPage(
    String folder,
    String refresh,
  ) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/fs/list';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Map<String, dynamic> dataMap = {
      "page": 1,
      "path": folder,
      "per_page": 1,
      "refresh": refresh == 'Refresh' ? true : false,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        data: dataMap,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        if (response.data['data']['total'] == 0) {
          return ['success', 0];
        }
        int totalPage = (response.data['data']['total'] / 50).ceil();
        return ['success', totalPage];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getTotalPage",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getTotalPage",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static listFolderByPage(String folder, String refresh, int page) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/fs/list';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Map<String, dynamic> dataMap = {
      "page": page,
      "path": folder,
      "per_page": 50,
      "refresh": refresh == 'Refresh' ? true : false,
    };
    Dio dio = Dio(baseoptions);
    List fileList = [];
    try {
      var response = await dio.post(
        url,
        data: dataMap,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        if (response.data['data']['total'] == 0) {
          return ['success', fileList];
        }
        fileList = response.data['data']['content'];

        return ['success', fileList];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "listFolderByPage",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "listFolderByPage",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static listFolder(String folder, String refresh) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/fs/list';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    int startPage = 1;
    Map<String, dynamic> dataMap = {
      "page": startPage,
      "path": folder,
      "per_page": 1000,
      "refresh": refresh == 'Refresh' ? true : false,
    };
    Dio dio = Dio(baseoptions);
    List fileList = [];
    try {
      var response = await dio.post(
        url,
        data: dataMap,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        if (response.data['data']['total'] == 0) {
          return ['success', fileList];
        }
        fileList = response.data['data']['content'];
        if (response.data['data']['total'] > 1000) {
          showToast('${response.data['data']['total']}文件 可能需要较长时间');
          int totalPage = (response.data['data']['total'] / 1000).ceil();
          for (int i = 2; i <= totalPage; i++) {
            dataMap['page'] = i;
            response = await dio.post(
              url,
              data: dataMap,
            );
            if (response.statusCode == 200 &&
                response.data['message'] == 'success') {
              if (response.data['data']['total'] == 0) {
                return ['success', fileList];
              }
              fileList.addAll(response.data['data']['content']);
            } else {
              return ['failed'];
            }
          }
        }

        return ['success', fileList];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "listFolder",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "listFolder",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static getFileInfo(String path) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/fs/get';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Map<String, dynamic> dataMap = {
      "path": path,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        data: dataMap,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return ['success', response.data['data']];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getFileInfo",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "getFileInfo",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static mkDir(String path) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/fs/mkdir';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Map<String, dynamic> dataMap = {
      "path": path,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        data: dataMap,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "mkDir",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "mkDir",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static rename(String source, String target) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/fs/rename';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Map<String, dynamic> dataMap = {
      "path": source,
      "name": target,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        data: dataMap,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "rename",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "rename",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static remove(String dir, List names) async {
    Map configMap = await getConfigMap();
    String host = configMap['host'];
    String token = configMap['token'];
    String url = '$host/api/fs/remove';

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": token,
      "Content-Type": "application/json",
    };
    Map<String, dynamic> dataMap = {
      "dir": dir,
      "names": names,
    };
    Dio dio = Dio(baseoptions);
    try {
      var response = await dio.post(
        url,
        data: dataMap,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "remove",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "remove",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  static uploadFile(String filename, String filepath, String uploadPath) async {
    Map configMap = await getConfigMap();
    if (uploadPath == 'None') {
      uploadPath = '/';
    } else {
      if (!uploadPath.startsWith('/')) {
        uploadPath = '/$uploadPath';
      }
      if (!uploadPath.endsWith('/')) {
        uploadPath = '$uploadPath/';
      }
    }
    String filePath = uploadPath + filename;
    FormData formdata = FormData.fromMap({
      "file": await MultipartFile.fromFile(filepath, filename: filename),
    });
    File uploadFile = File(filepath);
    int contentLength = await uploadFile.length().then((value) {
      return value;
    });

    BaseOptions baseoptions = setBaseOptions();
    baseoptions.headers = {
      "Authorization": configMap["token"],
      "Content-Type": Global.multipartString,
      "file-path": Uri.encodeComponent(filePath),
      "Content-Length": contentLength,
    };
    Dio dio = Dio(baseoptions);
    String uploadUrl = configMap["host"] + "/api/fs/form";
    try {
      var response = await dio.put(
        uploadUrl,
        data: formdata,
      );
      if (response.statusCode == 200 && response.data['message'] == 'success') {
        return ['success'];
      } else {
        return ['failed'];
      }
    } catch (e) {
      if (e is DioError) {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "uploadFile",
            text: formatErrorMessage({}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "uploadFile",
            text: formatErrorMessage({}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return [e.toString()];
    }
  }

  //从网络链接下载文件后上传
  static uploadNetworkFile(String fileLink, String uploadPath) async {
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
          filename,
          saveFilePath,
          uploadPath,
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
            className: "AlistManageAPI",
            methodName: "uploadNetworkFile",
            text: formatErrorMessage(
                {'fileLink': fileLink, 'uploadPath': uploadPath}, e.toString(),
                isDioError: true, dioErrorMessage: e),
            dataLogType: DataLogType.ERRORS.toString());
      } else {
        FLog.error(
            className: "AlistManageAPI",
            methodName: "uploadNetworkFile",
            text: formatErrorMessage(
                {'fileLink': fileLink, 'uploadPath': uploadPath}, e.toString()),
            dataLogType: DataLogType.ERRORS.toString());
      }
      return ['failed'];
    }
  }

  static uploadNetworkFileEntry(List fileList, String uploadPath) async {
    int successCount = 0;
    int failCount = 0;

    for (String fileLink in fileList) {
      if (fileLink.isEmpty) {
        continue;
      }
      var uploadResult = await uploadNetworkFile(fileLink, uploadPath);
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
