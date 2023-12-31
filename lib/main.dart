import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const tempToken =
    "007eJxTYOD50/dUOb6ghjVjmcmMHaUuglGzpoX9DXzHI56y/E9Q90cFhjRzU4Nk0xQTkxRTAxNjS3ML40RT01RLA/Nk47S0NFPj9eX7UxoCGRkO/rjJwsgAgSC+AENaZlFxSUhqcYlzRmJeXmoOAwMA6m0lKA==";
const appId = "f750c5d44d50439783a55e907c3fff53";
const channelName = "firstTestChannel";

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int? _remoteUid;
  bool _localUserJoined = false;
  RtcEngine? _engine;

  @override
  void initState() {
    initializeAgora();
    super.initState();
  }

  Future<void> initializeAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print('User Joined');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("remote user $remoteUid joined");
          setState(
            () {
              _remoteUid = remoteUid;
            },
          );
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          print("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          print(
            '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token',
          );
        },
      ),
    );
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableVideo();
    await _engine!.startPreview();

    await _engine!.joinChannel(
      token: tempToken,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: _renderRemoteView(
                engine: _engine,
                remoteUid: _remoteUid,
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 150,
                height: 200,
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: _localUserJoined
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _renderRemoteView({required remoteUid, required engine}) {
  if (remoteUid != null) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: remoteUid),
        connection: const RtcConnection(
          channelId: channelName,
        ),
      ),
    );
  } else {
    return const Text(
      'Please wait for remote user to join',
      textAlign: TextAlign.center,
    );
  }
}
