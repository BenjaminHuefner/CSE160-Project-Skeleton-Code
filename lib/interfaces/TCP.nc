#include "../../includes/packet.h"
#include "../../includes/socket.h"

interface TCP{
    command error_t testServer(uint8_t src, uint8_t port);
    command error_t testClient(uint8_t src, uint8_t srcport, uint8_t dest, uint8_t destport, uint16_t transfer);
    command uint8_t* AppServer(uint8_t src, uint8_t port);
    command uint8_t* AppClient(uint8_t src, uint8_t srcport, uint8_t dest, uint8_t destport);
    command error_t closeClient(uint8_t src, uint16_t port, uint8_t dest, uint16_t destport);
    event void serverConnected(uint8_t srcport, uint8_t destport);
    event void clientConnected(uint8_t srcport, uint8_t destport);
}