
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet/feature_flag/feature_flag_enum.dart';
import 'package:jitsi_meet/jitsi_meet.dart';
import 'package:jitsi_meet/jitsi_meeting_listener.dart';
import 'package:jitsi_meet/room_name_constraint.dart';
import 'package:jitsi_meet/room_name_constraint_type.dart';

class jitsiMeet{
  static final jitsiMeet _jitsiMeet = jitsiMeet._internal();

  var serverText = "";
  var roomText = "";
  var subjectText = "";
  var nameText = "";
  var emailText = "";
  var isAudioOnly = true;
  var isAudioMuted = true;
  var isVideoMuted = true;

  factory jitsiMeet(){
    return _jitsiMeet;
  }

  jitsiMeet._internal();


  void StartJetsiListener()
  {
    JitsiMeet.addListener(JitsiMeetingListener(
        onConferenceWillJoin: _onConferenceWillJoin,
        onConferenceJoined: _onConferenceJoined,
        onConferenceTerminated: _onConferenceTerminated,
        onError: _onError));
  }

  void stopJetsiListerner()
  {
    JitsiMeet.removeAllListeners();
  }

  String _Base64(String s) {
    String credentials = s;
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(credentials);
    String replaced = encoded.replaceAll(RegExp('='), '');
    return replaced;
  }

  void joinMeeting(String storyTitle,String roomID) async {
    String serverUrl =
    serverText.trim()?.isEmpty ?? "" ? null : serverText;
    bool hideTitle = false;

    if(storyTitle != "")
    {
      String encoded = _Base64(storyTitle);
      roomText = encoded;
      subjectText = storyTitle;
    }
    else
    {
      roomText = roomID;
      hideTitle = true;
    }

    try {
      // Enable or disable any feature flag here
      // If feature flag are not provided, default values will be used
      // Full list of feature flags (and defaults) available in the README
      Map<FeatureFlagEnum, bool> featureFlags = {
        FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
        FeatureFlagEnum.LIVE_STREAMING_ENABLED: false,
        FeatureFlagEnum.INVITE_ENABLED: false,
        //FeatureFlagEnum.MEETING_NAME_ENABLED: false,
      };

      // Here is an example, disabling features for each platform
      if (Platform.isAndroid) {
        // Disable ConnectionService usage on Android to avoid issues (see README)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        // Disable PIP on iOS as it looks weird
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      }

      if(hideTitle)
      {
        featureFlags[FeatureFlagEnum.MEETING_NAME_ENABLED] = false;
      }

      // Define meetings options here
      var options = JitsiMeetingOptions()
        ..room = roomText
        ..serverURL = serverUrl
        ..subject = subjectText
        ..userDisplayName = nameText
        ..userEmail = emailText
        ..audioOnly = isAudioOnly
        ..audioMuted = isAudioMuted
        ..videoMuted = isVideoMuted
        ..featureFlags.addAll(featureFlags);

      debugPrint("JitsiMeetingOptions: $options");
      await JitsiMeet.joinMeeting(
        options,
        listener: JitsiMeetingListener(onConferenceWillJoin: ({message}) {
          debugPrint("${options.room} will join with message: $message");
        }, onConferenceJoined: ({message}) {
          debugPrint("${options.room} joined with message: $message");
        }, onConferenceTerminated: ({message}) {
          debugPrint("${options.room} terminated with message: $message");
        }),
        // by default, plugin default constraints are used
        //roomNameConstraints: new Map(), // to disable all constraints
        //roomNameConstraints: customContraints, // to use your own constraint(s)
      );
    } catch (error) {
      debugPrint("error: $error");
    }
  }

  static final Map<RoomNameConstraintType, RoomNameConstraint>
  customContraints = {
    RoomNameConstraintType.MAX_LENGTH: new RoomNameConstraint((value) {
      return value.trim().length <= 50;
    }, "Maximum room name length should be 30."),
    RoomNameConstraintType.FORBIDDEN_CHARS: new RoomNameConstraint((value) {
      return RegExp(r"[$€£]+", caseSensitive: false, multiLine: false)
          .hasMatch(value) ==
          false;
    }, "Currencies characters aren't allowed in room names."),
  };

  void _onConferenceWillJoin({message}) {
    debugPrint("_onConferenceWillJoin broadcasted with message: $message");
  }

  void _onConferenceJoined({message}) {
    debugPrint("_onConferenceJoined broadcasted with message: $message");
  }

  void _onConferenceTerminated({message}) {
    debugPrint("_onConferenceTerminated broadcasted with message: $message");
    FirebaseDatabase.instance.reference().child('call').child('userid').remove();
  }

  _onError(error) {
    debugPrint("_onError broadcasted: $error");
  }

}