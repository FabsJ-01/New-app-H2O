part of 'generated.dart';

class DeleteSmartMeterVariablesBuilder {
  String id;

  final FirebaseDataConnect _dataConnect;
  DeleteSmartMeterVariablesBuilder(this._dataConnect, {required  this.id,});
  Deserializer<DeleteSmartMeterData> dataDeserializer = (dynamic json)  => DeleteSmartMeterData.fromJson(jsonDecode(json));
  Serializer<DeleteSmartMeterVariables> varsSerializer = (DeleteSmartMeterVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<DeleteSmartMeterData, DeleteSmartMeterVariables>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteSmartMeterData, DeleteSmartMeterVariables> ref() {
    DeleteSmartMeterVariables vars= DeleteSmartMeterVariables(id: id,);
    return _dataConnect.mutation("DeleteSmartMeter", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class DeleteSmartMeterSmartMeterDelete {
  final String id;
  DeleteSmartMeterSmartMeterDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSmartMeterSmartMeterDelete otherTyped = other as DeleteSmartMeterSmartMeterDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSmartMeterSmartMeterDelete({
    required this.id,
  });
}

@immutable
class DeleteSmartMeterData {
  final DeleteSmartMeterSmartMeterDelete? smartMeter_delete;
  DeleteSmartMeterData.fromJson(dynamic json):
  
  smartMeter_delete = json['smartMeter_delete'] == null ? null : DeleteSmartMeterSmartMeterDelete.fromJson(json['smartMeter_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSmartMeterData otherTyped = other as DeleteSmartMeterData;
    return smartMeter_delete == otherTyped.smartMeter_delete;
    
  }
  @override
  int get hashCode => smartMeter_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (smartMeter_delete != null) {
      json['smartMeter_delete'] = smartMeter_delete!.toJson();
    }
    return json;
  }

  DeleteSmartMeterData({
    this.smartMeter_delete,
  });
}

@immutable
class DeleteSmartMeterVariables {
  final String id;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  DeleteSmartMeterVariables.fromJson(Map<String, dynamic> json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSmartMeterVariables otherTyped = other as DeleteSmartMeterVariables;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSmartMeterVariables({
    required this.id,
  });
}

