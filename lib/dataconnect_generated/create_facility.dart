part of 'generated.dart';

class CreateFacilityVariablesBuilder {
  String name;
  String coords;
  String status;

  final FirebaseDataConnect _dataConnect;
  CreateFacilityVariablesBuilder(this._dataConnect, {required  this.name,required  this.coords,required  this.status,});
  Deserializer<CreateFacilityData> dataDeserializer = (dynamic json)  => CreateFacilityData.fromJson(jsonDecode(json));
  Serializer<CreateFacilityVariables> varsSerializer = (CreateFacilityVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateFacilityData, CreateFacilityVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateFacilityData, CreateFacilityVariables> ref() {
    CreateFacilityVariables vars= CreateFacilityVariables(name: name,coords: coords,status: status,);
    return _dataConnect.mutation("CreateFacility", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateFacilityFacilityInsert {
  final String id;
  CreateFacilityFacilityInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFacilityFacilityInsert otherTyped = other as CreateFacilityFacilityInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateFacilityFacilityInsert({
    required this.id,
  });
}

@immutable
class CreateFacilityData {
  final CreateFacilityFacilityInsert facility_insert;
  CreateFacilityData.fromJson(dynamic json):
  
  facility_insert = CreateFacilityFacilityInsert.fromJson(json['facility_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFacilityData otherTyped = other as CreateFacilityData;
    return facility_insert == otherTyped.facility_insert;
    
  }
  @override
  int get hashCode => facility_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['facility_insert'] = facility_insert.toJson();
    return json;
  }

  CreateFacilityData({
    required this.facility_insert,
  });
}

@immutable
class CreateFacilityVariables {
  final String name;
  final String coords;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateFacilityVariables.fromJson(Map<String, dynamic> json):
  
  name = nativeFromJson<String>(json['name']),
  coords = nativeFromJson<String>(json['coords']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateFacilityVariables otherTyped = other as CreateFacilityVariables;
    return name == otherTyped.name && 
    coords == otherTyped.coords && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, coords.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['coords'] = nativeToJson<String>(coords);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  CreateFacilityVariables({
    required this.name,
    required this.coords,
    required this.status,
  });
}

