import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_proxy_adapter/dio_proxy_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as my_path;

import 'package:horopic/pages/upload_pages/upload_request.dart';
import 'package:horopic/pages/upload_pages/upload_status.dart';
import 'package:horopic/pages/upload_pages/upload_task.dart';
import 'package:horopic/utils/event_bus_utils.dart';
import 'package:horopic/utils/uploader.dart';
import 'package:horopic/utils/global.dart';
import 'package:horopic/utils/common_functions.dart';
import 'package:horopic/album/album_sql.dart';
import 'package:horopic/api/tencent_api.dart';
import 'package:horopic/api/qiniu_api.dart';

class UploadManager {
  final Map<String, UploadTask> _cache = <String, UploadTask>{};
  final Queue<UploadRequest> _queue = Queue();
  Dio dio = Dio();

  int maxConcurrentTasks = 2;
  int runningTasks = 0;

  static final UploadManager _instance = UploadManager._internal();

  UploadManager._internal();

  factory UploadManager({int? maxConcurrentTasks}) {
    if (maxConcurrentTasks != null) {
      _instance.maxConcurrentTasks = maxConcurrentTasks;
    }
    return _instance;
  }

  void Function(int, int) createCallback(
    String path,
  ) {
    return (int sent, int total) {
      getUpload(path)?.progress.value = sent / total;
    };
  }

  Future<void> upload(String path, canceltoken) async {
    try {
      var task = getUpload(path);

      if (task == null || task.status.value == UploadStatus.canceled) {
        return;
      }
      setStatus(task, UploadStatus.uploading);

      String fileName = path.split('/').last;
      String configData = await readPictureHostConfig();
      Map configMap = jsonDecode(configData);
      String defaultPH = await Global.getPShost();
      var response;
      if (defaultPH == 'tencent') {
        String secretId = configMap['secretId'];
        String secretKey = configMap['secretKey'];
        String bucket = configMap['bucket'];
        String area = configMap['area'];
        String tencentpath = configMap['path'];
        String customUrl = configMap['customUrl'];
        String options = configMap['options'];
        if (customUrl != "None") {
          if (!customUrl.startsWith('http') && !customUrl.startsWith('https')) {
            customUrl = 'http://$customUrl';
          }
        }

        if (tencentpath != 'None') {
          if (tencentpath.startsWith('/')) {
            tencentpath = tencentpath.substring(1);
          }
          if (!tencentpath.endsWith('/')) {
            tencentpath = '$tencentpath/';
          }
        }
        String host = '$bucket.cos.$area.myqcloud.com';
        //云存储的路径
        String urlpath = '';
        if (tencentpath != 'None') {
          urlpath = '/$tencentpath$fileName';
        } else {
          urlpath = '/$fileName';
        }
        int startTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        int endTimestamp = startTimestamp + 86400;
        String keyTime = '$startTimestamp;$endTimestamp';
        Map<String, dynamic> uploadPolicy = {
          "expiration": "2033-03-03T09:38:12.414Z",
          "conditions": [
            {"acl": "default"},
            {"bucket": bucket},
            {"key": urlpath},
            {"q-sign-algorithm": "sha1"},
            {"q-ak": secretId},
            {"q-sign-time": keyTime}
          ]
        };
        String uploadPolicyStr = jsonEncode(uploadPolicy);
        String singature = TencentImageUploadUtils.getUploadAuthorization(
            secretKey, keyTime, uploadPolicyStr);
        FormData formData = FormData.fromMap({
          'key': urlpath,
          'policy': base64Encode(utf8.encode(uploadPolicyStr)),
          'acl': 'default',
          'q-sign-algorithm': 'sha1',
          'q-ak': secretId,
          'q-key-time': keyTime,
          'q-sign-time': keyTime,
          'q-signature': singature,
          'file': await MultipartFile.fromFile(path, filename: fileName),
        });
        BaseOptions baseoptions = BaseOptions(
          //连接服务器超时时间，单位是毫秒.
          connectTimeout: 30000,
          //响应超时时间。
          receiveTimeout: 30000,
          sendTimeout: 30000,
        );
        File uploadFile = File(path);
        String contentLength = await uploadFile.length().then((value) {
          return value.toString();
        });
        baseoptions.headers = {
          'Host': host,
          'Content-Type':
              'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW',
          'Content-Length': contentLength,
        };
        response = await dio.post(
          'https://$host',
          data: formData,
          onSendProgress: createCallback(path),
          cancelToken: canceltoken,
        );
        if (response.statusCode == HttpStatus.noContent) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = '';
          String displayUrl = '';

          if (customUrl != 'None') {
            if (!customUrl.endsWith('/')) {
              returnUrl = '$customUrl$urlpath';
              displayUrl = '$customUrl$urlpath';
            } else {
              customUrl = customUrl.substring(0, customUrl.length - 1);
              returnUrl = '$customUrl$urlpath';
              displayUrl = '$customUrl$urlpath';
            }
          } else {
            returnUrl = 'https://$host$urlpath';
            displayUrl = 'https://$host$urlpath';
          }

          if (options == 'None') {
            displayUrl = "$displayUrl?imageMogr2/thumbnail/500x500";
          } else {
            //网站后缀以?开头
            if (!options.startsWith('?')) {
              options = '?$options';
            }
            returnUrl = '$returnUrl$options';
            displayUrl = '$displayUrl$options';
          }

          String formatedURL = '';
          if (Global.isCopyLink == true) {
            formatedURL =
                linkGenerateDict[Global.defaultLKformat]!(returnUrl, fileName);
          } else {
            formatedURL = returnUrl;
          }
          await Clipboard.setData(ClipboardData(text: formatedURL));

          String pictureKey = 'None';
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl, //tencent文件原始地址
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': displayUrl, //实际展示的是displayUrl
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      } else if (defaultPH == 'aliyun') {
        String keyId = configMap['keyId'];
        String keySecret = configMap['keySecret'];
        String bucket = configMap['bucket'];
        String area = configMap['area'];
        String aliyunpath = configMap['path'];
        String customUrl = configMap['customUrl'];
        String options = configMap['options'];
        //格式化
        if (customUrl != "None") {
          if (!customUrl.startsWith('http') && !customUrl.startsWith('https')) {
            customUrl = 'http://$customUrl';
          }
        }
        //格式化
        if (aliyunpath != 'None') {
          if (aliyunpath.startsWith('/')) {
            aliyunpath = aliyunpath.substring(1);
          }
          if (!aliyunpath.endsWith('/')) {
            aliyunpath = '$aliyunpath/';
          }
        }
        String host = '$bucket.$area.aliyuncs.com';
        //云存储的路径
        String urlpath = '';
        //阿里云不能以/开头
        if (aliyunpath != 'None') {
          urlpath = '$aliyunpath$fileName';
        } else {
          urlpath = fileName;
        }

        Map<String, dynamic> uploadPolicy = {
          "expiration": "2034-12-01T12:00:00.000Z",
          "conditions": [
            {"bucket": bucket},
            ["content-length-range", 0, 104857600],
            {"key": urlpath}
          ]
        };
        String base64Policy =
            base64.encode(utf8.encode(json.encode(uploadPolicy)));
        String singature = base64.encode(Hmac(sha1, utf8.encode(keySecret))
            .convert(utf8.encode(base64Policy))
            .bytes);
        FormData formData = FormData.fromMap({
          'key': urlpath,
          'OSSAccessKeyId': keyId,
          'policy': base64Policy,
          'Signature': singature,
          'x-oss-content-type':
              'image/${my_path.extension(path).replaceFirst('.', '')}',
          'file': await MultipartFile.fromFile(path, filename: fileName),
        });
        BaseOptions baseoptions = BaseOptions(
          //连接服务器超时时间，单位是毫秒.
          connectTimeout: 30000,
          //响应超时时间。
          receiveTimeout: 30000,
          sendTimeout: 30000,
        );
        File uploadFile = File(path);
        String contentLength = await uploadFile.length().then((value) {
          return value.toString();
        });
        baseoptions.headers = {
          'Host': host,
          'Content-Type':
              'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW',
          'Content-Length': contentLength,
        };
        Dio dio = Dio(baseoptions);
        response = await dio.post(
          'https://$host',
          data: formData,
          onSendProgress: createCallback(path),
          cancelToken: canceltoken,
        );
        if (response.statusCode == HttpStatus.noContent) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = '';
          String displayUrl = '';

          if (customUrl != 'None') {
            if (!customUrl.endsWith('/')) {
              returnUrl = '$customUrl/$urlpath';
              displayUrl = '$customUrl/$urlpath';
            } else {
              customUrl = customUrl.substring(0, customUrl.length - 1);
              returnUrl = '$customUrl/$urlpath';
              displayUrl = '$customUrl/$urlpath';
            }
          } else {
            returnUrl = 'https://$host/$urlpath';
            displayUrl = 'https://$host/$urlpath';
          }

          if (options == 'None') {
            displayUrl =
                "$displayUrl?x-oss-process=image/resize,m_lfit,h_500,w_500";
          } else {
            //网站后缀以?开头
            if (!options.startsWith('?')) {
              options = '?$options';
            }
            returnUrl = '$returnUrl$options';
            displayUrl = '$displayUrl$options';
          }

          String formatedURL = '';
          if (Global.isCopyLink == true) {
            formatedURL =
                linkGenerateDict[Global.defaultLKformat]!(returnUrl, fileName);
          } else {
            formatedURL = returnUrl;
          }
          await Clipboard.setData(ClipboardData(text: formatedURL));
          String pictureKey = 'None';
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl, //aliyun文件原始地址
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': displayUrl, //实际展示的是displayUrl
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      } else if (defaultPH == 'qiniu') {
        String accessKey = configMap['accessKey'];
        String secretKey = configMap['secretKey'];
        String bucket = configMap['bucket'];
        String url = configMap['url'];
        String area = configMap['area'];
        String options = configMap['options'];
        String qiniupath = configMap['path'];

        if (!url.startsWith('http') && !url.startsWith('https')) {
          url = 'http://$url';
        }
        if (url.endsWith('/')) {
          url = url.substring(0, url.length - 1);
        }
        String urlpath = '';
        //不为None才处理
        if (qiniupath != 'None') {
          if (qiniupath.startsWith('/')) {
            qiniupath = qiniupath.substring(1);
          }
          if (!qiniupath.endsWith('/')) {
            qiniupath = '$qiniupath/';
          }
          urlpath = '$qiniupath$fileName';
        } else {
          urlpath = fileName;
        }
        String key = fileName;

        String urlSafeBase64EncodePutPolicy =
            QiniuImageUploadUtils.geturlSafeBase64EncodePutPolicy(
                bucket, key, qiniupath);
        String uploadToken = QiniuImageUploadUtils.getUploadToken(
            accessKey, secretKey, urlSafeBase64EncodePutPolicy);
        String host = QiniuImageUploadUtils.areaHostMap[area]!;
        FormData formData = FormData.fromMap({
          "key": urlpath,
          "fileName": fileName,
          "token": uploadToken,
          "file": await MultipartFile.fromFile(path, filename: fileName),
        });
        BaseOptions baseoptions = BaseOptions(
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
        );
        //不需要加Content-Type，host，Content-Length
        baseoptions.headers = {
          'Authorization': 'UpToken $uploadToken',
        };
        Dio dio = Dio(baseoptions);
        response = await dio.post(
          host,
          data: formData,
          onSendProgress: createCallback(path),
          cancelToken: canceltoken,
        );

        if (response.statusCode == HttpStatus.ok) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = '';
          String displayUrl = '';

          if (options == 'None') {
            returnUrl = '$url/${response.data['key']}';
            displayUrl =
                '$url/${response.data['key']}?imageView2/2/w/500/h/500';
          } else {
            if (!options.startsWith('?')) {
              options = '?$options';
            }
            returnUrl = '$url/${response.data['key']}$options';
            displayUrl = '$url/${response.data['key']}$options';
          }
          String formatedURL = '';
          if (Global.isCopyLink == true) {
            formatedURL =
                linkGenerateDict[Global.defaultLKformat]!(returnUrl, fileName);
          } else {
            formatedURL = returnUrl;
          }
          await Clipboard.setData(ClipboardData(text: formatedURL));
          String pictureKey = 'None';
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl, //qiniu文件原始地址
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': displayUrl, //实际展示的是displayUrl
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      } else if (defaultPH == 'upyun') {
        String bucket = configMap['bucket'];
        String upyunOperator = configMap['operator'];
        String password = configMap['password'];
        String url = configMap['url'];
        String options = configMap['options'];
        String upyunpath = configMap['path'];
        //格式化
        if (url != "None") {
          if (!url.startsWith('http') && !url.startsWith('https')) {
            url = 'http://$url';
          }
        }
        //格式化
        if (upyunpath != 'None') {
          if (upyunpath.startsWith('/')) {
            upyunpath = upyunpath.substring(1);
          }
          if (!upyunpath.endsWith('/')) {
            upyunpath = '$upyunpath/';
          }
        }
        String host = 'http://v0.api.upyun.com';
        //云存储的路径
        String urlpath = '';
        if (upyunpath != 'None') {
          urlpath = '/$upyunpath$fileName';
        } else {
          urlpath = '/$fileName';
        }
        String date = HttpDate.format(DateTime.now());
        File uploadFile = File(path);
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
        String base64Policy =
            base64.encode(utf8.encode(json.encode(uploadPolicy)));
        String stringToSign =
            'POST&/$bucket&$date&$base64Policy&$uploadFileMd5';
        String passwordMd5 = md5.convert(utf8.encode(password)).toString();
        String signature = base64.encode(Hmac(sha1, utf8.encode(passwordMd5))
            .convert(utf8.encode(stringToSign))
            .bytes);
        String authorization = 'UPYUN $upyunOperator:$signature';
        FormData formData = FormData.fromMap({
          'authorization': authorization,
          'policy': base64Policy,
          'file': await MultipartFile.fromFile(path, filename: fileName),
        });
        BaseOptions baseoptions = BaseOptions(
          connectTimeout: 30000,
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
        response = await dio.post(
          '$host/$bucket',
          data: formData,
          onSendProgress: createCallback(path),
          cancelToken: canceltoken,
        );
        if (response.statusCode == HttpStatus.ok) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = '';
          String displayUrl = '';

          if (!url.endsWith('/')) {
            returnUrl = '$url/$urlpath';
            displayUrl = '$url/$urlpath';
          } else {
            url = url.substring(0, url.length - 1);
            returnUrl = '$url/$urlpath';
            displayUrl = '$url/$urlpath';
          }

          returnUrl = '$returnUrl$options';
          displayUrl = '$displayUrl$options';

          String formatedURL = '';
          if (Global.isCopyLink == true) {
            formatedURL =
                linkGenerateDict[Global.defaultLKformat]!(returnUrl, fileName);
          } else {
            formatedURL = returnUrl;
          }
          await Clipboard.setData(ClipboardData(text: formatedURL));
          String pictureKey = 'None';
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl, //upyun文件原始地址
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': displayUrl, //实际展示的是displayUrl
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      } else if (defaultPH == 'lsky.pro') {
        FormData formdata = FormData.fromMap({
          "file": await MultipartFile.fromFile(path, filename: fileName),
        });
        if (configMap["strategy_id"] == "None") {
          formdata = FormData.fromMap({});
        } else {
          formdata = FormData.fromMap({
            "file": await MultipartFile.fromFile(path, filename: fileName),
            "strategy_id": configMap["strategy_id"],
          });
        }
        BaseOptions options = BaseOptions(
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
        );
        options.headers = {
          "Authorization": configMap["token"],
          "Accept": "application/json",
          "Content-Type": "multipart/form-data",
        };
        Dio dio = Dio(options);
        String uploadUrl = configMap["host"] + "/api/v1/upload";
        response = await dio.post(
          uploadUrl,
          data: formdata,
          onSendProgress: createCallback(path),
          cancelToken: canceltoken,
        );
        if (response.statusCode == HttpStatus.ok &&
            response.data!['status'] == true) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = '';
          String displayUrl = '';
          returnUrl = response.data!['data']['links']['url'];
          displayUrl = response.data!['data']['links']['thumbnail_url'];
          String formatedURL = '';
          if (Global.isCopyLink == true) {
            formatedURL =
                linkGenerateDict[Global.defaultLKformat]!(returnUrl, fileName);
          } else {
            formatedURL = returnUrl;
          }
          await Clipboard.setData(ClipboardData(text: formatedURL));
          String pictureKey = response.data!['data']['key'];
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl, //原图地址
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': displayUrl, //实际展示的是缩略图
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      } else if (defaultPH == 'sm.ms') {
        FormData formdata = FormData.fromMap({
          "smfile": await MultipartFile.fromFile(path, filename: fileName),
          "format": "json",
        });
        BaseOptions options = BaseOptions(
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
        );
        options.headers = {
          "Authorization": configMap["token"],
          "Content-Type": "multipart/form-data",
        };
        Dio dio = Dio(options);
        String uploadUrl = "https://smms.app/api/v2/upload";
        response = await dio.post(
          uploadUrl,
          data: formdata,
          onSendProgress: createCallback(path),
          cancelToken: canceltoken,
        );
        if (response.statusCode == HttpStatus.ok &&
            response.data!['success'] == true) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = response.data!['data']['url'];
          String pictureKey = response.data!['data']['hash'];
          String formatedURL = '';
          if (Global.isCopyLink == true) {
            formatedURL =
                linkGenerateDict[Global.defaultLKformat]!(returnUrl, fileName);
          } else {
            formatedURL = returnUrl;
          }
          await Clipboard.setData(ClipboardData(text: formatedURL));
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl,
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': 'test',
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      } else if (defaultPH == 'github') {
        String base64Image = base64Encode(File(path).readAsBytesSync());
        Map<String, dynamic> queryBody = {
          'message': 'uploaded by horopic app',
          'content': base64Image,
          'branch': configMap["branch"], //分支
        };
        BaseOptions options = BaseOptions(
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
        );
        options.headers = {
          "Authorization": configMap["token"],
          "Accept": "application/vnd.github+json",
        };

        String trimedPath = configMap['storePath'].toString().trim();
        if (trimedPath.startsWith('/')) {
          trimedPath = trimedPath.substring(1);
        }
        if (trimedPath.endsWith('/')) {
          trimedPath = trimedPath.substring(0, trimedPath.length - 1);
        }
        Dio dio = Dio(options);
        String uploadUrl = '';
        if (trimedPath == 'None') {
          uploadUrl =
              "https://api.github.com/repos/${configMap["githubusername"]}/${configMap["repo"]}/contents/$fileName";
        } else {
          uploadUrl =
              "https://api.github.com/repos/${configMap["githubusername"]}/${configMap["repo"]}/contents/$trimedPath/$fileName";
        }

        response = await dio.put(
          uploadUrl,
          data: jsonEncode(queryBody),
          onSendProgress: createCallback(path),
        );
        if (response.statusCode == HttpStatus.ok ||
            response.statusCode == HttpStatus.created) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = response.data!['content']['html_url'];
          String pictureKey = response.data!['content']['sha'];
          String downloadUrl = '';
          String formatedURL = '';
          if (configMap['customDomain'] != 'None') {
            if (configMap['customDomain'].toString().endsWith('/')) {
              String trimedCustomDomain = configMap['customDomain']
                  .toString()
                  .substring(
                      0, configMap['customDomain'].toString().length - 1);
              if (trimedPath == 'None') {
                downloadUrl = '$trimedCustomDomain$fileName';
              } else {
                downloadUrl = '$trimedCustomDomain$trimedPath/$fileName';
              }
            } else {
              if (trimedPath == 'None') {
                downloadUrl = '${configMap['customDomain']}/$fileName';
              } else {
                downloadUrl =
                    '${configMap['customDomain']}/$trimedPath/$fileName';
              }
            }
          } else {
            downloadUrl = response.data!['content']['download_url'];
          }
          if (!downloadUrl.startsWith('http') &&
              !downloadUrl.startsWith('https')) {
            downloadUrl = 'http://$downloadUrl';
          }
          if (Global.isCopyLink == true) {
            formatedURL = linkGenerateDict[Global.defaultLKformat]!(
                downloadUrl, fileName);
          } else {
            formatedURL = downloadUrl;
          }
          await Clipboard.setData(ClipboardData(text: formatedURL));
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl,
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': downloadUrl, //github download url或者自定义域名+路径
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      } else if (defaultPH == 'imgur') {
        String base64Image = base64Encode(File(path).readAsBytesSync());
        FormData formdata = FormData.fromMap({
          "image": base64Image,
        });
        BaseOptions options = BaseOptions(
          connectTimeout: 30000,
          receiveTimeout: 30000,
          sendTimeout: 30000,
        );
        options.headers = {
          "Authorization": "Client-ID ${configMap["clientId"]}",
        };
        Dio dio = Dio(options);
        String proxy = configMap["proxy"];
        String proxyClean = '';
        //判断是否有代理
        if (proxy != 'None') {
          if (proxy.startsWith('http://') || proxy.startsWith('https://')) {
            proxyClean = proxy.split('://')[1];
          } else {
            proxyClean = proxy;
          }
          dio.useProxy(proxyClean);
        }
        String uploadUrl = "https://api.imgur.com/3/image";
        response = await dio.post(
          uploadUrl,
          data: formdata,
          onSendProgress: createCallback(path),
          cancelToken: canceltoken,
        );
        if (response.statusCode == HttpStatus.ok ||
            response.data!['success'] == true) {
          eventBus.fire(AlbumRefreshEvent(albumKeepAlive: false));
          Map<String, dynamic> maps = {};
          String returnUrl = response.data!['data']['link'];
          String pictureKey = response.data!['data']['deletehash'];

          String formatedURL = '';
          if (Global.isCopyLink == true) {
            formatedURL =
                linkGenerateDict[Global.defaultLKformat]!(returnUrl, fileName);
          } else {
            formatedURL = returnUrl;
          }
          //相册显示地址用cdn加速,但是复制的时候还是用原图地址
          //https://search.pstatic.net/common?src=

          String cdnUrl = 'https://search.pstatic.net/common?src=$returnUrl';
          await Clipboard.setData(ClipboardData(text: formatedURL));
          maps = {
            'path': path,
            'name': fileName,
            'url': returnUrl, //imgur文件原始地址
            'PBhost': Global.defaultPShost,
            'pictureKey': pictureKey,
            'hostSpecificArgA': cdnUrl, //实际展示的是imgur cdn url
            'hostSpecificArgB': 'test',
            'hostSpecificArgC': 'test',
            'hostSpecificArgD': 'test',
            'hostSpecificArgE': 'test',
          };
          await AlbumSQL.insertData(
              Global.imageDB!, pBhostToTableName[Global.defaultPShost]!, maps);
          setStatus(task, UploadStatus.completed);
        }
      }
    } catch (e) {
      var task = getUpload(path)!;
      if (task.status.value != UploadStatus.canceled &&
          task.status.value != UploadStatus.completed) {
        setStatus(task, UploadStatus.failed);
        runningTasks--;
        if (_queue.isNotEmpty) {
          _startExecution();
        }
        rethrow;
      }
    }
    runningTasks--;
    if (_queue.isNotEmpty) {
      _startExecution();
    }
  }

  void _startExecution() async {
    if (runningTasks == maxConcurrentTasks || _queue.isEmpty) {
      return;
    }

    while (_queue.isNotEmpty && runningTasks < maxConcurrentTasks) {
      runningTasks++;
      var currentRequest = _queue.removeFirst();
      upload(currentRequest.path, currentRequest.cancelToken);
      await Future.delayed(const Duration(milliseconds: 500), null);
    }
  }

  UploadTask? getUpload(String path) {
    return _cache[path];
  }

  void setStatus(UploadTask? task, UploadStatus status) {
    if (task != null) {
      task.status.value = status;
    }
  }

  Future<UploadTask?> addUpload(String path) async {
    if (path.isNotEmpty) {
      return await _addUploadRequest(UploadRequest(path));
    }
    return null;
  }

  Future<UploadTask> _addUploadRequest(UploadRequest uploadRequest) async {
    if (_cache[uploadRequest.path] != null) {
      if (!_cache[uploadRequest.path]!.status.value.isCompleted &&
          _cache[uploadRequest.path]!.request == uploadRequest) {
        return _cache[uploadRequest.path]!;
      } else {
        _queue.remove(_cache[uploadRequest.path]);
      }
    }
    _queue.add(UploadRequest(uploadRequest.path));
    var task = UploadTask(_queue.last);
    _cache[uploadRequest.path] = task;
    _startExecution();
    return task;
  }

  Future<void> pauseUpload(String path) async {
    var task = getUpload(path);
    if (task != null) {
      setStatus(task, UploadStatus.paused);
      _queue.remove(task.request);
      task.request.cancelToken.cancel();
    }
  }

  Future<void> cancelUpload(String path) async {
    var task = getUpload(path);
    if (task != null) {
      setStatus(task, UploadStatus.canceled);
      _queue.remove(task.request);
      task.request.cancelToken.cancel();
    }
  }

  Future<void> resumeUpload(String path) async {
    var task = getUpload(path);
    if (task != null) {
      setStatus(task, UploadStatus.uploading);
      task.request.cancelToken = CancelToken();
      _queue.add(task.request);
    }
    _startExecution();
  }

  Future<void> removeUpload(String path) async {
    await cancelUpload(path);
    _cache.remove(path);
  }

  Future<UploadStatus> whenUploadComplete(String path,
      {Duration timeout = const Duration(hours: 2)}) async {
    UploadTask? task = getUpload(path);

    if (task != null) {
      return task.whenUploadComplete(timeout: timeout);
    } else {
      return Future.error("Upload not found");
    }
  }

  List<UploadTask> getALlUpload() {
    return _cache.values as List<UploadTask>;
  }

  Future<void> addBatchUploads(List<String> paths) async {
    for (var path in paths) {
      await addUpload(path);
    }
  }

  List<UploadTask?> getBatchUploads(List<String> paths) {
    return paths.map((e) => _cache[e]).toList();
  }

  Future<void> pauseBatchUploads(List<String> paths) async {
    for (var element in paths) {
      await pauseUpload(element);
    }
  }

  Future<void> cancelBatchUploads(List<String> paths) async {
    for (var element in paths) {
      await cancelUpload(element);
    }
  }

  Future<void> resumeBatchUploads(List<String> paths) async {
    for (var element in paths) {
      await resumeUpload(element);
    }
  }

  ValueNotifier<double> getBatchUploadProgress(List<String> paths) {
    ValueNotifier<double> progress = ValueNotifier(0);
    var total = paths.length;

    if (total == 0) {
      return progress;
    }

    if (total == 1) {
      return getUpload(paths.first)?.progress ?? progress;
    }

    var progressMap = <String, double>{};

    for (var path in paths) {
      UploadTask? task = getUpload(path);
      if (task != null) {
        progressMap[path] = 0.0;
        if (task.status.value.isCompleted) {
          progressMap[path] = 1.0;
          progress.value = progressMap.values.sum / total;
        }

        var progressListener;
        progressListener = () {
          progressMap[path] = task.progress.value;
          progress.value = progressMap.values.sum / total;
        };

        task.progress.addListener(progressListener);
        var listener;
        listener = () {
          if (task.status.value.isCompleted) {
            progressMap[path] = 1.0;
            progress.value = progressMap.values.sum / total;
            task.progress.removeListener(progressListener);
            task.status.removeListener(listener);
          }
        };
        task.status.addListener(listener);
      } else {
        total--;
      }
    }
    return progress;
  }

  Future<List<UploadTask?>?> whenBatchUploadsComplete(List<String> paths,
      {Duration timeout = const Duration(hours: 2)}) async {
    var completer = Completer<List<UploadTask?>?>();
    var completed = 0;
    var total = paths.length;
    for (var path in paths) {
      UploadTask? task = getUpload(path);

      if (task != null) {
        if (task.status.value.isCompleted) {
          completed++;

          if (completed == total) {
            completer.complete(getBatchUploads(paths));
          }
        }

        var listener;
        listener = () {
          if (task.status.value.isCompleted) {
            completed++;

            if (completed == total) {
              completer.complete(getBatchUploads(paths));
              task.status.removeListener(listener);
            }
          }
        };

        task.status.addListener(listener);
      } else {
        total--;

        if (total == 0) {
          completer.complete(null);
        }
      }
    }

    return completer.future.timeout(timeout);
  }
}