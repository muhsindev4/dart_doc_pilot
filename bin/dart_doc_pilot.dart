#!/usr/bin/env dart

import 'package:dart_doc_pilot/cli.dart';

void main(List<String> arguments) async {
  final cli = DartDocPilotCLI();
  await cli.run(arguments);
}
