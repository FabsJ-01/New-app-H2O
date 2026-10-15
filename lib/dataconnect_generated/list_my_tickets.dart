part of 'generated.dart';

class ListMyTicketsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListMyTicketsVariablesBuilder(this._dataConnect, );
  Deserializer<ListMyTicketsData> dataDeserializer = (dynamic json)  => ListMyTicketsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListMyTicketsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListMyTicketsData, void> ref() {
    
    return _dataConnect.query("ListMyTickets", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListMyTicketsMaintenanceTickets {
  final String title;
  final String status;
  ListMyTicketsMaintenanceTickets.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  status = nativeFromJson<String>(json['status']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyTicketsMaintenanceTickets otherTyped = other as ListMyTicketsMaintenanceTickets;
    return title == otherTyped.title && 
    status == otherTyped.status;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, status.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['status'] = nativeToJson<String>(status);
    return json;
  }

  ListMyTicketsMaintenanceTickets({
    required this.title,
    required this.status,
  });
}

@immutable
class ListMyTicketsData {
  final List<ListMyTicketsMaintenanceTickets> maintenanceTickets;
  ListMyTicketsData.fromJson(dynamic json):
  
  maintenanceTickets = (json['maintenanceTickets'] as List<dynamic>)
        .map((e) => ListMyTicketsMaintenanceTickets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListMyTicketsData otherTyped = other as ListMyTicketsData;
    return maintenanceTickets == otherTyped.maintenanceTickets;
    
  }
  @override
  int get hashCode => maintenanceTickets.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['maintenanceTickets'] = maintenanceTickets.map((e) => e.toJson()).toList();
    return json;
  }

  ListMyTicketsData({
    required this.maintenanceTickets,
  });
}

