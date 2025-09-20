
interface NeighborDiscovery{
   command error_t broadcast();
   command error_t neighborFound(uint16_t src);
   command uint16_t numNeighbors();
   command uint16_t NeighborNum(uint16_t num);
}