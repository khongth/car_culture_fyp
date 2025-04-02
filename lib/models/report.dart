import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reportedBy;
  final String messageId;
  final String messageOwnerId;
  final dynamic timestamp;

  Report({
    required this.id,
    required this.reportedBy,
    required this.messageId,
    required this.messageOwnerId,
    required this.timestamp,
  });

  // Convert Firestore Document to Report object
  factory Report.fromDocument(DocumentSnapshot doc) {
    return Report(
      id: doc.id,
      reportedBy: doc['reportedBy'],
      messageId: doc['messageId'],
      messageOwnerId: doc['messageOwnerId'],
      timestamp: doc['timestamp'],
    );
  }

  // Convert Report object to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'reportedBy': reportedBy,
      'messageId': messageId,
      'messageOwnerId': messageOwnerId,
      'timestamp': timestamp,
    };
  }
}
