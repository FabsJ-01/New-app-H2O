part of 'generated.dart';

class ListSmartMetersVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListSmartMetersVariablesBuilder(this._dataConnect, );
  Deserializer<ListSmartMetersData> dataDeserializer = (dynamic json)  => ListSmartMetersData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListSmartMetersData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListSmartMetersData, void> ref() {
    
    return _dataConnect.query("ListSmartMeters", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListSmartMetersSmartMeters {
  final String serialNumber;
  final String status;
  ListSmartMetersSmartMeters.fromJson(dynamic json):
  
  serialNumber = nativeFromJson<String>(json['serialNumber']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSmartMetersSmartMeters otherTyped = other as ListSmartMetersSmartMeters;
    return serialNumber == otherTyped.serialNumber && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([serialNumber.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['serialNumber'] = nativeToJson<String>(serialNumber);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  ListSmartMetersSmartMeters({
    required this.serialNumber,
    required this.status,
  });
}

@immutable
class ListSmartMetersData {
  final List<ListSmartMetersSmartMeters> smartMeters;
  ListSmartMetersData.fromJson(dynamic json):
  
  smartMeters = (json['smartMeters'] as List<dynamic>)
        .map((e) => ListSmartMetersSmartMeters.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSmartMetersData otherTyped = other as ListSmartMetersData;
    return smartMeters == otherTyped.smartMeters;
    
  }
  @override
  int get hashCode => smartMeters.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['smartMeters'] = smartMeters.map((e) => e.toJson()).toList();
    return json;
  }

  ListSmartMetersData({
    required this.smartMeters,
  });
}

