part of 'generated.dart';

class DeleteFacilityVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteFacilityVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteFacilityData> dataDeserializer = (dynamic json)  => DeleteFacilityData.fromJson(jsonDecode(json));
  Serializer<DeleteFacilityVariables> varsSerializer = (DeleteFacilityVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteFacilityData, DeleteFacilityVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteFacilityData, DeleteFacilityVariables> ref() {
    DeleteFacilityVariables vars= DeleteFacilityVariables(id: id,);
    return _dataConnect.mutation("DeleteFacility", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteFacilityFacilityDelete {
  final String id;
  DeleteFacilityFacilityDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteFacilityFacilityDelete otherTyped = other as DeleteFacilityFacilityDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteFacilityFacilityDelete({
    required this.id,
  });
}

@immutable
class DeleteFacilityData {
  final DeleteFacilityFacilityDelete? facility_delete;
  DeleteFacilityData.fromJson(dynamic json):
  
  facility_delete = json['facility_delete'] == null ? null : DeleteFacilityFacilityDelete.fromJson(json['facility_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteFacilityData otherTyped = other as DeleteFacilityData;
    return facility_delete == otherTyped.facility_delete;
    
  }
  @override
  int get hashCode => facility_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (facility_delete != null) {
      json['facility_delete'] = facility_delete!.toJson();
    }
    return json;
  }

  DeleteFacilityData({
    this.facility_delete,
  });
}

@immutable
class DeleteFacilityVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteFacilityVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteFacilityVariables otherTyped = other as DeleteFacilityVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteFacilityVariables({
    required this.id,
  });
}

