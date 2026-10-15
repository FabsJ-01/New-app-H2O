library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_user.dart';

part 'update_user_role.dart';

part 'delete_user.dart';

part 'get_current_user.dart';

part 'list_users.dart';

part 'create_facility.dart';

part 'update_facility.dart';

part 'delete_facility.dart';

part 'get_facility.dart';

part 'list_facilities.dart';

part 'create_smart_meter.dart';

part 'update_smart_meter.dart';

part 'delete_smart_meter.dart';

part 'get_smart_meter.dart';

part 'list_smart_meters.dart';

part 'create_alert.dart';

part 'update_alert.dart';

part 'delete_alert.dart';

part 'get_alert.dart';

part 'list_my_alerts.dart';

part 'create_ticket.dart';

part 'update_ticket.dart';

part 'delete_ticket.dart';

part 'get_ticket.dart';

part 'list_my_tickets.dart';







class ExampleConnector {
  
  
  CreateUserVariablesBuilder createUser () {
    return CreateUserVariablesBuilder(dataConnect, );
  }
  
  
  UpdateUserRoleVariablesBuilder updateUserRole ({required String role, }) {
    return UpdateUserRoleVariablesBuilder(dataConnect, role: role,);
  }
  
  
  DeleteUserVariablesBuilder deleteUser () {
    return DeleteUserVariablesBuilder(dataConnect, );
  }
  
  
  GetCurrentUserVariablesBuilder getCurrentUser () {
    return GetCurrentUserVariablesBuilder(dataConnect, );
  }
  
  
  ListUsersVariablesBuilder listUsers () {
    return ListUsersVariablesBuilder(dataConnect, );
  }
  
  
  CreateFacilityVariablesBuilder createFacility ({required String name, required String coords, required String status, }) {
    return CreateFacilityVariablesBuilder(dataConnect, name: name,coords: coords,status: status,);
  }
  
  
  UpdateFacilityVariablesBuilder updateFacility ({required String id, required String status, }) {
    return UpdateFacilityVariablesBuilder(dataConnect, id: id,status: status,);
  }
  
  
  DeleteFacilityVariablesBuilder deleteFacility ({required String id, }) {
    return DeleteFacilityVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetFacilityVariablesBuilder getFacility ({required String id, }) {
    return GetFacilityVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListFacilitiesVariablesBuilder listFacilities () {
    return ListFacilitiesVariablesBuilder(dataConnect, );
  }
  
  
  CreateSmartMeterVariablesBuilder createSmartMeter ({required String serial, required double reading, required String facilityId, }) {
    return CreateSmartMeterVariablesBuilder(dataConnect, serial: serial,reading: reading,facilityId: facilityId,);
  }
  
  
  UpdateSmartMeterVariablesBuilder updateSmartMeter ({required String id, required double reading, }) {
    return UpdateSmartMeterVariablesBuilder(dataConnect, id: id,reading: reading,);
  }
  
  
  DeleteSmartMeterVariablesBuilder deleteSmartMeter ({required String id, }) {
    return DeleteSmartMeterVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetSmartMeterVariablesBuilder getSmartMeter ({required String id, }) {
    return GetSmartMeterVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListSmartMetersVariablesBuilder listSmartMeters () {
    return ListSmartMetersVariablesBuilder(dataConnect, );
  }
  
  
  CreateAlertVariablesBuilder createAlert ({required String severity, required String type, required String meterId, }) {
    return CreateAlertVariablesBuilder(dataConnect, severity: severity,type: type,meterId: meterId,);
  }
  
  
  UpdateAlertVariablesBuilder updateAlert ({required String id, required String status, }) {
    return UpdateAlertVariablesBuilder(dataConnect, id: id,status: status,);
  }
  
  
  DeleteAlertVariablesBuilder deleteAlert ({required String id, }) {
    return DeleteAlertVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetAlertVariablesBuilder getAlert ({required String id, }) {
    return GetAlertVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListMyAlertsVariablesBuilder listMyAlerts () {
    return ListMyAlertsVariablesBuilder(dataConnect, );
  }
  
  
  CreateTicketVariablesBuilder createTicket ({required String title, required String alertId, }) {
    return CreateTicketVariablesBuilder(dataConnect, title: title,alertId: alertId,);
  }
  
  
  UpdateTicketVariablesBuilder updateTicket ({required String id, required String notes, }) {
    return UpdateTicketVariablesBuilder(dataConnect, id: id,notes: notes,);
  }
  
  
  DeleteTicketVariablesBuilder deleteTicket ({required String id, }) {
    return DeleteTicketVariablesBuilder(dataConnect, id: id,);
  }
  
  
  GetTicketVariablesBuilder getTicket ({required String id, }) {
    return GetTicketVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ListMyTicketsVariablesBuilder listMyTickets () {
    return ListMyTicketsVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-east1',
    'example',
    'h2o',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
