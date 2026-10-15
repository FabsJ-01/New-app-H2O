part of 'generated.dart';

class ListFacilitiesVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListFacilitiesVariablesBuilder(this._dataConnect, );
  Deserializer<ListFacilitiesData> dataDeserializer = (dynamic json)  => ListFacilitiesData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListFacilitiesData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListFacilitiesData, void> ref() {
    
    return _dataConnect.query("ListFacilities", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListFacilitiesFacilities {
  final String name;
  final String status;
  ListFacilitiesFacilities.fromJson(dynamic json):
  
  name = nativeFromJson<String>(json['name']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListFacilitiesFacilities otherTyped = other as ListFacilitiesFacilities;
    return name == otherTyped.name && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([name.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['name'] = nativeToJson<String>(name);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  ListFacilitiesFacilities({
    required this.name,
    required this.status,
  });
}

@immutable
class ListFacilitiesData {
  final List<ListFacilitiesFacilities> facilities;
  ListFacilitiesData.fromJson(dynamic json):
  
  facilities = (json['facilities'] as List<dynamic>)
        .map((e) => ListFacilitiesFacilities.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListFacilitiesData otherTyped = other as ListFacilitiesData;
    return facilities == otherTyped.facilities;
    
  }
  @override
  int get hashCode => facilities.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['facilities'] = facilities.map((e) => e.toJson()).toList();
    return json;
  }

  ListFacilitiesData({
    required this.facilities,
  });
}

