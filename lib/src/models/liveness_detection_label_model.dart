import 'dart:convert';

import 'package:flutter/widgets.dart';

LivenessDetectionLabelModel livenessDetectionLabelModelFromJson(String str) =>
    LivenessDetectionLabelModel.fromJson(json.decode(str));

String livenessDetectionLabelModelToJson(LivenessDetectionLabelModel data) =>
    json.encode(data.toJson());

class LivenessDetectionLabelModel {
  String? smile;
  String? lookUp;
  String? lookDown;
  String? lookLeft;
  String? lookRight;
  String? blink;

  /// Optional icon widgets for each step. Pass SvgPicture, Image.asset, etc.
  Widget? iconSmile;
  Widget? iconLookUp;
  Widget? iconLookDown;
  Widget? iconLookLeft;
  Widget? iconLookRight;
  Widget? iconBlink;

  LivenessDetectionLabelModel({
    this.smile,
    this.lookUp,
    this.lookDown,
    this.lookLeft,
    this.lookRight,
    this.blink,
    this.iconSmile,
    this.iconLookUp,
    this.iconLookDown,
    this.iconLookLeft,
    this.iconLookRight,
    this.iconBlink,
  });

  factory LivenessDetectionLabelModel.fromJson(Map<String, dynamic> json) =>
      LivenessDetectionLabelModel(
        smile: json["smile"],
        lookUp: json["lookUp"],
        lookDown: json["lookDown"],
        lookLeft: json["lookLeft"],
        lookRight: json["lookRight"],
        blink: json["blink"],
      );

  Map<String, dynamic> toJson() => {
        "smile": smile,
        "lookUp": lookUp,
        "lookDown": lookDown,
        "lookLeft": lookLeft,
        "lookRight": lookRight,
        "blink": blink,
      };
}
