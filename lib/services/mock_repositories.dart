import 'package:railone/models/food.dart';
import 'package:railone/models/grievance.dart';
import 'package:railone/models/pnr.dart';
import 'package:railone/models/refund.dart';
import 'package:railone/models/train.dart';
import 'package:railone/services/json_service.dart';

class TrainRepository {
  Future<List<Train>> getTrains() async {
    final list = await JsonService.loadJsonList('assets/data/trains.json');
    return list.map((e) => Train.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}

class PnrRepository {
  Future<PnrRecord?> getByPnr(String pnr) async {
    final list = await JsonService.loadJsonList('assets/data/pnr.json');
    final records = list
        .map((e) => PnrRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    try {
      return records.firstWhere((r) => r.pnr == pnr);
    } catch (_) {
      return null;
    }
  }
}

class FoodRepository {
  Future<List<FoodVendor>> getVendors() async {
    final list = await JsonService.loadJsonList('assets/data/food.json');
    return list
        .map((e) => FoodVendor.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class RefundRepository {
  Future<List<RefundRequest>> getRefunds() async {
    final list = await JsonService.loadJsonList('assets/data/refunds.json');
    return list
        .map((e) => RefundRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class GrievanceRepository {
  Future<List<Grievance>> getGrievances() async {
    final list = await JsonService.loadJsonList('assets/data/grievances.json');
    return list
        .map((e) => Grievance.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

