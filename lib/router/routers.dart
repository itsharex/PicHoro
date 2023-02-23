import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:fluro/fluro.dart';

import 'package:horopic/router/router_handler.dart';

class Routes {
  static String webviewPage = '/webview';
  static String root = "/";
  static String homePage = "/homePage";
  static String albumUploadedImages = "/albumUploadedImages";
  static String albumImagePreview = "/albumImagePreview";
  static String webdavImagePreview = "/webdavImagePreview";
  static String localImagePreview = "/localImagePreview";
  static String configurePage = "/configurePage";
  static String configurePageLogger = "/configurePageLogger";
  static String compressConfigurePage = "/compressConfigurePage";
  static String appPassword = "/appPassword";
  static String allPShost = "/allPShost";
  static String defaultPShostSelect = "/defaultPShostSelect";
  static String lskyproPShostSelect = "/lskyproPShostSelect";
  static String smmsPShostSelect = "/smmsPShostSelect";
  static String githubPShostSelect = "/githubPShostSelect";
  static String imgurPShostSelect = "/imgurPShostSelect";
  static String aliyunPShostSelect = "/aliyunPShostSelect";
  static String tencentPShostSelect = "/tencentPShostSelect";
  static String qiniuPShostSelect = "/qiniuPShostSelect";
  static String upyunPShostSelect = "/upyunPShostSelect";
  static String ftpPShostSelect = "/ftpPShostSelect";
  static String awsPShostSelect = "/awsPShostSelect";
  static String alistPShostSelect = "/alistPShostSelect";
  static String webdavPShostSelect = "/webdavPShostSelect";
  static String configureStorePage = "/configureStorePage";
  static String alistConfigureStoreEditPage = "/alistConfigureStoreEditPage";
  static String aliyunConfigureStoreEditPage = "/aliyunConfigureStoreEditPage";
  static String awsConfigureStoreEditPage = "/awsConfigureStoreEditPage";
  static String ftpConfigureStoreEditPage = "/ftpConfigureStoreEditPage";
  static String githubConfigureStoreEditPage = "/githubConfigureStoreEditPage";
  static String imgurConfigureStoreEditPage = "/imgurConfigureStoreEditPage";
  static String lskyproConfigureStoreEditPage = "/lskyConfigureStoreEditPage";
  static String qiniuConfigureStoreEditPage = "/qiniuConfigureStoreEditPage";
  static String smmsConfigureStoreEditPage = "/smmsConfigureStoreEditPage";
  static String tencentConfigureStoreEditPage =
      "/tencentConfigureStoreEditPage";
  static String upyunConfigureStoreEditPage = "/upyunConfigureStoreEditPage";
  static String webdavConfigureStoreEditPage = "/webdavConfigureStoreEditPage";
  static String commonConfig = "/commonConfig";
  static String renameFile = "/renameFile";
  static String linkFormatSelect = "/linkFormatSelect";
  static String changeTheme = "/changeTheme";
  static String emptyDatabase = "/emptyDatabase";
  static String authorInformation = "/authorInformation";
  static String updateLog = "/updateLog";
  static String tencentBucketInformation = "/tencentBucketInformation";
  static String tencentNewBucketConfig = "/tencentNewBucketConfig";
  static String tencentFileExplorer = "/tencentFileExplorer";
  static String tencentFileInformation = "/tencentFileInformation";
  static String tencentBucketList = "/tencentBucketList";
  static String fileExplorer = "/fileExplorer";
  static String smmsManageHomePage = "/smmsManageHomePage";
  static String smmsFileExplorer = "/smmsFileExplorer";
  static String smmsFileInformation = "/smmsFileInformation";
  static String smmsUpDownloadManagePage = "/smmsUpDownloadManagePage";
  static String userInformationPage = '/userInformationPage';
  static String pictureHostInfoPage = '/pictureHostInfoPage';
  static String aliyunBucketList = '/aliyunBucketList';
  static String aliyunNewBucketConfig = "/aliyunNewBucketConfig";
  static String aliyunBucketInformation = "/aliyunBucketInformation";
  static String aliyunFileExplorer = "/aliyunFileExplorer";
  static String aliyunFileInformation = "/aliyunFileInformation";
  static String upyunLogIn = '/upyunLogIn';
  static String upyunFileExplorer = "/upyunFileExplorer";
  static String upyunBucketList = "/upyunBucketList";
  static String upyunBucketInformation = "/upyunBucketInformation";
  static String upyunTokenManagePage = "/upyunTokenManagePage";
  static String upyunNewBucketConfig = "/upyunNewBucketConfig";
  static String upyunFileInformationPage = "/upyunFileInformationPage";
  static String qiniuBucketList = "/qiniuBucketList";
  static String qiniuNewBucketConfig = "/qiniuNewBucketConfig";
  static String qiniuBucketDomainAreaConfig = "/qiniuBucketDomainAreaConfig";
  static String qiniuFileExplorer = "/qiniuFileExplorer";
  static String qiniuFileInformation = "/qiniuFileInformation";
  static String lskyproManageHomePage = "/lskyproManageHomePage";
  static String lskyproFileExplorer = "/lskyproFileExplorer";
  static String lskyproFileInformation = "/lskyproFileInformation";
  static String githubManageHomePage = "/githubManageHomePage";
  static String githubReposList = "/githubReposList";
  static String githubRepoInformation = "/githubRepoInformation";
  static String githubNewRepoConfig = "/githubNewRepoConfig";
  static String githubFileExplorer = "/githubFileExplorer";
  static String githubFileInformation = "/githubFileInformation";
  static String imgurLogIn = "/imgurLogIn";
  static String imgurFileExplorer = "/imgurFileExplorer";
  static String imgurTokenManagePage = "/imgurTokenManagePage";
  static String imgurFileInformation = "/imgurFileInformation";
  static String sftpFileExplorer = "/sftpFileExplorer";
  static String sftpFileInformation = "/sftpFileInformation";
  static String sshTerminal = "/sshTerminal";
  static String sftpLocalImagePreview = "/sftpLocalImagePreview";
  static String mdPreview = "/mdPreview";
  static String awsBucketList = "/awsBucketList";
  static String awsNewBucketConfig = "/awsNewBucketConfig";
  static String awsFileExplorer = "/awsFileExplorer";
  static String awsFileInformation = "/awsFileInformation";
  static String alistBucketList = "/alistBucketList";
  static String alistBucketInformation = "/alistBucketInformation";
  static String alistNewBucketConfig = "/alistNewBucketConfig";
  static String newAlistBucketNavigation = "/newAlistBucketNavigation";
  static String alistFileExplorer = "/alistFileExplorer";
  static String alistFileInformation = "/alistFileInformation";
  static String alistUpDownloadManagePage = "/alistUpDownloadManagePage";
  static String netVideoPlayer = "/netVideoPlayer";
  static String pdfViewer = "/pdfViewer";
  static String webdavFileExplorer = "/webdavFileExplorer";
  static String webdavFileInformation = "/webdavFileInformation";
  static String baseUpDownloadManagePage = "/baseUpDownloadManagePage";

  static void configureRoutes(FluroRouter router) {
    router.notFoundHandler = Handler(
        handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
      if (kDebugMode) {
        print("ROUTE WAS NOT FOUND !!!");
      }
      return null;
    });
    router.define(webviewPage, handler: webviewHandler);
    router.define(root, handler: rootHandler);
    router.define(homePage, handler: homePageHandler);
    router.define(albumUploadedImages, handler: albumUploadedImagesHandler);
    router.define(albumImagePreview, handler: albumImagePreviewHandler);
    router.define(webdavImagePreview, handler: webdavImagePreviewHandler);
    router.define(localImagePreview, handler: localImagePreviewHandler);
    router.define(configurePage, handler: configurePageHandler);
    router.define(compressConfigurePage, handler: compressConfigureHandler);
    router.define(appPassword, handler: appPasswordHandler);
    router.define(allPShost, handler: allPShostHandler);
    router.define(defaultPShostSelect, handler: defaultPShostSelectHandler);
    router.define(lskyproPShostSelect, handler: lskyproPShostSelectHandler);
    router.define(smmsPShostSelect, handler: smmsPShostSelectHandler);
    router.define(githubPShostSelect, handler: githubPShostSelectHandler);
    router.define(imgurPShostSelect, handler: imgurPShostSelectHandler);
    router.define(aliyunPShostSelect, handler: aliyunPShostSelectHandler);
    router.define(tencentPShostSelect, handler: tencentPShostSelectHandler);
    router.define(qiniuPShostSelect, handler: qiniuPShostSelectHandler);
    router.define(upyunPShostSelect, handler: upyunPShostSelectHandler);
    router.define(ftpPShostSelect, handler: ftpPShostSelectHandler);
    router.define(awsPShostSelect, handler: awsPShostSelectHandler);
    router.define(alistPShostSelect, handler: alistPShostSelectHandler);
    router.define(webdavPShostSelect, handler: webdavPShostSelectHandler);
    router.define(alistConfigureStoreEditPage,
        handler: alistConfigureStoreEditPageHandler);
    router.define(aliyunConfigureStoreEditPage,
        handler: aliyunConfigureStoreEditPageHandler);
    router.define(awsConfigureStoreEditPage,
        handler: awsConfigureStoreEditPageHandler);
    router.define(ftpConfigureStoreEditPage,
        handler: ftpConfigureStoreEditPageHandler);
    router.define(githubConfigureStoreEditPage,
        handler: githubConfigureStoreEditPageHandler);
    router.define(imgurConfigureStoreEditPage,
        handler: imgurConfigureStoreEditPageHandler);
    router.define(lskyproConfigureStoreEditPage,
        handler: lskyproConfigureStoreEditPageHandler);
    router.define(qiniuConfigureStoreEditPage,
        handler: qiniuConfigureStoreEditPageHandler);
    router.define(smmsConfigureStoreEditPage,
        handler: smmsConfigureStoreEditPageHandler);
    router.define(tencentConfigureStoreEditPage,
        handler: tencentConfigureStoreEditPageHandler);
    router.define(upyunConfigureStoreEditPage,
        handler: upyunConfigureStoreEditPageHandler);
    router.define(webdavConfigureStoreEditPage,
        handler: webdavConfigureStoreEditPageHandler);
    router.define(commonConfig, handler: commonConfigHandler);
    router.define(renameFile, handler: renameFileHandler);
    router.define(linkFormatSelect, handler: linkFormatSelectHandler);
    router.define(changeTheme, handler: changeThemeHandler);
    router.define(emptyDatabase, handler: emptyDatabaseHandler);
    router.define(authorInformation, handler: authorInformationHandler);
    router.define(updateLog, handler: updateLogHandler);
    router.define(tencentBucketInformation,
        handler: tencentBucketInformationHandler);
    router.define(tencentNewBucketConfig, handler: newTencentBucketHandler);
    router.define(tencentFileExplorer, handler: tencentFileExplorerHandler);
    router.define(tencentFileInformation,
        handler: tencentFileInformationHandler);
    router.define(tencentBucketList, handler: tencentBucketListHandler);
    router.define(fileExplorer, handler: fileExplorerHandler);
    router.define(smmsManageHomePage, handler: smmsManageHomePageHandler);
    router.define(smmsFileExplorer, handler: smmsFileExplorerHandler);
    router.define(smmsFileInformation, handler: smmsFileInformationHandler);
    router.define(smmsUpDownloadManagePage, handler: smmsUpDownloadFileHandler);
    router.define(userInformationPage, handler: userInformationPageHandler);
    router.define(pictureHostInfoPage, handler: pictureHostInfoPageHandler);
    router.define(aliyunBucketList, handler: aliyunBucketListHandler);
    router.define(aliyunNewBucketConfig, handler: newAliyunBucketHandler);
    router.define(aliyunBucketInformation,
        handler: aliyunBucketInformationHandler);
    router.define(aliyunFileExplorer, handler: aliyunFileExplorerHandler);
    router.define(aliyunFileInformation, handler: aliyunFileInformationHandler);
    router.define(configurePageLogger, handler: logsHandler);
    router.define(upyunFileExplorer, handler: upyunFileExplorerHandler);
    router.define(upyunLogIn, handler: upyunLogInHandler);
    router.define(upyunBucketList, handler: upyunBucketListHandler);
    router.define(upyunBucketInformation,
        handler: upyunBucketInformationHandler);
    router.define(upyunTokenManagePage, handler: upyunTokenManageHandler);
    router.define(upyunNewBucketConfig, handler: newUpyunBucketHandler);
    router.define(upyunFileInformationPage,
        handler: upyunFileInformationHandler);
    router.define(qiniuBucketList, handler: qiniuBucketListHandler);
    router.define(qiniuNewBucketConfig, handler: newQiniuBucketHandler);
    router.define(qiniuBucketDomainAreaConfig,
        handler: qiniuBucketDomainAreaConfigHandler);
    router.define(qiniuFileExplorer, handler: qiniuFileExplorerHandler);
    router.define(qiniuFileInformation, handler: qiniuFileInformationHandler);
    router.define(lskyproManageHomePage, handler: lskyproManageHomePageHandler);
    router.define(lskyproFileExplorer, handler: lskyproFileExplorerHandler);
    router.define(lskyproFileInformation,
        handler: lskyproFileInformationHandler);
    router.define(githubManageHomePage, handler: githubManageHomePageHandler);
    router.define(githubReposList, handler: githubReposListHandler);
    router.define(githubRepoInformation, handler: githubRepoInformationHandler);
    router.define(githubNewRepoConfig, handler: githubNewRepoConfigHandler);
    router.define(githubFileExplorer, handler: githubFileExplorerHandler);
    router.define(githubFileInformation, handler: githubFileInformationHandler);
    router.define(imgurLogIn, handler: imgurLogInHandler);
    router.define(imgurFileExplorer, handler: imgurFileExplorerHandler);
    router.define(imgurTokenManagePage, handler: imgurTokenManageHandler);
    router.define(imgurFileInformation, handler: imgurFileInformationHandler);
    router.define(sftpFileExplorer, handler: sftpFileExplorerHandler);
    router.define(sftpFileInformation, handler: sftpFileInformationHandler);
    router.define(sshTerminal, handler: sshTerminalHandler);
    router.define(sftpLocalImagePreview, handler: sftplocalImagePreviewHandler);
    router.define(mdPreview, handler: mdFilePreviewHandler);
    router.define(awsBucketList, handler: awsBucketListHandler);
    router.define(awsNewBucketConfig, handler: newAwsBucketHandler);
    router.define(awsFileExplorer, handler: awsFileExplorerHandler);
    router.define(awsFileInformation, handler: awsFileInformationHandler);
    router.define(configureStorePage, handler: configureStorePageHandler);
    router.define(alistBucketList, handler: alistBucketListHandler);
    router.define(alistBucketInformation,
        handler: alistBucketInformationHandler);
    router.define(alistNewBucketConfig, handler: newAlistBucketHandler);
    router.define(newAlistBucketNavigation,
        handler: newAlistBucketNavigationHandler);
    router.define(alistFileExplorer, handler: alistFileExplorerHandler);
    router.define(alistFileInformation, handler: alistFileInformationHandler);
    router.define(alistUpDownloadManagePage, handler: alistDownloadFileHandler);
    router.define(netVideoPlayer, handler: netVideoPlayerHandler);
    router.define(pdfViewer, handler: pdfViewerHandler);
    router.define(webdavFileExplorer, handler: webdavFileExplorerHandler);
    router.define(webdavFileInformation, handler: webdavFileInformationHandler);
    router.define(baseUpDownloadManagePage, handler: baseDownloadFileHandler);
  }
}
