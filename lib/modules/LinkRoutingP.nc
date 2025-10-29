

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
    uint8_t maxNode=7;
    uint8_t numNeighbors=0;
    uint8_t state=0;
    uint8_t i=0;
    uint8_t j=0;
    uint8_t routing[256]={0};
    uint8_t selfPayload[10]={0};
    uint8_t otherPayload[10];
    uint8_t graph[256][256]={0};

    task void recievedData(){}
    task void sendLinkState(){
        // dbg(GENERAL_CHANNEL,"LinkRouting: Sending Link State\n");
        numNeighbors= call NeighborDiscovery.numNeighbors();
        selfPayload[0]=nodeID;
        selfPayload[1]=numNeighbors;
        for(i=0;i<numNeighbors;i++){
            selfPayload[i+2]=call NeighborDiscovery.NeighborNum(i);
        }

        call Flood.startFlood(nodeID,nodeID,selfPayload);
        call sendTimer.startOneShot(30000);
        
    }
    task void buildTable(){
        
        if(state==2){
            state=0;
            signal LinkRouting.routingState(1);
        }
    }
    command uint8_t LinkRouting.routingTable(uint8_t dest){
        return 3;
    }
    command void LinkRouting.printTable(){
        dbg(GENERAL_CHANNEL,"Graph for Node %d:\n",nodeID);
        for(i=1;i<=maxNode;i++){
            for(j=1;j<=maxNode;j++){
                if(graph[i][j]==1){
                    dbg(GENERAL_CHANNEL,"%d Neighbors to: %d\n",i,j);
                }
            }
            
        }
    }
   event void NeighborDiscovery.neighborUpdate(uint8_t updated){
    if(updated){
        nodeID=updated;
        if(maxNode<nodeID){
            maxNode=nodeID;
        }
        // signal LinkRouting.routingState(1);
        state=1;
        signal LinkRouting.routingState(0);
        post sendLinkState();
    }
   }
   event void Flood.floodUpdated(uint8_t updated){}
   event void Flood.messageRecieved(uint8_t* payload){
    // dbg(GENERAL_CHANNEL,"LinkRouting: Message Received\n");
        memcpy(otherPayload,payload,10);
        // if(nodeID==1){
        //     for(i=0;i<10;i++){
        //     dbg(GENERAL_CHANNEL,"Payload byte %d: %d\n",i,otherPayload[i]);
        // // }
        // }
        
        if((state==0||state==2)&&nodeID!=0){
            state=1;
            signal LinkRouting.routingState(0);
            post sendLinkState();
        }
        if(call sendTimer.isRunning()){
            call sendTimer.stop();
        }
            i=otherPayload[1];
            for(i=0;i<maxNode;i++){
                graph[otherPayload[0]][i+1]=0;
            }
            for(i=0;i<otherPayload[1];i++){
                graph[otherPayload[0]][otherPayload[i+2]]=1;
                if(maxNode<otherPayload[i+2]){
                    maxNode=otherPayload[i+2];
                }
            }
            call sendTimer.startOneShot(30000);
        

        // i=0;
        // while(i<10){
        //     dbg(GENERAL_CHANNEL,"Payload byte %d: %d\n",i,otherPayload[i]);
        //     i++;
        // }
        
   }
   event void sendTimer.fired(){
    state=2;
    post buildTable();
   }


}