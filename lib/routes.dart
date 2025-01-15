import 'package:ebidence/view/developer/send_firebase.dart';
import 'package:ebidence/view/result.dart';
import 'package:ebidence/view/result_card.dart';
import 'package:ebidence/view/result_card_row.dart';
import 'package:ebidence/view/select_subject_page.dart';
import 'package:ebidence/view/start_page.dart';
import 'package:ebidence/viewmodel/quiz.dart';
import 'package:ebidence/viewmodel/result.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/startpage',
    routes: [
      GoRoute(
        path: '/quiz/:quizIndex',
        builder: (context, state) {
          return const QuizScreen();
        },
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) {
          final isCheakAllFalse = state.extra as bool? ?? false; // 安全な型キャスト
          return ResultPage1(isCheakAllFalse);
        },
      ),
      GoRoute(
          path: '/',
          builder: (context, state) {
            return const SendFirebase();
          }),
      GoRoute(
          path: '/result/:_imageId',
          builder: (context, state) {
            final imageId = state.pathParameters['_imageId']!;
            return ResultPage(imageId: imageId);
          }),
      GoRoute(
          path: '/result_flash_card',
          builder: (context, state) {
            return const ResultFlashCard();
          }),
      GoRoute(
          path: '/selectsubject',
          builder: (context, state) {
            return const SelectSubjectPage();
          }),
      GoRoute(
          path: '/startpage',
          builder: (context, state) {
            return const StartPage();
          }),
    ]);
