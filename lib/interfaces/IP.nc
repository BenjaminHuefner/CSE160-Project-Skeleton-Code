#include "../../includes/packet.h"

interface IP{
   command error_t sendPing(uint8_t src, uint8_t dest, uint8_t* payload);
   command error_t readPing(pack msg, uint8_t nodeID);
}