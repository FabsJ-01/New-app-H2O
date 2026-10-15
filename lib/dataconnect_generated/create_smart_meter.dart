part of 'generated.dart';

class CreateSmartMeterVariablesBuilder {
  String serial;
  double reading;
  String facilityId;

  final FirebaseDataConnect _dataConnect;
  CreateSmartMeterVariablesBuilder(this._dataConnect, {required  this.serial,required  this.reading,required  this.facilityId,});
  Deserializer<CreateSmartMeterData> dataDeserializer = (dynamic json)  => CreateSmartMeterData.fromJson(jsonDecode(json));
  Serializer<CreateSmartMeterVariables> varsSerializer = (CreateSmartMeterVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateSmartMeterData, CreateSmartMeterVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateSmartMeterData, CreateSmartMeterVariables> ref() {
    CreateSmartMeterVariables vars= CreateSmartMeterVariables(serial: serial,reading: reading,facilityId: facilityId,);
    return _dataConnect.mutation("CreateSmartMeter", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateSmartMeterSmartMeterInsert {
  final String id;
  CreateSmartMeterSmartMeterInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSmartMeterSmartMeterInsert otherTyped = other as CreateSmartMeterSmartMeterInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateSmartMeterSmartMeterInsert({
    required this.id,
  });
}

@immutable
class CreateSmartMeterData {
  final CreateSmartMeterSmartMeterInsert smartMeter_insert;
  CreateSmartMeterData.fromJson(dynamic json):
  
  smartMeter_insert = CreateSmartMeterSmartMeterInsert.fromJson(json['smartMeter_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSmartMeterData otherTyped = other as CreateSmartMeterData;
    return smartMeter_insert == otherTyped.smartMeter_insert;
    
  }
  @override
  int get hashCode => smartMeter_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['smartMeter_insert'] = smartMeter_insert.toJson();
    return json;
  }

  CreateSmartMeterData({
    required this.smartMeter_insert,
  });
}

@immutable
class CreateSmartMeterVariables {
  final String serial;
  final double reading;
  final String facilityId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateSmartMeterVariables.fromJson(Map<String, dynamic> json):
  
  serial = nativeFromJson<String>(json['serial']),
  reading = nativeFromJson<double>(json['reading']),
  facilityId = nativeFromJson<String>(json['facilityId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSmartMeterVariables otherTyped = other as CreateSmartMeterVariables;
    return serial == otherTyped.serial && 
    reading == otherTyped.reading && 
    facilityId == otherTyped.facilityId;
    
  }
  @override
  int get hashCode => Object.hashAll([serial.hashCode, reading.hashCode, facilityId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['serial'] = nativeToJson<String>(serial);
    json['reading'] = nativeToJson<double>(reading);
    json['facilityId'] = nativeToJson<String>(facilityId);
    return json;
  }

  CreateSmartMeterVariables({
    required this.serial,
    required this.reading,
    required this.facilityId,
  });
}

