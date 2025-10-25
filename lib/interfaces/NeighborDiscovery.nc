
interface NeighborDiscovery{
   command error_t broadcast(uint8_t src);
   command error_t neighborFound(uint8_t src,uint8_t protocol);
   command uint16_t numNeighbors();
   command uint16_t NeighborNum(uint8_t num);
   command error_t dump();
   event void neighborUpdate(uint8_t updated);
}