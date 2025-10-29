//try to keep flood packet size <10 bytes with max 8 neighbors + self per LS packet with first uint8 as number of neighbors in payload
#include "../../includes/packet.h"

interface LinkRouting{
   command uint8_t routingTable(uint8_t dest);
   event void routingState(uint8_t updated);
}