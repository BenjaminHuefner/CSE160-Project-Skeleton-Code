#include "../../includes/packet.h"

interface IP{
   command error_t sendPing(uint8_t src, uint8_t dest, uint8_t* payload);
   command error_t readPing(pack msg, uint8_t nodeID);
   command error_t sendTCP(uint8_t src , uint16_t dest, uint8_t* payload);
   command error_t readTCP(pack msg, uint8_t nodeID);
   event void sendState(uint8_t updated);
   event void tcpReceived(uint8_t* payload);
}