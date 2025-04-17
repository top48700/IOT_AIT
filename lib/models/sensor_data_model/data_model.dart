class DataModel {
  final String? sensorId;
  final double? accumulatedEnergyValue;
  final double? powerConsumptionValue;
  final double? powerFactorValue;
  final String? measuredAt;
  Map<String, dynamic>? branchInfo;
  final String? branchId;
  final String? tenantId;
  final String? gatewayId;
  final String? name;
  final String? iox_day;
  final String? time;
  final String? iox_month;
  final String? iox_week;
  final String? iox_weekday;
  final String? iox_year; 
  final double? mvalue;  
  final double? reactivePowerValue; 

  DataModel({
    this.sensorId,
    this.accumulatedEnergyValue,
    this.powerConsumptionValue,
    this.powerFactorValue,
    this.measuredAt,
    this.branchInfo,
    this.branchId,
    this.tenantId,
    this.gatewayId,
    this.name,
    this.iox_day,
    this.time,
    this.iox_month,
    this.iox_week,
    this.iox_weekday,
    this.iox_year,
    this.mvalue,
    this.reactivePowerValue,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      sensorId: json['sensorId'] as String?,
      accumulatedEnergyValue: (json['accumulatedEnergyValue'] as num?)?.toDouble(),
      powerConsumptionValue: (json['powerConsumptionValue'] as num?)?.toDouble(),
      powerFactorValue: (json['powerFactorValue'] as num?)?.toDouble(),
      measuredAt: json['measuredAt'] as String?,
      branchInfo: json['branchInfo'] != null ? json['branchInfo'] as Map<String, dynamic> : null,
      branchId: json['branchId'],
      tenantId: json['tenantId'],                                              
      gatewayId: json['gatewayId'],
      name: json['name'],
      iox_day: json['iox_day'],
      time: json['time'],
      iox_month: json['iox_month'],
      iox_week: json['iox_week'],
      iox_weekday: json['iox_weekday'],
      iox_year: json['iox_year'],
      mvalue: (json['mvalue'] as num?)?.toDouble(),
      reactivePowerValue: (json['reactivePowerValue'] as num?)?.toDouble(),
    );
  }
}
