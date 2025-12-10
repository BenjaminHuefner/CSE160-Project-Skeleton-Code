interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer(uint16_t port);
   event void setTestClient(uint16_t port, uint16_t dest, uint16_t destport, uint16_t transfer);
   event void closeClient(uint16_t port, uint16_t dest, uint16_t destport);
   event void setChatServer(uint8_t port);
   event void ChatConnect(uint8_t srcport, uint8_t dest, uint8_t destport, uint8_t namelength, uint8_t *username);
   event void ChatBroadcast(uint8_t msglength,uint8_t *payload);
   event void ChatUnicast(uint8_t msglength, uint8_t namelength, uint8_t *username, uint8_t *msg);
   event void ChatList();
}
