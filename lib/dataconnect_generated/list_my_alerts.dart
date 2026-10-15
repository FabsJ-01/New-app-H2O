part of 'generated.dart';

class ListMyAlertsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMyAlertsVariablesBuilder(this._dataConnect, );
  Deserializer<ListMyAlertsData> dataDeserializer = (dynamic json)  => ListMyAlertsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMyAlertsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListMyAlertsData, void> ref() {
    
    return _dataConnect.query("ListMyAlerts", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMyAlertsAlerts {
  final String severity;
  final String type;
  final String status;
  ListMyAlertsAlerts.fromJson(dynamic json):
  
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

    final ListMyAlertsAlerts otherTyped = other as ListMyAlertsAlerts;
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

  ListMyAlertsAlerts({
    required this.severity,
    required this.type,
    required this.status,
  });
}

@immutable
class ListMyAlertsData {
  final List<ListMyAlertsAlerts> alerts;
  ListMyAlertsData.fromJson(dynamic json):
  
  alerts = (json['alerts'] as List<dynamic>)
        .map((e) => ListMyAlertsAlerts.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyAlertsData otherTyped = other as ListMyAlertsData;
    return alerts == otherTyped.alerts;
    
  }
  @override
  int get hashCode => alerts.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['alerts'] = alerts.map((e) => e.toJson()).toList();
    return json;
  }

  ListMyAlertsData({
    required this.alerts,
  });
}

