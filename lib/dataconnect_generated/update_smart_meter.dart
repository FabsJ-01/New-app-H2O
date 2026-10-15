part of 'generated.dart';

class UpdateSmartMeterVariablesBuilder {
  String id;
  double reading;

  final FirebaseDataConnect _dataConnect;
  UpdateSmartMeterVariablesBuilder(this._dataConnect, {required  this.id,required  this.reading,});
  Deserializer<UpdateSmartMeterData> dataDeserializer = (dynamic json)  => UpdateSmartMeterData.fromJson(jsonDecode(json));
  Serializer<UpdateSmartMeterVariables> varsSerializer = (UpdateSmartMeterVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateSmartMeterData, UpdateSmartMeterVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateSmartMeterData, UpdateSmartMeterVariables> ref() {
    UpdateSmartMeterVariables vars= UpdateSmartMeterVariables(id: id,reading: reading,);
    return _dataConnect.mutation("UpdateSmartMeter", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateSmartMeterSmartMeterUpdate {
  final String id;
  UpdateSmartMeterSmartMeterUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSmartMeterSmartMeterUpdate otherTyped = other as UpdateSmartMeterSmartMeterUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateSmartMeterSmartMeterUpdate({
    required this.id,
  });
}

@immutable
class UpdateSmartMeterData {
  final UpdateSmartMeterSmartMeterUpdate? smartMeter_update;
  UpdateSmartMeterData.fromJson(dynamic json):
  
  smartMeter_update = json['smartMeter_update'] == null ? null : UpdateSmartMeterSmartMeterUpdate.fromJson(json['smartMeter_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSmartMeterData otherTyped = other as UpdateSmartMeterData;
    return smartMeter_update == otherTyped.smartMeter_update;
    
  }
  @override
  int get hashCode => smartMeter_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (smartMeter_update != null) {
      json['smartMeter_update'] = smartMeter_update!.toJson();
    }
    return json;
  }

  UpdateSmartMeterData({
    this.smartMeter_update,
  });
}

@immutable
class UpdateSmartMeterVariables {
  final String id;
  final double reading;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateSmartMeterVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  reading = nativeFromJson<double>(json['reading']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSmartMeterVariables otherTyped = other as UpdateSmartMeterVariables;
    return id == otherTyped.id && 
    reading == otherTyped.reading;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, reading.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['reading'] = nativeToJson<double>(reading);
    return json;
  }

  UpdateSmartMeterVariables({
    required this.id,
    required this.reading,
  });
}

