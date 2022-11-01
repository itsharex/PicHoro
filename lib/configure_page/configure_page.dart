import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fluro/fluro.dart';

import 'package:horopic/utils/sql_utils.dart';
import 'package:horopic/utils/permission.dart';
import 'package:horopic/router/application.dart';
import 'package:horopic/router/routers.dart';
import 'package:horopic/utils/common_functions.dart';

class ConfigurePage extends StatefulWidget {
  const ConfigurePage({Key? key}) : super(key: key);

  @override
  ConfigurePageState createState() => ConfigurePageState();
}

class ConfigurePageState extends State<ConfigurePage>
    with AutomaticKeepAliveClientMixin<ConfigurePage> {
  String version = ' ';

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  void _getVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      version = info.version;
    });
  }

  _checkUpdate() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    String remoteVersion = await MySqlUtils.getCurrentVersion();
    if (version != remoteVersion) {
      _showUpdateDialog(version, remoteVersion);
    } else {
      return Fluttertoast.showToast(
          msg: "已是最新版本",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 2,
          fontSize: 16.0);
    }
  }

  _showUpdateDialog(String version, String remoteVersion) {
    showCupertinoAlertDialogWithConfirmFunc(
      title: '通知',
      content: '发现新版本$remoteVersion,当前版本$version,是否更新?',
      context: context,
      onConfirm: () async {
        Navigator.of(context).pop();
        _update(remoteVersion);
      },
    );
  }

  _update(String remoteVersion) async {
    String url =
        'https://www.horosama.com/self_apk/PicHoro_V$remoteVersion.apk';
    RUpgrade.upgrade(url,
        fileName: 'PicHoro_V$remoteVersion.apk',
        isAutoRequestInstall: true,
        notificationStyle: NotificationStyle.speechAndPlanTime);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          '设置页面',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: MediaQuery.of(context).size.width / 10,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          const Image(image: AssetImage('assets/app_icon.png'))
                              .image,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text('v$version'),
                    )
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text(
              '用户登录',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Application.router.navigateTo(this.context, Routes.appPassword,
                  transition: TransitionType.cupertino);
            },
          ),
          ListTile(
            title: const Text('图床参数设置'),
            onTap: () {
              Application.router.navigateTo(this.context, Routes.allPShost,
                  transition: TransitionType.cupertino);
            },
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            title: const Text('常规设置'),
            onTap: () {
              Application.router.navigateTo(this.context, Routes.commonConfig,
                  transition: TransitionType.cupertino);
            },
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            title: const Text('联系作者'),
            onTap: () {
              Application.router.navigateTo(
                  this.context, Routes.authorInformation,
                  transition: TransitionType.cupertino);
            },
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            title: const Text('立即更新'),
            onTap: () async {
              await Permissionutils.askPermissionRequestInstallPackage();
              _checkUpdate();
            },
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
          ListTile(
            title: const Text('更新日志'),
            onTap: () {
              Application.router.navigateTo(this.context, Routes.updateLog,
                  transition: TransitionType.cupertino);
            },
            trailing: const Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}