import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlatformSwitch extends StatefulWidget {
  final bool value;
  final void Function(bool) onChanged;
  final Color activeColor;
  final bool disabled;

  const PlatformSwitch({
    Key key,
    this.value,
    this.onChanged,
    this.activeColor,
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
      activeColor: widget.activeColor,
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
      activeTrackColor: widget.activeColor.withOpacity(0.25),
      activeColor: widget.activeColor,
    );
  }

  Widget androidSwitchDisabled() {
    return Switch(
      value: false,
      onChanged: null,
    );
  }
}
