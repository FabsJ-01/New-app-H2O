part of 'generated.dart';

class GetAlertVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetAlertVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetAlertData> dataDeserializer = (dynamic json)  => GetAlertData.fromJson(jsonDecode(json));
  Serializer<GetAlertVariables> varsSerializer = (GetAlertVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetAlertData, GetAlertVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAlertData, GetAlertVariables> ref() {
    GetAlertVariables vars= GetAlertVariables(id: id,);
    return _dataConnect.query("GetAlert", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetAlertAlert {
  final String severity;
  final String type;
  final String status;
  GetAlertAlert.fromJson(dynamic json):
  
  severity = nativeFromJson<String>(json['severity']),
  type = nativeFromJson<String>(json['type']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAlertAlert otherTyped = other as GetAlertAlert;
    return severity == otherTyped.severity && 
    type == otherTyped.type && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([severity.hashCode, type.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['severity'] = nativeToJson<String>(severity);
    json['type'] = nativeToJson<String>(type);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  GetAlertAlert({
    required this.severity,
    required this.type,
    required this.status,
  });
}

@immutable
class GetAlertData {
  final GetAlertAlert? alert;
  GetAlertData.fromJson(dynamic json):
  
  alert = json['alert'] == null ? null : GetAlertAlert.fromJson(json['alert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAlertData otherTyped = other as GetAlertData;
    return alert == otherTyped.alert;
    
  }
  @override
  int get hashCode => alert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (alert != null) {
      json['alert'] = alert!.toJson();
    }
    return json;
  }

  GetAlertData({
    this.alert,
  });
}

@immutable
class GetAlertVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetAlertVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAlertVariables otherTyped = other as GetAlertVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetAlertVariables({
    required this.id,
  });
}

