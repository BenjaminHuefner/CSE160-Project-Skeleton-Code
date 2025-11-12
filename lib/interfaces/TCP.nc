#include "../../includes/packet.h"
#include "../../includes/socket.h"

interface TCP{
    command error_t testServer(uint8_t src, uint8_t port);
    command error_t testClient(uint8_t src, uint8_t srcport, uint8_t dest, uint8_t destport, uint16_t transfer);
}