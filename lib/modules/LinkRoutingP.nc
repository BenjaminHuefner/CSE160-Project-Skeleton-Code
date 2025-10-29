

module LinkRoutingP{

   provides interface LinkRouting;

    uses interface Flood;
   uses interface SimpleSend;
   uses interface Timer<TMilli> as sendTimer;

   uses interface NeighborDiscovery;
   
   uses interface Random;
   
}
implementation{
    uint8_t nodeID;
    uint8_t i=0;
    uint8_t routing[256]={0};
    uint8_t selfPayload[10]={1,2,3,4,5,6,7,8,9,10};
    uint8_t otherPayload[10];
    uint8_t graph[256][256]={0};

    task void recievedData(){}
    task void sendLinkState(){
        if(1){
            call Flood.startFlood(nodeID,nodeID,selfPayload);
        }
        
    }
    command uint8_t LinkRouting.routingTable(uint8_t dest){
        return 3;
    }
   event void NeighborDiscovery.neighborUpdate(uint8_t updated){
    if(updated){
        nodeID=updated;
        signal LinkRouting.routingState(1);
        post sendLinkState();
    }
   }
   event void Flood.floodUpdated(uint8_t updated){}
   event void Flood.messageRecieved(uint8_t* payload){
    // dbg(GENERAL_CHANNEL,"LinkRouting: Message Received\n");
        memcpy(otherPayload,payload,10);
        // i=0;
        // while(i<10){
        //     dbg(GENERAL_CHANNEL,"Payload byte %d: %d\n",i,otherPayload[i]);
        //     i++;
        // }
        
   }
   event void sendTimer.fired(){}


}