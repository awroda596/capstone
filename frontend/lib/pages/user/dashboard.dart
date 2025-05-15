//my attempt to modularize these functions.  Time perimitting will et them  modularized by before presentation but function first tbh.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/user.dart';
import 'userInfo.dart';
import 'reviewList.dart';
import 'sessionList.dart';
import 'teaCabinet.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String displayName = "";
  String profileImageUrl = "";
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserInfo(),
            const SizedBox(height: 24),
            kIsWeb
                ? Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(child: ReviewList()),
                      SizedBox(width: 16),
                      Expanded(child: TeaLogList()),
                      SizedBox(width: 16),
                      Expanded(child: TeaCabinetList()),
                    ],
                  ),
                )
                : Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(child: ReviewList()),
                        SizedBox(width: 16),
                        Expanded(child: TeaLogList()),
                        SizedBox(width: 16),
                        Expanded(child: TeaCabinetList()),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
