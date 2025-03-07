import 'package:flutter/material.dart';

extension FluentWidgets on Widget {
  Padding pad(double padding) =>
      Padding(padding: EdgeInsets.all(padding), child: this);
}
