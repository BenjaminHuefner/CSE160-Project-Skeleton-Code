from TestSim import TestSim
def main():
    # Get simulation ready to run.
    s = TestSim();
    # Before we do anything, lets simulate the network off.
    s.runTime(1);
    # Load the the layout of the network.
    s.loadTopo("pizza.topo");
    # Add a noise model to all of the motes.
    s.loadNoise("meyer-heavy.txt");
    # Turn on all of the sensors.
    s.bootAll();
    # Add the main channels. These channels are declared in includes/channels.h
    # s.addChannel(s.COMMAND_CHANNEL);
    # s.addChannel(s.GENERAL_CHANNEL);
    # s.addChannel(s.TRANSPORT_CHANNEL);
    s.addChannel(s.CHAT_CHANNEL);
    # After sending a ping, simulate a little to prevent collision.
    s.runTime(200);
    s.cmdChatServer(1,0);
    s.runTime(10);
    s.cmdChatClient(13,1,1,0,"Node13");
    s.runTime(10);
    s.cmdChatClient(8,1,1,0,"Node8");
    s.runTime(10);
    s.cmdChatClient(9,1,1,0,"Node9");
    s.runTime(10);
    s.cmdChatClient(3,1,1,0,"Node3");
    s.runTime(200);
    s.cmdChatBroadcast(13,"12345678901234567890123");
    s.runTime(200);
    s.cmdChatUnicast(13,"Node8","Private Message");
    s.runTime(200);
    s.cmdChatList(13);
    s.runTime(200);
    s.cmdChatList(8);
    s.runTime(1000);
if __name__ == '__main__':
    main()
