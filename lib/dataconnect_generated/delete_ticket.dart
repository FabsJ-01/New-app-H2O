part of 'generated.dart';

class DeleteTicketVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteTicketVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteTicketData> dataDeserializer = (dynamic json)  => DeleteTicketData.fromJson(jsonDecode(json));
  Serializer<DeleteTicketVariables> varsSerializer = (DeleteTicketVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteTicketData, DeleteTicketVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteTicketData, DeleteTicketVariables> ref() {
    DeleteTicketVariables vars= DeleteTicketVariables(id: id,);
    return _dataConnect.mutation("DeleteTicket", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteTicketMaintenanceTicketDelete {
  final String id;
  DeleteTicketMaintenanceTicketDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTicketMaintenanceTicketDelete otherTyped = other as DeleteTicketMaintenanceTicketDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteTicketMaintenanceTicketDelete({
    required this.id,
  });
}

@immutable
class DeleteTicketData {
  final DeleteTicketMaintenanceTicketDelete? maintenanceTicket_delete;
  DeleteTicketData.fromJson(dynamic json):
  
  maintenanceTicket_delete = json['maintenanceTicket_delete'] == null ? null : DeleteTicketMaintenanceTicketDelete.fromJson(json['maintenanceTicket_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTicketData otherTyped = other as DeleteTicketData;
    return maintenanceTicket_delete == otherTyped.maintenanceTicket_delete;
    
  }
  @override
  int get hashCode => maintenanceTicket_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (maintenanceTicket_delete != null) {
      json['maintenanceTicket_delete'] = maintenanceTicket_delete!.toJson();
    }
    return json;
  }

  DeleteTicketData({
    this.maintenanceTicket_delete,
  });
}

@immutable
class DeleteTicketVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteTicketVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteTicketVariables otherTyped = other as DeleteTicketVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteTicketVariables({
    required this.id,
  });
}

