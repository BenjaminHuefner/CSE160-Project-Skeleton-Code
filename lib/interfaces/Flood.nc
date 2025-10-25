#include "../../includes/packet.h"

interface Flood{
   command error_t flood(pack msg, uint8_t nodeID);
   command error_t startFlood(uint8_t src, uint8_t dest, uint8_t *payload);
   event void floodUpdated(uint8_t updated);
   event void messageRecieved(uint8_t* payload);
}