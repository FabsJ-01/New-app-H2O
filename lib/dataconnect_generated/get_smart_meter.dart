part of 'generated.dart';

class GetSmartMeterVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetSmartMeterVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetSmartMeterData> dataDeserializer = (dynamic json)  => GetSmartMeterData.fromJson(jsonDecode(json));
  Serializer<GetSmartMeterVariables> varsSerializer = (GetSmartMeterVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetSmartMeterData, GetSmartMeterVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetSmartMeterData, GetSmartMeterVariables> ref() {
    GetSmartMeterVariables vars= GetSmartMeterVariables(id: id,);
    return _dataConnect.query("GetSmartMeter", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetSmartMeterSmartMeter {
  final String serialNumber;
  final double currentReading;
  final GetSmartMeterSmartMeterFacility? facility;
  GetSmartMeterSmartMeter.fromJson(dynamic json):
  
  serialNumber = nativeFromJson<String>(json['serialNumber']),
  currentReading = nativeFromJson<double>(json['currentReading']),
  facility = json['facility'] == null ? null : GetSmartMeterSmartMeterFacility.fromJson(json['facility']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSmartMeterSmartMeter otherTyped = other as GetSmartMeterSmartMeter;
    return serialNumber == otherTyped.serialNumber && 
    currentReading == otherTyped.currentReading && 
    facility == otherTyped.facility;
    
  }
  @override
  int get hashCode => Object.hashAll([serialNumber.hashCode, currentReading.hashCode, facility.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['serialNumber'] = nativeToJson<String>(serialNumber);
    json['currentReading'] = nativeToJson<double>(currentReading);
    if (facility != null) {
      json['facility'] = facility!.toJson();
    }
    return json;
  }

  GetSmartMeterSmartMeter({
    required this.serialNumber,
    required this.currentReading,
    this.facility,
  });
}

@immutable
class GetSmartMeterSmartMeterFacility {
  final String name;
  GetSmartMeterSmartMeterFacility.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSmartMeterSmartMeterFacility otherTyped = other as GetSmartMeterSmartMeterFacility;
    return name == otherTyped.name;
    
  }
  @override
  int get hashCode => name.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    return json;
  }

  GetSmartMeterSmartMeterFacility({
    required this.name,
  });
}

@immutable
class GetSmartMeterData {
  final GetSmartMeterSmartMeter? smartMeter;
  GetSmartMeterData.fromJson(dynamic json):
  
  smartMeter = json['smartMeter'] == null ? null : GetSmartMeterSmartMeter.fromJson(json['smartMeter']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSmartMeterData otherTyped = other as GetSmartMeterData;
    return smartMeter == otherTyped.smartMeter;
    
  }
  @override
  int get hashCode => smartMeter.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (smartMeter != null) {
      json['smartMeter'] = smartMeter!.toJson();
    }
    return json;
  }

  GetSmartMeterData({
    this.smartMeter,
  });
}

@immutable
class GetSmartMeterVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetSmartMeterVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSmartMeterVariables otherTyped = other as GetSmartMeterVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetSmartMeterVariables({
    required this.id,
  });
}

