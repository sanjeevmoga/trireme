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
import 'dart:convert';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:trireme/torrent_list/torrent_list_controller.dart';

const _dbFileName = "trireme.db";
const _dbVersion = 2;
const _tableName = "servers";
const _columnId = "id";
const _columnHost = "host";
const _columnPort = "port";
const _columnUsername = "username";
const _columnPassword = "password";
const _columnCertificate = "certificate";

class ServerDBModel {
  final int id;
  final String host;
  final int port;
  final String username;
  final String password;
  final String certificate;

  ServerDBModel._(this.id, this.host, this.port, this.username, this.password,
      this.certificate);

  Map<String, Object> toMap() {
    var map = {
      _columnHost: host,
      _columnPort: port,
      _columnUsername: username,
      _columnPassword: password,
      _columnCertificate: certificate
    };

    if (id != null) {
      map[_columnId] = id;
    }

    return map;
  }

  factory ServerDBModel.fromMap(Map<String, Object> map) {
    return ServerDBModel._(map[_columnId], map[_columnHost], map[_columnPort],
        map[_columnUsername], map[_columnPassword], map[_columnCertificate]);
  }

  factory ServerDBModel(String host, int port, String username, String password,
      String certificate) {
    return ServerDBModel._(
        null, host, port, username, password, certificate ?? "");
  }

  @override
  String toString() => "$username@$host";
}

class ServerDetailsDatabase {
  Database _database;

  Future open() async {
    var appDataDir = await getApplicationDocumentsDirectory();
    var path = join(appDataDir.path, _dbFileName);
    _database = await openDatabase(path,
        version: _dbVersion, onCreate: _createDb, onUpgrade: _upgradeDb);
  }

  Future addServer(ServerDBModel server) async {
    await _database.insert(_tableName, server.toMap());
  }

  Future<List<ServerDBModel>> getServers() async {
    var records = await _database.query(_tableName);
    return records.map((map) => ServerDBModel.fromMap(map)).toList();
  }

  Future updateServer(ServerDBModel oldData, ServerDBModel newData) async {
    await deleteServer(oldData);
    await addServer(newData);
  }

  Future deleteServer(ServerDBModel server) async {
    await _database
        .delete(_tableName, where: "$_columnId = ?", whereArgs: [server.id]);
  }

  Future close() async {
    await _database.close();
    _database = null;
  }
}

void _createDb(Database db, int version) async {
  await db.execute(""
      "create table $_tableName ("
      "$_columnId integer primary key autoincrement,"
      "$_columnHost text not null,"
      "$_columnPort integer not null,"
      "$_columnUsername text not null,"
      "$_columnPassword text not null,"
      "$_columnCertificate text not null)");
}

void _upgradeDb(Database db, int oldVersion, int newVersion) async {
  switch (oldVersion) {
    case 1:
      await db.execute(
          "alter table $_tableName add column $_columnCertificate text not null "
          "default ''");
  }
}

const _sortModeKey = "sortMode";

Future saveSortMode(SortCriteria sortMode) async {
  var s = await SharedPreferences.getInstance();
  s.setString(_sortModeKey, sortMode.toString());
}

Future<SortCriteria> getSavedSortMode() async {
  var s = await SharedPreferences.getInstance();
  var sortStr = s.get(_sortModeKey);
  return SortCriteria.values.firstWhere((s) => s.toString() == sortStr,
      orElse: () => SortCriteria.name);
}

const _reverseKey = "reverseSort";

Future saveSortReverse(bool reverse) async {
  var s = await SharedPreferences.getInstance();
  s.setBool(_reverseKey, reverse);
}

Future<bool> getSavedSortReverseMode() async {
  var s = await SharedPreferences.getInstance();
  return s.getBool(_reverseKey) ?? false;
}

const _filterSpecKey = "filterSpec";

Future saveFilter(FilterSpec f) async {
  var s = await SharedPreferences.getInstance();
  s.setString(_filterSpecKey, json.encode(f.toFilterDict()));
}

Future<FilterSpec> getSavedFilterSpec() async {
  var s = await SharedPreferences.getInstance();
  var filterStr = s.getString(_filterSpecKey);
  if (filterStr == null) {
    return FilterSpec.all;
  } else {
    Map<String, String> filterDict =
        (json.decode(filterStr) as Map).cast<String, String>();
    return FilterSpec(
        filterDict["state"] ?? FilterSpec.strAll,
        filterDict["label"] ?? FilterSpec.strAll,
        filterDict["tracker_host"] ?? FilterSpec.strAll);
  }
}
