part of 'generated.dart';

class UpdateTicketVariablesBuilder {
  String id;
  String notes;

  final FirebaseDataConnect _dataConnect;
  UpdateTicketVariablesBuilder(this._dataConnect, {required  this.id,required  this.notes,});
  Deserializer<UpdateTicketData> dataDeserializer = (dynamic json)  => UpdateTicketData.fromJson(jsonDecode(json));
  Serializer<UpdateTicketVariables> varsSerializer = (UpdateTicketVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateTicketData, UpdateTicketVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateTicketData, UpdateTicketVariables> ref() {
    UpdateTicketVariables vars= UpdateTicketVariables(id: id,notes: notes,);
    return _dataConnect.mutation("UpdateTicket", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateTicketMaintenanceTicketUpdate {
  final String id;
  UpdateTicketMaintenanceTicketUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTicketMaintenanceTicketUpdate otherTyped = other as UpdateTicketMaintenanceTicketUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateTicketMaintenanceTicketUpdate({
    required this.id,
  });
}

@immutable
class UpdateTicketData {
  final UpdateTicketMaintenanceTicketUpdate? maintenanceTicket_update;
  UpdateTicketData.fromJson(dynamic json):
  
  maintenanceTicket_update = json['maintenanceTicket_update'] == null ? null : UpdateTicketMaintenanceTicketUpdate.fromJson(json['maintenanceTicket_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTicketData otherTyped = other as UpdateTicketData;
    return maintenanceTicket_update == otherTyped.maintenanceTicket_update;
    
  }
  @override
  int get hashCode => maintenanceTicket_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (maintenanceTicket_update != null) {
      json['maintenanceTicket_update'] = maintenanceTicket_update!.toJson();
    }
    return json;
  }

  UpdateTicketData({
    this.maintenanceTicket_update,
  });
}

@immutable
class UpdateTicketVariables {
  final String id;
  final String notes;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateTicketVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']),
  notes = nativeFromJson<String>(json['notes']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateTicketVariables otherTyped = other as UpdateTicketVariables;
    return id == otherTyped.id && 
    notes == otherTyped.notes;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, notes.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['notes'] = nativeToJson<String>(notes);
    return json;
  }

  UpdateTicketVariables({
    required this.id,
    required this.notes,
  });
}

