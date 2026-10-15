part of 'generated.dart';

class GetCurrentUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetCurrentUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetCurrentUserData> dataDeserializer = (dynamic json)  => GetCurrentUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetCurrentUserData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetCurrentUserData, void> ref() {
    
    return _dataConnect.query("GetCurrentUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetCurrentUserUser {
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  GetCurrentUserUser.fromJson(dynamic json):
  
  email = nativeFromJson<String>(json['email']),
  role = nativeFromJson<String>(json['role']),
  firstName = json['firstName'] == null ? null : nativeFromJson<String>(json['firstName']),
  lastName = json['lastName'] == null ? null : nativeFromJson<String>(json['lastName']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserUser otherTyped = other as GetCurrentUserUser;
    return email == otherTyped.email && 
    role == otherTyped.role && 
    firstName == otherTyped.firstName && 
    lastName == otherTyped.lastName;
    
  }
  @override
  int get hashCode => Object.hashAll([email.hashCode, role.hashCode, firstName.hashCode, lastName.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['email'] = nativeToJson<String>(email);
    json['role'] = nativeToJson<String>(role);
    if (firstName != null) {
      json['firstName'] = nativeToJson<String?>(firstName);
    }
    if (lastName != null) {
      json['lastName'] = nativeToJson<String?>(lastName);
    }
    return json;
  }

  GetCurrentUserUser({
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
  });
}

@immutable
class GetCurrentUserData {
  final GetCurrentUserUser? user;
  GetCurrentUserData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetCurrentUserUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetCurrentUserData otherTyped = other as GetCurrentUserData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetCurrentUserData({
    this.user,
  });
}

