import 'package:ev_charger/controllers/session_controller.dart';
import 'package:ev_charger/models/active_session_model.dart';
import 'package:ev_charger/models/smtp_view_model.dart';
import 'package:ev_charger/views/widgets/dialog/custom_info_bar.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:ev_charger/models/chargers_view_model.dart';
import 'package:ev_charger/services/background_service.dart';
import 'package:get/get.dart';

class DatabaseHelper {
  // Name of the database file.
  static const _databaseName = "EvCharger_test101.db";
  //static const _databaseName = "EvCharger17A.db";
  // Version of the database, used for migrations and upgrades.
  static const _databaseVersion = 1;

  // Private constructor for the singleton pattern.
  DatabaseHelper._privateConstructor();

  // The single instance of DatabaseHelper.
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  final Logger log = Logger();

  // The database instance.
  Database? _database;

  // Getter for the database. It initializes the database if it doesn't exist.
  Future<Database> get database async {
    _database ??= await initDatabase();
    return _database!;
  }

  // Initializes the database.
  Future<Database> initDatabase() async {
    // Initialize the FFI (Foreign Function Interface) for sqflite.
    // This is necessary for using sqflite in a non-mobile environment (e.g., desktop).
    sqfliteFfiInit(); // Initialize FFI

    // Sets the database factory to the FFI version.
    final databaseFactory = databaseFactoryFfi;

    // Gets the directory where the database file will be stored.
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    // Joins the directory with the database name to get the full path.
    String path = join(documentsDirectory.path, _databaseName);

    // Opens the database and creates it if it doesn't exist.
    return await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: _databaseVersion,
          onCreate: _onCreate,
        ));
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_name TEXT NOT NULL,
          status TEXT NOT NULL
        )
      ''');

    await db.execute('''
    CREATE TABLE chargers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        charge_point_vendor TEXT NOT NULL,
        charge_point_model TEXT NOT NULL,
        charge_point_serial_number TEXT NOT NULL,
        firmware_version TEXT NOT NULL,
        charge_box_serial_number TEXT NOT NULL,
        interval_time TEXT NOT NULL,
        next_update INTEGER NOT NULL,
        url_to_connect TEXT NOT NULL,
        group_id INTEGER NOT NULL,
        maximum_charging_power TEXT NOT NULL,
        meter_value TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT "",
        charging_status TEXT NOT NULL DEFAULT "",
        FOREIGN KEY(group_id) REFERENCES groups(id)
      )
    ''');

    await db.execute('''
    CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_number TEXT NOT NULL,
        msp TEXT NOT NULL,
        uid TEXT NOT NULL,
        min_kwh_per_session TEXT NOT NULL,
        max_kwh_per_session TEXT NOT NULL,
        min_session_time TEXT NOT NULL,
        max_session_time TEXT NOT NULL,
        usage_hours TEXT NOT NULL,
        min_interval_before_reuse TEXT NOT NULL,
        group_id INTEGER NOT NULL,
        reference TEXT NOT NULL,
        time INTEGER NOT NULL,
        begin_meter_value REAL NOT NULL DEFAULT 0,
        last_meter_value REAL NOT NULL DEFAULT 0,
        times TEXT NOT NULL,
        days_from TEXT NOT NULL,
        days_until TEXT NOT NULL,
        charger_id TEXT NOT NULL DEFAULT "",
        FOREIGN KEY(group_id) REFERENCES groups(id)
      )
    ''');

    await db.execute('''
    CREATE TABLE notification_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        messageId INTEGER NOT NULL,
        charger_id INTEGER NOT NULL UNIQUE,
        uid TEXT NOT NULL DEFAULT "",
        transactionId INTEGER NOT NULL UNIQUE,
        meter_value DOUBLE NOT NULL,
        begin_meter_value DOUBLE NOT NULL,
        start_time TEXT NOT NULL,
        status TEXT NOT NULL,
        numberOfCharge INTEGER NOT NULL,
        numberOfChargeDays INTEGER NOT NULL,
        FOREIGN KEY(charger_id) REFERENCES chargers(id)
      )
    ''');

    await db.execute('''
    CREATE TABLE active_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        charger_id INTEGER NOT NULL UNIQUE,
        card_id INTEGER NOT NULL,
        transaction_start_time INTEGER NOT NULL,
        kwh TEXT NOT NULL,
        session_time TEXT NOT NULL,
        FOREIGN KEY(charger_id) REFERENCES chargers(id),
        FOREIGN KEY(card_id) REFERENCES cards(id)
    );
    ''');

    await db.execute('''
    CREATE TABLE smtp (
        id INTEGER PRIMARY KEY,
        email TEXT NOT NULL,
        password TEXT NOT NULL
    );
    ''');

    await db.execute('''
    CREATE TABLE receiver_email (
        id INTEGER PRIMARY KEY,
        email TEXT NOT NULL
    );
    ''');

    await db.execute('''
    CREATE TABLE time_format (
        id INTEGER PRIMARY KEY,
        utc_time TEXT NOT NULL,
        date TEXT NOT NULL DEFAULT "",
        time TEXT NOT NULL DEFAULT ""
    );
    ''');
  }

  ///...................CRUD operation for Group..................///
  /// Insert a new group
  Future<void> insertGroup(Map<String, dynamic> group) async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      'groups',
      group,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all customers
  Future<List<Map<String, dynamic>>> getGroups() async {
    Database db = await DatabaseHelper.instance.database;
    return await db.query('groups');
  }

  /// Retrieves a paginated list of customers from the database.
  Future<List<Map<String, dynamic>>> getGroupsPaginated(
      int pageNumber, int itemsPerPage,
      {String? searchQuery}) async {
    Database db = await DatabaseHelper.instance.database;

    int offset = (pageNumber - 1) * itemsPerPage;

    String whereString = '';
    List<dynamic> whereArguments = [];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereString = 'group_name LIKE ? OR status LIKE ?';
      whereArguments = List.filled(2, '%$searchQuery%');
    }

    return await db.query(
      'groups',
      where: whereString.isEmpty ? null : whereString,
      whereArgs: whereArguments.isEmpty ? null : whereArguments,
      orderBy: 'id DESC',
      limit: itemsPerPage,
      offset: offset,
    );
  }

  /// Counts all group records in the database.
  Future<int> getTotalGroupCount() async {
    final Database db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('SELECT COUNT(*) as count FROM groups');
    int count = 0;
    if (data.isNotEmpty) {
      count = data.first['count'] as int;
    }
    return count;
  }

  /// update a groups
  Future<void> updateGroup(Map<String, dynamic> group, int id) async {
    Database db = await instance.database;

    await db.update(
      'groups',
      group,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// delete a groups
  Future<void> deleteGroup(int id) async {
    Database db = await instance.database;

    // Proceed with the delete operation since the database is available
    await db.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  ///...................CRUD operation for Charger..................///
  /// Insert a new charger
  Future<void> insertCharger(
      BuildContext context, Map<String, dynamic> charger) async {
    Database db = await database; // Assume you have a getter for the database

    // Extract relevant fields from the charger map
    String chargeBoxSerialNumber = charger['charge_box_serial_number'];
    String urlToConnect = charger['url_to_connect'];

    // Query to check for existing record with the same charge_box_serial_number and url_to_connect
    List<Map<String, dynamic>> existingRecords = await db.query(
      'chargers',
      where: 'charge_box_serial_number = ? AND url_to_connect = ?',
      whereArgs: [chargeBoxSerialNumber, urlToConnect],
    );

    // If no existing record is found, proceed with the insertion
    if (existingRecords.isEmpty) {
      try {
        int insertedId = await db.insert('chargers', charger,
            conflictAlgorithm: ConflictAlgorithm.replace);
        // print("Charger inserted successfully.");
        // Pass the inserted ID along with charger details to create a ChargersViewModel instance
        ChargersViewModel chargersViewModel = ChargersViewModel(
          id: insertedId,
          chargePointVendor: charger['charge_point_vendor'],
          chargePointModel: charger['charge_point_model'],
          chargePointSerialNumber: charger['charge_point_serial_number'],
          firmwareVersion: charger['firmware_version'],
          chargeBoxSerialNumber: charger['charge_box_serial_number'],
          intervalTime: charger['interval_time'],
          lastUpdate: charger['next_update'],
          urlToConnect: charger['url_to_connect'],
          groupName: charger['group_name'],
          groupId: charger['group_id'],
          maximumChargingPower: charger['maximum_charging_power'],
          meterValue: charger['meter_value'],
          status: charger['status'],
          chargingStatus: charger['charging_status'],
        );
        // Call getChargerDetails with the ChargersViewModel object
        BackgroundService().sendNewChargerBootNotification(chargersViewModel);
      } catch (e) {
        //  print("Error inserting charger: $e");
        // Handle any errors that occur during the insertion process
      }
    } else {
      CustomInfoBar.show(context,
          title: "Action not allowed. :/",
          content:
              "Charger with the same charge box serial number and URL to connect already exists.",
          infoBarSeverity: InfoBarSeverity.warning);
      print(
          "Charger with the same charge box serial number and URL to connect already exists.");
    }
  }

  /// Retrieve all chargers
  Future<List<Map<String, dynamic>>> getChargers() async {
    Database db = await DatabaseHelper.instance.database;
    return await db.query('chargers');
  }

  /// Retrieves a paginated list of chargers from the database.
  Future<List<Map<String, dynamic>>> getChargerPaginated(
      int pageNumber, int itemsPerPage,
      {String? searchQuery}) async {
    Database db = await DatabaseHelper.instance.database;
    int offset = (pageNumber - 1) * itemsPerPage;

    // Start building the raw SQL query
    String sql = '''
  SELECT chargers.*, groups.group_name 
  FROM chargers
  JOIN groups ON chargers.group_id = groups.id
  ''';

    // Initialize an empty list for WHERE clause conditions and arguments
    List<String> whereConditions = [];
    List<dynamic> whereArguments = [];

    // Check if a search query is provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Add conditions for each searchable field, including the group_name from the joined groups table
      whereConditions.addAll([
        'charge_point_vendor LIKE ?',
        'charge_point_model LIKE ?',
        'charge_point_serial_number LIKE ?',
        'firmware_version LIKE ?',
        'charge_box_serial_number LIKE ?',
        'groups.group_name LIKE ?' // Include group_name in the search
      ]);
      // Add the search query for each condition to whereArguments
      for (var condition in whereConditions) {
        whereArguments.add('%$searchQuery%');
      }
    }

    // If there are any WHERE conditions, append them to the SQL query
    if (whereConditions.isNotEmpty) {
      sql += ' WHERE ${whereConditions.join(' OR ')}';
    }

    // Add ordering, limit, and offset to the query
    sql += ' ORDER BY chargers.id DESC LIMIT ? OFFSET ?';
    // Now add the pagination parameters to the whereArguments
    whereArguments.add(itemsPerPage);
    whereArguments.add(offset);

    // Execute the query and return the results
    return await db.rawQuery(sql, whereArguments);
  }

  /// Counts all charger records in the database.
  Future<int> getTotalChargerCount() async {
    final Database db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('SELECT COUNT(*) as count FROM chargers');
    int count = 0;
    if (data.isNotEmpty) {
      count = data.first['count'] as int;
    }
    return count;
  }

  Future<int> updateTime(int chargerId, int? intervalTime) async {
    final db = await database;
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/
        1000; // Get current Unix timestamp

    // print("Next: $currentTime + $intervalTime");
    var charger = await db.query('chargers',
        where: 'id = ?', whereArgs: [chargerId], limit: 1);
    if (charger.isNotEmpty) {
      int newUpdateTime =
          intervalTime == null ? currentTime + 0 : currentTime + intervalTime;
      int result = await db.update(
        'chargers',
        {'next_update': newUpdateTime},
        where: 'id = ?',
        whereArgs: [chargerId],
      );

      return result;
    }
    return 0; // No update if charger not found
  }

  Future<Map<String, dynamic>?> queryDueChargers() async {
    final db = await database;
    int currentTime =
        DateTime.now().millisecondsSinceEpoch ~/ 1000; // Current Unix timestamp

    List<Map<String, dynamic>> result = await db.query(
      'chargers',
      where: 'next_update < ?',
      whereArgs: [currentTime],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null; // Return null if no due chargers are found
    }
  }

  Future<void> updateBeginMeterValue(
      int chargerId, double newBeginMeterValue) async {
    // Get a reference to the database.
    final db = await database; // Assuming 'database' is your database instance.

    // Update the 'begin_meter_value' field with the new value for the specified card ID.
    int updateCount = await db.update(
      'chargers',
      {
        'meter_value': newBeginMeterValue
      }, // Directly updating the 'begin_meter_value' field
      where: 'id = ?', // Using the card ID as the unique identifier
      whereArgs: [chargerId],
    );

    // Optionally, you can use updateCount to check if the update was successful
    if (updateCount > 0) {
      // print('Update successful');
    } else {
      // print('Update failed');
    }
  }

  /// update a charger
  Future<void> updateCharger(Map<String, dynamic> charger, int id) async {
    Database db = await instance.database;

    await db.update(
      'chargers',
      charger,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// delete a charger
  Future<void> deleteCharger(int id) async {
    Database db = await instance.database;

    // Proceed with the delete operation since the database is available
    await db.delete(
      'chargers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateChargerStatus(int chargerId, String status) async {
    Database db = await instance.database;
    final SessionController sessionController = Get.find<SessionController>();
    // print("charger status: $status");
    // Update statement
    await db.update(
      'chargers', // Table name
      {'status': status}, // Values to update
      where: 'id = ?', // Condition to find the right row
      whereArgs: [chargerId], // Values for where condition
    );

    sessionController.addAllChargers();
  }

  Future<void> updateChargingStatus(
      int chargerId, String chargingStatus, int stop) async {
    // print("chargingStatus status: $chargingStatus for $chargerId");
    Database db = await instance.database;
    final SessionController sessionController = Get.find<SessionController>();

    final List<Map<String, dynamic>> rows = await db.rawQuery('''
    SELECT charging_status,charge_box_serial_number FROM chargers WHERE id = ? LIMIT 1
  ''', [chargerId]);

    log.i("chargerID $chargerId $chargingStatus   #### ${rows.first['charge_box_serial_number']}  ${rows.first['charging_status']}");
    log.t("stop data $stop");
    if (rows.isNotEmpty) {
      if(rows.first['charging_status'] == 'waiting'){
        if(chargingStatus != 'start'){
          await db.update(
            'chargers',
            {'charging_status': chargingStatus}, // Values to update
            where: 'id = ?', // Condition to find the right row
            whereArgs: [chargerId], // Values for where condition
          );
        }else if(stop == -1){
          log.e("charger stopped   #### ${rows.first['charge_box_serial_number']} ");
          await db.update(
            'chargers',
            {'charging_status': chargingStatus}, // Values to update
            where: 'id = ?', // Condition to find the right row
            whereArgs: [chargerId], // Values for where condition
          );
        }
      }else {
        await db.update(
          'chargers',
          {'charging_status': chargingStatus}, // Values to update
          where: 'id = ?', // Condition to find the right row
          whereArgs: [chargerId], // Values for where condition
        );
      }
    }

    sessionController.addAllChargers();
  }

  // Future<bool> isCombinationUnique(String urlToConnect,) async {
  //   Database db = await instance.database;
  //
  //   // Combine the fields
  //   String combined = urlToConnect;
  //
  //   // Query to check for existing combinations
  //   // Note: This assumes you have a combined field. If not, you might need to adjust your database model
  //   // or use a more complex query to dynamically concatenate fields
  //   String sql = '''
  //   SELECT COUNT(*) AS count
  //   FROM chargers
  //   WHERE url_to_connect = ?
  // ''';
  //
  //   // Execute the query
  //   List<Map<String, dynamic>> result = await db.rawQuery(sql, [combined]);
  //
  //   // Check the count
  //   int count = result.first["count"];
  //
  //   // Return true if the combination is unique, false otherwise
  //   return count == 0;
  // }

  Future<bool> isCombinationUnique(String urlToConnect, {String? id}) async {
    Database db = await instance.database;

    // Combine the fields
    String combined = urlToConnect;

    // Start building the query
    String sql = '''
  SELECT COUNT(*) AS count 
  FROM chargers 
  WHERE url_to_connect = ?
  ''';

    // The arguments for the query
    List<dynamic> arguments = [combined];

    // If an id is provided, adjust the query to exclude it
    if (id != null) {
      sql += ' AND id <> ?';
      arguments.add(id);
    }

    // Execute the query
    List<Map<String, dynamic>> result = await db.rawQuery(sql, arguments);

    // Check the count
    int count = result.first["count"];

    // Return true if the combination is unique, false otherwise
    return count == 0;
  }

  ///...................CRUD operation for cards..................///
  /// Insert a new card
  Future<void> insertCard(Map<String, dynamic> charger) async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      'cards',
      charger,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve all cards
  Future<List<Map<String, dynamic>>> getCards() async {
    Database db = await DatabaseHelper.instance.database;
    return await db.query('cards');
  }

  Future<List<Map<String, dynamic>>> getCardsByGroup(int groupId) async {
    Database db = await DatabaseHelper.instance.database;

    return await db.query(
      'cards',
      where: 'group_id = ?', // Using the card ID as the unique identifier
      whereArgs: [groupId],
    );
  }

  /// Retrieves a paginated list of cards from the database.
  Future<List<Map<String, dynamic>>> getCardPaginated(
      int pageNumber, int itemsPerPage,
      {String? searchQuery}) async {
    Database db = await DatabaseHelper.instance.database;
    int offset = (pageNumber - 1) * itemsPerPage;

    // Start building the raw SQL query
    String sql = '''
  SELECT cards.*, groups.group_name 
  FROM cards
  JOIN groups ON cards.group_id = groups.id
  ''';

    // Initialize an empty list for WHERE clause conditions and arguments
    List<String> whereConditions = [];
    List<dynamic> whereArguments = [];

    // Check if a search query is provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Add conditions for each searchable field, including the group_name from the joined groups table
      whereConditions.addAll([
        'card_number LIKE ?',
        'msp LIKE ?',
        'uid LIKE ?',
        'min_kwh_per_session LIKE ?',
        'max_kwh_per_session LIKE ?',
        'usage_hours LIKE ?',
        'min_interval_before_reuse LIKE ?',
        'groups.group_name LIKE ?' // Include group_name in the search
      ]);
      // Add the search query for each condition to whereArguments
      for (var condition in whereConditions) {
        whereArguments.add('%$searchQuery%');
      }
    }

    // If there are any WHERE conditions, append them to the SQL query
    if (whereConditions.isNotEmpty) {
      sql += ' WHERE ${whereConditions.join(' OR ')}';
    }

    // Correct the 'ORDER BY' clause to use 'cards.id' instead of 'chargers.id'
    sql += ' ORDER BY cards.id DESC LIMIT ? OFFSET ?';
    // Now add the pagination parameters to the whereArguments
    whereArguments.add(itemsPerPage);
    whereArguments.add(offset);

    // Execute the query and return the results
    return await db.rawQuery(sql, whereArguments);
  }

  /// Counts all card records in the database.
  Future<int> getTotalCardCount() async {
    final Database db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('SELECT COUNT(*) as count FROM cards');
    int count = 0;
    if (data.isNotEmpty) {
      count = data.first['count'] as int;
    }
    return count;
  }

  Future<Map<String, dynamic>?> getCardByGroupAndTime(int groupId) async {
    Database db = await DatabaseHelper.instance.database;

    // Get the current time as a whole hour in 24-hour format
    DateTime now = DateTime.now();
    int currentHour = now.hour;
    int currentTime =
        DateTime.now().millisecondsSinceEpoch ~/ 1000; // Current Unix timestamp

    // Query to select the matching card, assuming usage_hours like "22 - 23"
    var result = await db.rawQuery('''
    SELECT * FROM cards
    WHERE group_id = ? 
    AND charger_id = '' 
    AND time < ?
    AND (
      (CAST(substr(usage_hours, 1, instr(usage_hours, ' - ') - 1) AS INTEGER) < CAST(substr(usage_hours, instr(usage_hours, ' - ') + 3) AS INTEGER)
        AND ? >= CAST(substr(usage_hours, 1, instr(usage_hours, ' - ') - 1) AS INTEGER)
        AND ? < CAST(substr(usage_hours, instr(usage_hours, ' - ') + 3) AS INTEGER))
      OR
      (CAST(substr(usage_hours, 1, instr(usage_hours, ' - ') - 1) AS INTEGER) > CAST(substr(usage_hours, instr(usage_hours, ' - ') + 3) AS INTEGER)
        AND (? >= CAST(substr(usage_hours, 1, instr(usage_hours, ' - ') - 1) AS INTEGER) OR ? < CAST(substr(usage_hours, instr(usage_hours, ' - ') + 3) AS INTEGER)))
    )
    ORDER BY RANDOM()
    LIMIT 1
  ''', [
      groupId,
      currentTime,
      currentHour,
      currentHour,
      currentHour,
      currentHour
    ]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> updateTimeField(int cardId, int newTime) async {
    // Get a reference to the database.

    final db = await database; // Assuming 'database' is your database instance.

    // Update the 'time' field with the new value for the specified card ID.
    int updateCount = await db.update(
      'cards',
      {'time': newTime}, // Directly updating the 'time' field
      where: 'id = ?', // Using the card ID as the unique identifier
      whereArgs: [cardId],
    );

    // Optionally, you can use updateCount to check if the update was successful
    if (updateCount > 0) {
      // print('Update successful');
    } else {
      //  print('Update failed');
    }
  }

  /// update a card
  Future<void> updateCard(Map<String, dynamic> card, int id) async {
    Database db = await instance.database;

    await db.update(
      'cards',
      card,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// delete a charger
  Future<void> deleteCards(int id) async {
    Database db = await instance.database;

    // Proceed with the delete operation since the database is available
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

// get single charger by id
  Future<Map<String, dynamic>?> getChargerById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> chargers = await db.query(
      'chargers',
      where: 'id = ?',
      whereArgs: [id],
    );
    return chargers.isNotEmpty ? chargers.first : null;
  }

// get single card by id
  Future<Map<String, dynamic>?> getCardById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> cards = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    return cards.isNotEmpty ? cards.first : null;
  }

  // get single card by id
  Future<Map<String, dynamic>?> getCardByChargerId(int chargerId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> cards = await db.query(
      'cards',
      where: 'charger_id = ?',
      whereArgs: [chargerId],
    );
    return cards.isNotEmpty ? cards.first : null;
  }

  Future<void> removeChargerId(int chargerId, String newChargerId) async {
    Database db = await instance.database;
    // Proceed with the update if the charger_id is either unique or an empty string
    await db.update(
      'cards', // Table name
      {'charger_id': newChargerId}, // Values to update
      where: 'charger_id = ?', // Condition to find the right row
      whereArgs: [chargerId], // Values for where condition
    );
  }

  Future<void> updateChargerId(int cardId, String newChargerId) async {
    Database db = await instance.database;
    // Proceed with the update if the charger_id is either unique or an empty string
    // print('$newChargerId chargerID updated successfully for');
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
    SELECT charger_id FROM cards WHERE charger_id = ? LIMIT 1
  ''', [newChargerId]);

    log.i("cardID $cardId $newChargerId  #### ${rows.length}");
    if(rows.isEmpty){
        await db.update(
          'cards', // Table name
          {'charger_id': newChargerId}, // Values to update
          where: 'id = ?', // Condition to find the right row
          whereArgs: [cardId], // Values for where condition
        );
    }
  }

  ///.......................notification log...................///
  // will be unique
  Future<void> logNotification({
    required int messageId,
    required int chargerId,
    required String uid,
    required int transactionId,
    required double meterValue,
    required double beginMeterValue,
    required String startTime,
    required String status,
    required int numberOfCharge,
    required int numberOfChargeDays,
  }) async {
    final Database db = await DatabaseHelper.instance.database;

    // Step 1: Try to fetch the existing row to see if it needs an update or an insert
    List<Map> existingRows = await db.query(
      'notification_log',
      where: 'charger_id = ?',
      whereArgs: [chargerId],
    );

    Map? existingRow = existingRows.isNotEmpty ? existingRows.first : null;

    // Since charger_id is UNIQUE, we use INSERT OR REPLACE to update existing rows or insert new ones.
    // Make sure to include all required fields based on the table schema.
    await db.execute('''
    INSERT OR REPLACE INTO notification_log (messageId,charger_id, uid, transactionId, meter_value, begin_meter_value, start_time, status, numberOfCharge, numberOfChargeDays)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''', [
      messageId,
      chargerId,
      uid, // This needs to be passed to the function or generated/defined within it
      transactionId,
      meterValue,
      beginMeterValue,
      startTime,
      status,
      numberOfCharge,
      numberOfChargeDays
    ]);
  }

  /// delete a groups
  Future<void> deleteNotificationLog(int id) async {
    Database db = await instance.database;
    // Proceed with the delete operation since the database is available
    await db
        .delete('notification_log', where: 'charger_id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getNotificationLog(String chargerId) async {
    // Get a reference to the database.
    // print(chargerId);
    final Database db = await DatabaseHelper.instance.database;

    // Query the database for a single row where the charger_id matches the provided chargerId.
    List<Map<String, dynamic>> maps = await db.query(
      'notification_log', // Name of the table you want to query
      where: 'charger_id = ?', // SQL 'where' clause to filter results
      whereArgs: [chargerId], // Arguments to replace '?' in where clause
    );

    // Check if the result is not empty and then use the first item.
    if (maps.isNotEmpty) {
      // Return the first map from the result as it matches the chargerId.
      return maps.first;
    } else {
      // Return null if no matching record is found.
      return null;
    }
  }

  ///.......................Active session.....................
  Future<void> insertOrUpdateActiveSession({
    required int chargerId,
    required int cardId,
    required int transactionStartTime,
    required String kwh,
    required String sessionTime,
  }) async {
    final Database db = await DatabaseHelper.instance.database;

    await db.execute('''
    INSERT OR REPLACE INTO active_session (
      charger_id, 
      card_id, 
      transaction_start_time, 
      kwh, 
      session_time
    ) VALUES (?, ?, ?, ?, ?)
  ''', [
      chargerId,
      cardId,
      transactionStartTime,
      kwh,
      sessionTime,
    ]);
  }

  Future<void> deleteActiveSessionByChargerId(int chargerId) async {
    // print("chargerId: $chargerId deleted");
    final Database db = await DatabaseHelper.instance.database;

    await db.execute('''
    DELETE FROM active_session WHERE charger_id = ?
  ''', [chargerId]);
  }

  ///.....................Active session....................

  ///.......................smtp........................
  Future<void> insertOrReplaceEmail(SmtpViewModel smtpViewModel) async {
    final Database db = await DatabaseHelper.instance.database;

    await db.execute('''
      REPLACE INTO smtp (id, email, password)
      VALUES (1, ?, ?)
  ''', [smtpViewModel.email, smtpViewModel.password]);
  }

  Future<SmtpViewModel> getSmtpEmail() async {
    final Database db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> results =
        await db.query('smtp', where: 'id = ?', whereArgs: [1], limit: 1);

    if (results.isNotEmpty) {
      return SmtpViewModel.fromJson(results[0]);
    } else {
      throw Exception('No SMTP settings found.');
    }
  }

  ///....................smtp......................

  ///......................time_format....................
  Future<void> insertOrReplaceTimeFormat(String utcTime) async {
    if (utcTime == 'NL') {
      int currentMonth = DateTime.now().month;
      if (currentMonth >= 3 && currentMonth < 10) {
        utcTime = 'UTC+02:00';
      } else if (currentMonth >= 10 || currentMonth < 3) {
        utcTime = 'UTC+01:00';
      }
    }
    final Database db = await DatabaseHelper.instance.database;
    await db.execute('''
      REPLACE INTO time_format (id, utc_time)
      VALUES (1, ?)
  ''', [utcTime]);
  }

  Future<String> getUtcTime() async {
    final Database db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> results = await db.query('time_format',
        where: 'id = ?', whereArgs: [1], limit: 1);

    if (results.isNotEmpty && results[0]['utc_time'] != "null") {
      return results[0]['utc_time'];
    } else {
      DateTime deviceTime = DateTime.now();
      return getTimeZoneOffset(deviceTime);
    }
  }

  String getTimeZoneOffset(DateTime dateTime) {
    // Get the time zone offset
    Duration offset = dateTime.timeZoneOffset;

    // Format the offset in the format "UTC±HH:mm"
    String sign = offset.isNegative ? '-' : '+';
    String hours = offset.inHours.abs().toString().padLeft(2, '0');
    String minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

    return 'UTC$sign$hours:$minutes';
  }

  ///.......................receiver email........................
  Future<void> insertOrReplaceReceiverEmail(SmtpViewModel smtpViewModel) async {
    final Database db = await DatabaseHelper.instance.database;

    await db.execute('''
      REPLACE INTO receiver_email (id, email)
      VALUES (1, ?)
  ''', [smtpViewModel.email]);
  }

  Future<String> getReceiverEmail() async {
    final Database db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> results = await db.query('receiver_email',
        where: 'id = ?', whereArgs: [1], limit: 1);

    if (results.isNotEmpty) {
      return results[0]['email'];
    } else {
      throw Exception('No SMTP settings found.');
    }
  }

  ///....................receiver email......................

  /// Retrieve all sessions
  Future<List<Map<String, dynamic>>> getSessions() async {
    Database db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT *
      FROM active_session
      JOIN cards ON active_session.card_id = cards.id
      JOIN chargers ON active_session.charger_id = chargers.id
    ''');
  }

  /// delete a groups
  Future<void> deleteSession(int id) async {
    Database db = await instance.database;
    // Proceed with the delete operation since the database is available
    await db.delete('active_session', where: 'charger_id = ?', whereArgs: [id]);
  }
}
