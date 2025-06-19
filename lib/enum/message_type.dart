enum MessageType { text, image, notify }

MessageType parseMessageType(String? typeString) {
  switch (typeString) {
    case 'image':
      return MessageType.image;
    case 'notify':
      return MessageType.notify;
    case 'text':
    default:
      return MessageType.text;
  }
}
