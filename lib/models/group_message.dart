import '../enum/message_type.dart';

class GroupMessage {
  GroupMessage({
    required this.toGroupId,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromUserId,
    required this.sent,
  });

  late final String toGroupId;
  late final String msg;
  late final String read;
  late final String fromUserId;
  late final String sent;
  late final MessageType type;

  GroupMessage.fromJson(Map<String, dynamic> json) {
    toGroupId = json['toGroupId'].toString();
    msg = json['msg'].toString();
    read = json['read'].toString();
    type = parseMessageType(json['type']?.toString());
    fromUserId = json['fromUserId'].toString();
    sent = json['sent'].toString();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['toGroupId'] = toGroupId;
    data['msg'] = msg;
    data['read'] = read;
    data['type'] = type.name;
    data['fromUserId'] = fromUserId;
    data['sent'] = sent;
    return data;
  }
}