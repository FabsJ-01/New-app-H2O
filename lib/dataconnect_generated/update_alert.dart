part of 'generated.dart';

class UpdateAlertVariablesBuilder {
  String id;
  String status;

  final FirebaseDataConnect _dataConnect;
  UpdateAlertVariablesBuilder(this._dataConnect, {required  this.id,required  this.status,});
  Deserializer<UpdateAlertData> dataDeserializer = (dynamic json)  => UpdateAlertData.fromJson(jsonDecode(json));
  Serializer<UpdateAlertVariables> varsSerializer = (UpdateAlertVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateAlertData, UpdateAlertVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateAlertData, UpdateAlertVariables> ref() {
    UpdateAlertVariables vars= UpdateAlertVariables(id: id,status: status,);
    return _dataConnect.mutation("UpdateAlert", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateAlertAlertUpdate {
  final String id;
  UpdateAlertAlertUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateAlertAlertUpdate otherTyped = other as UpdateAlertAlertUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateAlertAlertUpdate({
    required this.id,
  });
}

@immutable
class UpdateAlertData {
  final UpdateAlertAlertUpdate? alert_update;
  UpdateAlertData.fromJson(dynamic json):
  
  alert_update = json['alert_update'] == null ? null : UpdateAlertAlertUpdate.fromJson(json['alert_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateAlertData otherTyped = other as UpdateAlertData;
    return alert_update == otherTyped.alert_update;
    
  }
  @override
  int get hashCode => alert_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (alert_update != null) {
      json['alert_update'] = alert_update!.toJson();
    }
    return json;
  }

  UpdateAlertData({
    this.alert_update,
  });
}

@immutable
class UpdateAlertVariables {
  final String id;
  final String status;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateAlertVariables.fromJson(Map<String, dynamic> json):
  
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

    final UpdateAlertVariables otherTyped = other as UpdateAlertVariables;
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

  UpdateAlertVariables({
    required this.id,
    required this.status,
  });
}

