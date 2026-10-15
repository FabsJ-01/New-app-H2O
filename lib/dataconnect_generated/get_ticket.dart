part of 'generated.dart';

class GetTicketVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  GetTicketVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<GetTicketData> dataDeserializer = (dynamic json)  => GetTicketData.fromJson(jsonDecode(json));
  Serializer<GetTicketVariables> varsSerializer = (GetTicketVariables vars) => jsonEncode(vars.toJson());
  Future<QueryResult<GetTicketData, GetTicketVariables>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetTicketData, GetTicketVariables> ref() {
    GetTicketVariables vars= GetTicketVariables(id: id,);
    return _dataConnect.query("GetTicket", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class GetTicketMaintenanceTicket {
  final String title;
  final String status;
  final String? technicianNotes;
  GetTicketMaintenanceTicket.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']),
  status = nativeFromJson<String>(json['status']),
  technicianNotes = json['technicianNotes'] == null ? null : nativeFromJson<String>(json['technicianNotes']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTicketMaintenanceTicket otherTyped = other as GetTicketMaintenanceTicket;
    return title == otherTyped.title && 
    status == otherTyped.status && 
    technicianNotes == otherTyped.technicianNotes;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, status.hashCode, technicianNotes.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['status'] = nativeToJson<String>(status);
    if (technicianNotes != null) {
      json['technicianNotes'] = nativeToJson<String?>(technicianNotes);
    }
    return json;
  }

  GetTicketMaintenanceTicket({
    required this.title,
    required this.status,
    this.technicianNotes,
  });
}

@immutable
class GetTicketData {
  final GetTicketMaintenanceTicket? maintenanceTicket;
  GetTicketData.fromJson(dynamic json):
  
  maintenanceTicket = json['maintenanceTicket'] == null ? null : GetTicketMaintenanceTicket.fromJson(json['maintenanceTicket']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTicketData otherTyped = other as GetTicketData;
    return maintenanceTicket == otherTyped.maintenanceTicket;
    
  }
  @override
  int get hashCode => maintenanceTicket.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (maintenanceTicket != null) {
      json['maintenanceTicket'] = maintenanceTicket!.toJson();
    }
    return json;
  }

  GetTicketData({
    this.maintenanceTicket,
  });
}

@immutable
class GetTicketVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  GetTicketVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetTicketVariables otherTyped = other as GetTicketVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  GetTicketVariables({
    required this.id,
  });
}

