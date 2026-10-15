# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetCurrentUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getCurrentUser().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetCurrentUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getCurrentUser();
GetCurrentUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getCurrentUser().ref();
ref.execute();

ref.subscribe(...);
```


### ListUsers
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listUsers().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListUsersData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listUsers();
ListUsersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listUsers().ref();
ref.execute();

ref.subscribe(...);
```


### GetFacility
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getFacility(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetFacilityData, GetFacilityVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getFacility(
  id: id,
);
GetFacilityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getFacility(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListFacilities
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listFacilities().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListFacilitiesData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listFacilities();
ListFacilitiesData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listFacilities().ref();
ref.execute();

ref.subscribe(...);
```


### GetSmartMeter
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getSmartMeter(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetSmartMeterData, GetSmartMeterVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getSmartMeter(
  id: id,
);
GetSmartMeterData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getSmartMeter(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListSmartMeters
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listSmartMeters().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListSmartMetersData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listSmartMeters();
ListSmartMetersData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listSmartMeters().ref();
ref.execute();

ref.subscribe(...);
```


### GetAlert
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getAlert(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAlertData, GetAlertVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getAlert(
  id: id,
);
GetAlertData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getAlert(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMyAlerts
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listMyAlerts().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMyAlertsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listMyAlerts();
ListMyAlertsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listMyAlerts().ref();
ref.execute();

ref.subscribe(...);
```


### GetTicket
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.getTicket(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetTicketData, GetTicketVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getTicket(
  id: id,
);
GetTicketData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.getTicket(
  id: id,
).ref();
ref.execute();

ref.subscribe(...);
```


### ListMyTickets
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.listMyTickets().execute();
```



#### Return Type
`execute()` returns a `QueryResult<ListMyTicketsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.listMyTickets();
ListMyTicketsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.listMyTickets().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.createUser().execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createUser();
CreateUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.createUser().ref();
ref.execute();
```


### UpdateUserRole
#### Required Arguments
```dart
String role = ...;
ExampleConnector.instance.updateUserRole(
  role: role,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateUserRoleData, UpdateUserRoleVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateUserRole(
  role: role,
);
UpdateUserRoleData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String role = ...;

final ref = ExampleConnector.instance.updateUserRole(
  role: role,
).ref();
ref.execute();
```


### DeleteUser
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.deleteUser().execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteUserData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteUser();
DeleteUserData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.deleteUser().ref();
ref.execute();
```


### CreateFacility
#### Required Arguments
```dart
String name = ...;
String coords = ...;
String status = ...;
ExampleConnector.instance.createFacility(
  name: name,
  coords: coords,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateFacilityData, CreateFacilityVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createFacility(
  name: name,
  coords: coords,
  status: status,
);
CreateFacilityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String name = ...;
String coords = ...;
String status = ...;

final ref = ExampleConnector.instance.createFacility(
  name: name,
  coords: coords,
  status: status,
).ref();
ref.execute();
```


### UpdateFacility
#### Required Arguments
```dart
String id = ...;
String status = ...;
ExampleConnector.instance.updateFacility(
  id: id,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateFacilityData, UpdateFacilityVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateFacility(
  id: id,
  status: status,
);
UpdateFacilityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String status = ...;

final ref = ExampleConnector.instance.updateFacility(
  id: id,
  status: status,
).ref();
ref.execute();
```


### DeleteFacility
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteFacility(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteFacilityData, DeleteFacilityVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteFacility(
  id: id,
);
DeleteFacilityData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteFacility(
  id: id,
).ref();
ref.execute();
```


### CreateSmartMeter
#### Required Arguments
```dart
String serial = ...;
double reading = ...;
String facilityId = ...;
ExampleConnector.instance.createSmartMeter(
  serial: serial,
  reading: reading,
  facilityId: facilityId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateSmartMeterData, CreateSmartMeterVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createSmartMeter(
  serial: serial,
  reading: reading,
  facilityId: facilityId,
);
CreateSmartMeterData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String serial = ...;
double reading = ...;
String facilityId = ...;

final ref = ExampleConnector.instance.createSmartMeter(
  serial: serial,
  reading: reading,
  facilityId: facilityId,
).ref();
ref.execute();
```


### UpdateSmartMeter
#### Required Arguments
```dart
String id = ...;
double reading = ...;
ExampleConnector.instance.updateSmartMeter(
  id: id,
  reading: reading,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateSmartMeterData, UpdateSmartMeterVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateSmartMeter(
  id: id,
  reading: reading,
);
UpdateSmartMeterData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
double reading = ...;

final ref = ExampleConnector.instance.updateSmartMeter(
  id: id,
  reading: reading,
).ref();
ref.execute();
```


### DeleteSmartMeter
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteSmartMeter(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteSmartMeterData, DeleteSmartMeterVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteSmartMeter(
  id: id,
);
DeleteSmartMeterData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteSmartMeter(
  id: id,
).ref();
ref.execute();
```


### CreateAlert
#### Required Arguments
```dart
String severity = ...;
String type = ...;
String meterId = ...;
ExampleConnector.instance.createAlert(
  severity: severity,
  type: type,
  meterId: meterId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateAlertData, CreateAlertVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createAlert(
  severity: severity,
  type: type,
  meterId: meterId,
);
CreateAlertData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String severity = ...;
String type = ...;
String meterId = ...;

final ref = ExampleConnector.instance.createAlert(
  severity: severity,
  type: type,
  meterId: meterId,
).ref();
ref.execute();
```


### UpdateAlert
#### Required Arguments
```dart
String id = ...;
String status = ...;
ExampleConnector.instance.updateAlert(
  id: id,
  status: status,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateAlertData, UpdateAlertVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateAlert(
  id: id,
  status: status,
);
UpdateAlertData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String status = ...;

final ref = ExampleConnector.instance.updateAlert(
  id: id,
  status: status,
).ref();
ref.execute();
```


### DeleteAlert
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteAlert(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteAlertData, DeleteAlertVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteAlert(
  id: id,
);
DeleteAlertData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteAlert(
  id: id,
).ref();
ref.execute();
```


### CreateTicket
#### Required Arguments
```dart
String title = ...;
String alertId = ...;
ExampleConnector.instance.createTicket(
  title: title,
  alertId: alertId,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<CreateTicketData, CreateTicketVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createTicket(
  title: title,
  alertId: alertId,
);
CreateTicketData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String title = ...;
String alertId = ...;

final ref = ExampleConnector.instance.createTicket(
  title: title,
  alertId: alertId,
).ref();
ref.execute();
```


### UpdateTicket
#### Required Arguments
```dart
String id = ...;
String notes = ...;
ExampleConnector.instance.updateTicket(
  id: id,
  notes: notes,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<UpdateTicketData, UpdateTicketVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.updateTicket(
  id: id,
  notes: notes,
);
UpdateTicketData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;
String notes = ...;

final ref = ExampleConnector.instance.updateTicket(
  id: id,
  notes: notes,
).ref();
ref.execute();
```


### DeleteTicket
#### Required Arguments
```dart
String id = ...;
ExampleConnector.instance.deleteTicket(
  id: id,
).execute();
```



#### Return Type
`execute()` returns a `OperationResult<DeleteTicketData, DeleteTicketVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.deleteTicket(
  id: id,
);
DeleteTicketData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String id = ...;

final ref = ExampleConnector.instance.deleteTicket(
  id: id,
).ref();
ref.execute();
```

