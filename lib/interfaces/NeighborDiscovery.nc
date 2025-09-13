
interface NeighborDiscovery{
   command error_t broadcast();
   command error_t neighborFound(uint16_t src);
}