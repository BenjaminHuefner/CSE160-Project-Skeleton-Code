

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
    uint8_t next;
    uint8_t cost;
    uint8_t minCost=255;
    uint8_t minNode=0;
    uint8_t i=0;
    uint8_t j=0;
    uint8_t routing[256]={0};
    uint8_t selfPayload[10]={0};
    uint8_t otherPayload[10];
    uint8_t graph[256][256]={0};
    uint8_t tentative[256][2]={0};
    uint8_t tentativeCount=0;
    uint8_t confirmed[256][2]={0};

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
    void dijkstra(){
        for(i=1;i<=maxNode;i++){
            confirmed[i][0]=0;
            confirmed[i][1]=0;
            tentative[i][0]=0;
            tentative[i][1]=0;
        }
        confirmed[nodeID][0]=0;
        confirmed[nodeID][1]=nodeID;
        next=nodeID;
        cost=confirmed[next][0];

        for(i=1;i<=maxNode;i++){
            if(graph[next][i]==1 && graph[i][next]==1){
                if(tentative[i][1]==0 && confirmed[i][1]==0){
                    tentative[i][0]=cost+1;
                    tentative[i][1]=i;
                    tentativeCount++;
                }
            }
        }
        while(tentativeCount>0){
            minCost=255;
            minNode=0;
            for(i=1;i<=maxNode;i++){
                if(tentative[i][1]!=0){
                    if(tentative[i][0]<minCost){
                        minCost=tentative[i][0];
                        minNode=i;
                    }
                }
            }
            if(minCost==0){
                tentative[minNode][0]=0;
                tentative[minNode][1]=0;
                tentativeCount--;
                dbg(GENERAL_CHANNEL,"Dijkstra");
                continue;
            }
            if(minNode==0){
                break;
            }
            confirmed[minNode][0]=minCost;
            confirmed[minNode][1]=tentative[minNode][1];
            tentative[minNode][0]=0;
            tentative[minNode][1]=0;
            tentativeCount--;
            next=minNode;
            cost=confirmed[next][0];
            for(i=1;i<=maxNode;i++){
                if(graph[next][i]==1 && graph[i][next]==1){
                    if(tentative[i][1]==0 && confirmed[i][0]==0){
                        tentative[i][0]=cost+1;
                        tentative[i][1]=confirmed[next][1];
                        tentativeCount++;
                    }else{
                        if(tentative[i][0]>cost+1){
                            tentative[i][0]=cost+1;
                            tentative[i][1]=confirmed[next][1];
                        }
                    }
                }
            }
        }

    }
    task void buildTable(){
        dijkstra();
        for(i=1;i<=maxNode;i++){
            routing[i]=confirmed[i][1];
            if(i==nodeID){
                routing[i]=nodeID;
            }
        }
        
        if(state==2){
            state=0;
            dbg(GENERAL_CHANNEL,"LinkRouting: Routing Table Built for %d\n",nodeID);
            signal LinkRouting.routingState(1);
        }
    }
    command uint8_t LinkRouting.routingTable(uint8_t dest){
        return routing[dest];
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
        dbg(GENERAL_CHANNEL,"Routing Table for Node %d:\n",nodeID);
        for(i=1;i<=maxNode;i++){
            dbg(GENERAL_CHANNEL,"Dest: %d Next Hop: %d\n",i,routing[i]);
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
            // dbg(GENERAL_CHANNEL,"LinkRouting: Timer Stopped\n");
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