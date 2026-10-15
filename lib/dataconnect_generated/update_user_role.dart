part of 'generated.dart';

class UpdateUserRoleVariablesBuilder {
  String role;

  final FirebaseDataConnect _dataConnect;
  UpdateUserRoleVariablesBuilder(this._dataConnect, {required  this.role,});
  Deserializer<UpdateUserRoleData> dataDeserializer = (dynamic json)  => UpdateUserRoleData.fromJson(jsonDecode(json));
  Serializer<UpdateUserRoleVariables> varsSerializer = (UpdateUserRoleVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<UpdateUserRoleData, UpdateUserRoleVariables>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateUserRoleData, UpdateUserRoleVariables> ref() {
    UpdateUserRoleVariables vars= UpdateUserRoleVariables(role: role,);
    return _dataConnect.mutation("UpdateUserRole", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class UpdateUserRoleUserUpdate {
  final String id;
  UpdateUserRoleUserUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserRoleUserUpdate otherTyped = other as UpdateUserRoleUserUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateUserRoleUserUpdate({
    required this.id,
  });
}

@immutable
class UpdateUserRoleData {
  final UpdateUserRoleUserUpdate? user_update;
  UpdateUserRoleData.fromJson(dynamic json):
  
  user_update = json['user_update'] == null ? null : UpdateUserRoleUserUpdate.fromJson(json['user_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserRoleData otherTyped = other as UpdateUserRoleData;
    return user_update == otherTyped.user_update;
    
  }
  @override
  int get hashCode => user_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user_update != null) {
      json['user_update'] = user_update!.toJson();
    }
    return json;
  }

  UpdateUserRoleData({
    this.user_update,
  });
}

@immutable
class UpdateUserRoleVariables {
  final String role;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  UpdateUserRoleVariables.fromJson(Map<String, dynamic> json):
  
  role = nativeFromJson<String>(json['role']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateUserRoleVariables otherTyped = other as UpdateUserRoleVariables;
    return role == otherTyped.role;
    
  }
  @override
  int get hashCode => role.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['role'] = nativeToJson<String>(role);
    return json;
  }

  UpdateUserRoleVariables({
    required this.role,
  });
}

