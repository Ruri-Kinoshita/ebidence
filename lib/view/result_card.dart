import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ebidence/constant/app_color.dart';
import 'package:ebidence/constant/quiz_data.dart';
import 'package:ebidence/provider/quiz_provider.dart';
import 'package:ebidence/view/result_card_row.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultFlashCard extends ConsumerStatefulWidget {
  //final bool isCheakAllFalse;
  const ResultFlashCard({super.key});

  @override
  ConsumerState<ResultFlashCard> createState() => _ResultFlashCard();
}

class _ResultFlashCard extends ConsumerState<ResultFlashCard>
    with SingleTickerProviderStateMixin {
  late List<Quiz> resultCardList;
  late int currentIndex;
  late bool isExistCards;
  bool? isSaveImage;
  bool isPostPush = false;
  bool isPostX = false;
  bool isPostCancel = false;
  String? imageId;
  String text = '';
  String url = '';
  List<String> hashtags = [];
  String via = '';
  String related = '';
  Uint8List? image;

  final storageRef = FirebaseStorage.instance.ref();
  late Reference containerRef;

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // FirestoreのドキュメントIDを保持する変数
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _updateContainerRef();
    debugPrint('a');
  }

  /// 現在のタイムスタンプを用いてReferenceを更新
  void _updateContainerRef() {
    final String timestamp =
        DateFormat('yyyy_MM_dd_HH_mm_ss_SSS').format(DateTime.now());
    containerRef = storageRef.child("$timestamp.jpg");
  }

  Future<Uint8List> _captureContainerAsImage() async {
    try {
      // RepaintBoundaryのキーから描画情報を取得
      RenderRepaintBoundary? boundary = _repaintBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("RepaintBoundary が見つかりませんでした。描画が完了していない可能性があります。");
      }

      // 描画を画像に変換
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // 画像をバイトデータに変換
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception("ByteData に変換できませんでした。");
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("画像のレンダリングに失敗しました: $e");
      rethrow;
    }
  }

  Future<void> _uploadContainerImageAndSaveToFirestore() async {
    try {
      isSaveImage = false;
      // タイムスタンプを使用してファイル名を更新
      _updateContainerRef();

      // Containerを画像としてキャプチャ
      Uint8List containerImage = await _captureContainerAsImage();

      setState(() {
        image = containerImage;
      });

      // Firebase Storage にアップロード
      await containerRef.putData(
          containerImage,
          SettableMetadata(
            contentType: "image/png",
          ));

      // アップロードされた画像のダウンロードURLを取得
      final String downloadUrl = await containerRef.getDownloadURL();

      // Firestore に保存し、DocumentReferenceを取得
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('images')
          .add({'url': downloadUrl});

      debugPrint('Firestoreに保存したドキュメントID: ${docRef.id}');
      debugPrint('保存した画像名: ${containerRef.name}');

      imageId = docRef.id;

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('保存成功！ドキュメントID: ${docRef.id}')),
      // );
      setState(() {
        isSaveImage = true;
      });
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${e.message}')),
        );
      }
    }
  }

  Future<void> _tweet() async {
    // Twitterアプリを開くためのURIスキーム
    final Uri tweetScheme = Uri.parse(
      "twitter://post?text=${Uri.encodeComponent(text)}",
    );

    // TwitterウェブURL
    final Uri tweetIntentUrl = Uri.https(
      "twitter.com",
      "/intent/tweet",
      {
        "text": 'クスクス、こんなのも分からないの～？🦐\n勉強不足なんじゃな～い？もっと頑張れ～！🦐\n',
        "url": 'https://ebidence-gbc.web.app/result/$imageId\n',
        "hashtags": ['p2hacks'],
        "via": '',
        "related": '',
      },
    );

    // Twitterアプリがインストールされているか確認
    if (await canLaunchUrl(tweetScheme)) {
      await launchUrl(tweetScheme);
    } else if (await canLaunchUrl(tweetIntentUrl)) {
      // インストールされていない場合はブラウザで開く
      await launchUrl(tweetIntentUrl);
    } else {
      // どちらも開けない場合はエラーメッセージを表示
      throw Exception("Could not launch Twitter URL.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final quiz = ref.watch(quizProvider);
    final resultCardList = ref.watch(resultCardListProvider); //List<Quiz>

    return Scaffold(
      body: Stack(
        children: [
          //全問不正解用の画像作成処理↓
          if (resultCardList.length == 5) ...[
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: Container(
                      width: 1200,
                      height: 630,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 8.0,
                                  child: Material(
                                    elevation: 2, // 影をつける高さ
                                    shadowColor: Colors.black
                                        .withOpacity(0.3), // 影の色と透明度
                                    borderRadius:
                                        BorderRadius.circular(8), // 角丸をつける場合
                                    child: Stack(
                                      alignment: Alignment.center, // 中央に配置
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColor.brand.secondary,
                                            borderRadius:
                                                BorderRadius.circular(0),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                offset: const Offset(0, 4),
                                                blurRadius: 2,
                                                spreadRadius: 0.5,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 300,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            color: Colors.white, // 白色の背景
                                            borderRadius: BorderRadius.circular(
                                                100), // 角丸
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                    0.1), // 影の色と透明度
                                                blurRadius: 4, // 影のぼかし半径
                                                offset: const Offset(
                                                    0, 4), // 下側に影を移動
                                              ),
                                            ],
                                          ),
                                        ),
                                        Image.asset(
                                          'assets/images/ebidence_title.png',
                                          height: 80,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const Text(
                            '結果',
                            style: TextStyle(fontSize: 35),
                          ),
                          Text(
                            '全問不正解',
                            style: TextStyle(
                              fontSize: 107, //'全'が潰れない最大値
                              fontFamily: 'NotoSansJP-Bold',
                              color: AppColor.text.black,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    '間違えた問題',
                                    style: TextStyle(fontSize: 30),
                                  ),
                                  Row(
                                    children: [
                                      for (int i = 0; i < 5; i++) ...[
                                        Container(
                                          width: 110,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border:
                                                Border.all(color: Colors.black),
                                            color: Colors.white,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  quiz[i].question,
                                                  //'あいうえお',
                                                  style: const TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  quiz[i].answer,
                                                  //'aiueo',
                                                  style: const TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 12),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (i < 4) const SizedBox(width: 10),
                                      ],
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(
                                width: 150,
                              ),
                              Column(
                                children: [
                                  Image.asset(
                                    'assets/images/aor_real_tag.png',
                                    height: 238,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '@ガリバタコーン',
                            style: TextStyle(
                                fontSize: 12, color: AppColor.brand.secondary),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          //最終結果画面の処理↓
          const ResultCardRow(),
          //全問不正解用の吹き出しの処理↓
          if (resultCardList.length == 5 && !isPostX) _wrongSpeachBubble(),
          Align(
            alignment: const Alignment(0.9, 1),
            child: Image.asset(
              'assets/images/evi_cam.png',
              width: deviceWidth / 3.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrongSpeachBubble() {
    return Center(
      child: Stack(
        children: [
          Center(child: Image.asset('assets/images/hukidashi_big.png')),
          if (isSaveImage == null) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(
                    child: SizedBox(),
                  ),
                  const Center(
                    child: Text(
                      '全問間違っちゃったでんすね〜w',
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 100,
                        ),
                        _buildCustomButton(
                          label: 'はい',
                          onPressed: () async {
                            try {
                              setState(() {
                                isSaveImage = false;
                              });
                              _uploadContainerImageAndSaveToFirestore();
                            } catch (e) {
                              debugPrint("エラー発生: $e");
                            }
                          },
                        ),
                        //Expanded(child: SizedBox())
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isPostX == false) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: Column(
                      children: [
                        if (isPostCancel == false) ...[
                          const Text(
                            '口角あがっちゃうでんすw',
                            style: TextStyle(fontSize: 30),
                          ),
                          const Text(
                            '甲殻類だけにw',
                            style: TextStyle(fontSize: 30),
                          ),
                        ],
                        if (isPostCancel == true) ...[
                          const Text(
                            'ボタン壊れてるでんすw',
                            style: TextStyle(fontSize: 30),
                          ),
                          const Text(
                            'ポストするしかないでんすw',
                            style: TextStyle(fontSize: 30),
                          ),
                        ],
                        Center(
                          child: Image.memory(
                            image!,
                            width: 400,
                            height: 200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSaveImage != null)
                    Column(
                      children: [
                        const SizedBox(
                          height: 20,
                        ),
                        _buildCustomButton(
                          label: 'ポストする',
                          onPressed: (isSaveImage!)
                              ? () {
                                  try {
                                    //isPostPush = true;
                                    debugPrint('imageId:$imageId');
                                    _tweet();
                                    setState(() {
                                      isPostX = true;
                                    });
                                  } catch (e) {
                                    debugPrint("エラー発生: $e");
                                  }
                                }
                              : null,
                        ),
                        //Expanded(child: SizedBox())
                      ],
                    ),
                ],
              ),
            ),
          ],
          Align(
            alignment: const Alignment(0.33, -0.55),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange, // ボタンの背景色をオレンジに設定
                borderRadius: BorderRadius.circular(8), // 少し丸みを帯びた四角いボタン
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    isPostCancel = true;
                  });
                  // isPostCancel = true;
                  debugPrint('Postをキャンセルしようとしてる');
                },
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white, // アイコンの色を白に設定
                ),
                padding: const EdgeInsets.all(10), // ボタン内の余白
                iconSize: 30, // アイコンのサイズ調整
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCustomButton({
  required String label,
  required void Function()? onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 1, // 影の広がり
          blurRadius: 4, // ぼかし具合
          offset: const Offset(0, 4), // 影の位置（x, y）
        ),
      ],
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFA15E), // ボタンの背景色
        foregroundColor: Colors.white, // テキストの色
        minimumSize: const Size(200, 60), // ボタンのサイズ（幅と高さ）
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // 丸みの半径
        ),
        shadowColor: Colors.transparent, // ElevatedButton自身の影を無効化
        elevation: 0, // ElevatedButton標準影をオフ
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 24, // テキストのサイズ
          fontWeight: FontWeight.bold, // テキストの太さ
        ),
      ),
    ),
  );
}
