#include "../../includes/packet.h"

interface Flood{
   command error_t flood(pack msg, uint16_t nodeID);
   command error_t startFlood(uint16_t src, uint16_t dest, uint8_t *payload);
}