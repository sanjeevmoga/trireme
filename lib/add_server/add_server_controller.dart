/*
 * Trireme for Deluge - A Deluge thin client for Android.
 * Copyright (C) 2018  Aashrava Holla
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:io';

import 'package:trireme_client/trireme_client.dart';

import 'package:trireme/core/persistence.dart';

class AddServerController {
  String validateHost(String host) {
    if (host == null || host.trim().isEmpty) {
      return "Host must not be empty";
    }
    return null;
  }

  String validatePort(String port) {
    if (port == null || port.trim().isEmpty) {
      return "Port must not be empty";
    } else {
      try {
        var portInt = int.parse(port);
        if (portInt < 0 || portInt > 65535) {
          return "Port not in range [0, 65535]";
        }
      } on FormatException {
        return "Port must be valid";
      }
    }
    return null;
  }

  String validateUsername(String username) {
    if (username == null || username.trim().isEmpty) {
      return "Username must not be empty";
    }
    return null;
  }

  String validatePassword(String password) {
    if (password == null || password.trim().isEmpty) {
      return "Password must not be empty";
    }
    return null;
  }

  Future<bool> validateServerCredentials(
      String username, String password, String host, String port) {
    int portInt = int.parse(port);
    TriremeClient client =
    TriremeClient(username, password, host, port: portInt);

    return client
        .init()
        .then((_) => true)
        .catchError((e) {
      var se = e as SocketException;
      if (se.osError != null) {
        if (se.osError.errorCode == 111) {
          throw "Connection refused. Is the deluge server running and configured to accept remote connections?";
        } else if (se.osError.errorCode == 113) {
          throw "No route to host";
        }
      }
      throw "Network error. Could not connect to server.";
    }, test: (e) => e is SocketException)
        .catchError((e) => throw e.toString(), test: (e) => e is DelugeRpcError)
        .whenComplete(() {
      client.dispose();
    });
  }

  Future addServer(String username, String password, String host, String port) async {
    var portInt = int.parse(port);
    var dbModel = ServerDBModel(host, portInt, username, password);
    var database = ServerDetailsDatabase();
    await database.open();
    await database.addServer(dbModel);
    await database.close();
  }
}