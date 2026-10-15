part of 'generated.dart';

class UpdateFacilityVariablesBuilder {
  String id;
  String status;

  final FirebaseDataConnect _dataConnect;
  UpdateFacilityVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,});
  Deserializer<UpdateFacilityData> dataDeserializer = (dynamic json)  => UpdateFacilityData.fromJson(jsonDecode(json));
  Serializer<UpdateFacilityVariables> varsSerializer = (UpdateFacilityVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateFacilityData, UpdateFacilityVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateFacilityData, UpdateFacilityVariables> ref() {
    UpdateFacilityVariables vars= UpdateFacilityVariables(id: id,status: status,);
    return _dataConnect.mutation("UpdateFacility", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateFacilityFacilityUpdate {
  final String id;
  UpdateFacilityFacilityUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateFacilityFacilityUpdate otherTyped = other as UpdateFacilityFacilityUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateFacilityFacilityUpdate({
    required this.id,
  });
}

@immutable
class UpdateFacilityData {
  final UpdateFacilityFacilityUpdate? facility_update;
  UpdateFacilityData.fromJson(dynamic json):
  
  facility_update = json['facility_update'] == null ? null : UpdateFacilityFacilityUpdate.fromJson(json['facility_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateFacilityData otherTyped = other as UpdateFacilityData;
    return facility_update == otherTyped.facility_update;
    
  }
  @override
  int get hashCode => facility_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (facility_update != null) {
      json['facility_update'] = facility_update!.toJson();
    }
    return json;
  }

  UpdateFacilityData({
    this.facility_update,
  });
}

@immutable
class UpdateFacilityVariables {
  final String id;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateFacilityVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateFacilityVariables otherTyped = other as UpdateFacilityVariables;
    return id == otherTyped.id && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  UpdateFacilityVariables({
    required this.id,
    required this.status,
  });
}

