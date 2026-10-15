part of 'generated.dart';

class CreateTicketVariablesBuilder {
  String title;
  String alertId;

  final FirebaseDataConnect _dataConnect;
  CreateTicketVariablesBuilder(this._dataConnect, {required  this.title,required  this.alertId,});
  Deserializer<CreateTicketData> dataDeserializer = (dynamic json)  => CreateTicketData.fromJson(jsonDecode(json));
  Serializer<CreateTicketVariables> varsSerializer = (CreateTicketVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateTicketData, CreateTicketVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateTicketData, CreateTicketVariables> ref() {
    CreateTicketVariables vars= CreateTicketVariables(title: title,alertId: alertId,);
    return _dataConnect.mutation("CreateTicket", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateTicketMaintenanceTicketInsert {
  final String id;
  CreateTicketMaintenanceTicketInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTicketMaintenanceTicketInsert otherTyped = other as CreateTicketMaintenanceTicketInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateTicketMaintenanceTicketInsert({
    required this.id,
  });
}

@immutable
class CreateTicketData {
  final CreateTicketMaintenanceTicketInsert maintenanceTicket_insert;
  CreateTicketData.fromJson(dynamic json):
  
  maintenanceTicket_insert = CreateTicketMaintenanceTicketInsert.fromJson(json['maintenanceTicket_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTicketData otherTyped = other as CreateTicketData;
    return maintenanceTicket_insert == otherTyped.maintenanceTicket_insert;
    
  }
  @override
  int get hashCode => maintenanceTicket_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['maintenanceTicket_insert'] = maintenanceTicket_insert.toJson();
    return json;
  }

  CreateTicketData({
    required this.maintenanceTicket_insert,
  });
}

@immutable
class CreateTicketVariables {
  final String title;
  final String alertId;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateTicketVariables.fromJson(Map<String, dynamic> json):
  
  title = nativeFromJson<String>(json['title']),
  alertId = nativeFromJson<String>(json['alertId']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTicketVariables otherTyped = other as CreateTicketVariables;
    return title == otherTyped.title && 
    alertId == otherTyped.alertId;
    
  }
  @override
  int get hashCode => Object.hashAll([title.hashCode, alertId.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    json['alertId'] = nativeToJson<String>(alertId);
    return json;
  }

  CreateTicketVariables({
    required this.title,
    required this.alertId,
  });
}

