#include "../../includes/packet.h"

interface Flood{
   command error_t flood(pack msg, uint16_t dest, uint16_t lastSrc );
}