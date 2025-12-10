// queue uint8[40],10
#include "../../includes/socket.h"
#include "../../includes/chatMsg.h"

configuration ChatServerC{
   provides interface ChatServer;
}

implementation{
  components ChatServerP;
   ChatServer = ChatServerP.ChatServer;


    components TCPC;
    ChatServerP.TCP -> TCPC;
    components CommandHandlerC;
    ChatServerP.CommandHandler -> CommandHandlerC;

   //Timers
   components new TimerMilliC() as baseTimer;
   components RandomC as Random;
    ChatServerP.baseTimer -> baseTimer;
    ChatServerP.Random -> Random;

   //Lists
   components new QueueC(chatMsg, 10);
    ChatServerP.sendQueue -> QueueC;

    components new QueueC(chatMsg, 10) as QueueC2;
    ChatServerP.rcvQueue -> QueueC2;
  

}
