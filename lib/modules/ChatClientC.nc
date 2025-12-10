// queue uint8[40],10
#include "../../includes/socket.h"
#include "../../includes/chatMsg.h"

configuration ChatClientC{
   provides interface ChatClient;
}

implementation{
  components ChatClientP;
   ChatClient = ChatClientP.ChatClient;


    components TCPC;
    ChatClientP.TCP -> TCPC;

    components CommandHandlerC;
    ChatClientP.CommandHandler -> CommandHandlerC;

   //Timers
   components new TimerMilliC() as baseTimer;
   components RandomC as Random;
    ChatClientP.baseTimer -> baseTimer;
    ChatClientP.Random -> Random;

   //Lists
   components new QueueC(chatMsg, 10);
    ChatClientP.sendQueue -> QueueC;

    components new QueueC(chatMsg, 10) as QueueC2;
    ChatClientP.rcvQueue -> QueueC2;
  

}
