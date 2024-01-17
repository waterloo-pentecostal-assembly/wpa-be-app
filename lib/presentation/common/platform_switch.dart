import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/app/constants.dart';

class PlatformSwitch extends StatefulWidget {
  final bool value;
  final void Function(bool)? onChanged;
  final bool disabled;

  const PlatformSwitch({
    Key? key,
    this.value = false,
    this.onChanged,
    this.disabled = false,
  }) : super(key: key);

  @override
  _PlatformSwitchState createState() => _PlatformSwitchState();
}

class _PlatformSwitchState extends State<PlatformSwitch> {
  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      if (widget.disabled) {
        return iOSSwitchDisabled();
      }
      return iOSSwitch();
    } else {
      if (widget.disabled) {
        return androidSwitchDisabled();
      }
      return androidSwitch();
    }
  }

  Widget iOSSwitch() {
    return CupertinoSwitch(
      value: widget.value,
      onChanged: widget.onChanged,
      activeColor: kWpaBlue.withOpacity(0.6),
    );
  }

  Widget iOSSwitchDisabled() {
    return CupertinoSwitch(
      value: false,
      onChanged: null,
    );
  }

  Widget androidSwitch() {
    return Switch(
      value: widget.value,
      onChanged: widget.onChanged,
      activeTrackColor: kWpaBlue.withOpacity(0.25),
      activeColor: kWpaBlue.withOpacity(0.6),
    );
  }

  Widget androidSwitchDisabled() {
    return Switch(
      value: false,
      onChanged: null,
    );
  }
}
