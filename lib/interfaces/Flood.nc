#include "../../includes/packet.h"

interface Flood{
   command error_t directFlood(pack msg, uint16_t dest );
}