part of 'generated.dart';

class DeleteAlertVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteAlertVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteAlertData> dataDeserializer = (dynamic json)  => DeleteAlertData.fromJson(jsonDecode(json));
  Serializer<DeleteAlertVariables> varsSerializer = (DeleteAlertVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteAlertData, DeleteAlertVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteAlertData, DeleteAlertVariables> ref() {
    DeleteAlertVariables vars= DeleteAlertVariables(id: id,);
    return _dataConnect.mutation("DeleteAlert", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteAlertAlertDelete {
  final String id;
  DeleteAlertAlertDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAlertAlertDelete otherTyped = other as DeleteAlertAlertDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteAlertAlertDelete({
    required this.id,
  });
}

@immutable
class DeleteAlertData {
  final DeleteAlertAlertDelete? alert_delete;
  DeleteAlertData.fromJson(dynamic json):
  
  alert_delete = json['alert_delete'] == null ? null : DeleteAlertAlertDelete.fromJson(json['alert_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAlertData otherTyped = other as DeleteAlertData;
    return alert_delete == otherTyped.alert_delete;
    
  }
  @override
  int get hashCode => alert_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (alert_delete != null) {
      json['alert_delete'] = alert_delete!.toJson();
    }
    return json;
  }

  DeleteAlertData({
    this.alert_delete,
  });
}

@immutable
class DeleteAlertVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteAlertVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteAlertVariables otherTyped = other as DeleteAlertVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteAlertVariables({
    required this.id,
  });
}

