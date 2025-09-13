#include "../../includes/packet.h"

interface Flood{
   command error_t broadFlood(pack msg, uint16_t dest );
   command error_t directFlood(pack msg, uint16_t dest );
}