part of 'generated.dart';

class GetFacilityVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetFacilityVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetFacilityData> dataDeserializer = (dynamic json)  => GetFacilityData.fromJson(jsonDecode(json));
  Serializer<GetFacilityVariables> varsSerializer = (GetFacilityVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetFacilityData, GetFacilityVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetFacilityData, GetFacilityVariables> ref() {
    GetFacilityVariables vars= GetFacilityVariables(id: id,);
    return _dataConnect.query("GetFacility", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetFacilityFacility {
  final String name;
  final String status;
  final String locationCoordinates;
  GetFacilityFacility.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  status = nativeFromJson<String>(json['status']),
  locationCoordinates = nativeFromJson<String>(json['locationCoordinates']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFacilityFacility otherTyped = other as GetFacilityFacility;
    return name == otherTyped.name && 
    status == otherTyped.status && 
    locationCoordinates == otherTyped.locationCoordinates;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, status.hashCode, locationCoordinates.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['status'] = nativeToJson<String>(status);
    json['locationCoordinates'] = nativeToJson<String>(locationCoordinates);
    return json;
  }

  GetFacilityFacility({
    required this.name,
    required this.status,
    required this.locationCoordinates,
  });
}

@immutable
class GetFacilityData {
  final GetFacilityFacility? facility;
  GetFacilityData.fromJson(dynamic json):
  
  facility = json['facility'] == null ? null : GetFacilityFacility.fromJson(json['facility']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFacilityData otherTyped = other as GetFacilityData;
    return facility == otherTyped.facility;
    
  }
  @override
  int get hashCode => facility.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (facility != null) {
      json['facility'] = facility!.toJson();
    }
    return json;
  }

  GetFacilityData({
    this.facility,
  });
}

@immutable
class GetFacilityVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetFacilityVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetFacilityVariables otherTyped = other as GetFacilityVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetFacilityVariables({
    required this.id,
  });
}

