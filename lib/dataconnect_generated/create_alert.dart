part of 'generated.dart';

class CreateAlertVariablesBuilder {
  String severity;
  String type;
  String meterId;

  final FirebaseDataConnect _dataConnect;
  CreateAlertVariablesBuilder(this._dataConnect, {required  this.severity,required  this.type,required  this.meterId,});
  Deserializer<CreateAlertData> dataDeserializer = (dynamic json)  => CreateAlertData.fromJson(jsonDecode(json));
  Serializer<CreateAlertVariables> varsSerializer = (CreateAlertVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateAlertData, CreateAlertVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateAlertData, CreateAlertVariables> ref() {
    CreateAlertVariables vars= CreateAlertVariables(severity: severity,type: type,meterId: meterId,);
    return _dataConnect.mutation("CreateAlert", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateAlertAlertInsert {
  final String id;
  CreateAlertAlertInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateAlertAlertInsert otherTyped = other as CreateAlertAlertInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateAlertAlertInsert({
    required this.id,
  });
}

@immutable
class CreateAlertData {
  final CreateAlertAlertInsert alert_insert;
  CreateAlertData.fromJson(dynamic json):
  
  alert_insert = CreateAlertAlertInsert.fromJson(json['alert_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateAlertData otherTyped = other as CreateAlertData;
    return alert_insert == otherTyped.alert_insert;
    
  }
  @override
  int get hashCode => alert_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['alert_insert'] = alert_insert.toJson();
    return json;
  }

  CreateAlertData({
    required this.alert_insert,
  });
}

@immutable
class CreateAlertVariables {
  final String severity;
  final String type;
  final String meterId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateAlertVariables.fromJson(Map<String, dynamic> json):
  
  severity = nativeFromJson<String>(json['severity']),
  type = nativeFromJson<String>(json['type']),
  meterId = nativeFromJson<String>(json['meterId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateAlertVariables otherTyped = other as CreateAlertVariables;
    return severity == otherTyped.severity && 
    type == otherTyped.type && 
    meterId == otherTyped.meterId;
    
  }
  @override
  int get hashCode => Object.hashAll([severity.hashCode, type.hashCode, meterId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['severity'] = nativeToJson<String>(severity);
    json['type'] = nativeToJson<String>(type);
    json['meterId'] = nativeToJson<String>(meterId);
    return json;
  }

  CreateAlertVariables({
    required this.severity,
    required this.type,
    required this.meterId,
  });
}

