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
    s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);
    s.addChannel(s.TRANSPORT_CHANNEL);
    # After sending a ping, simulate a little to prevent collision.
    s.runTime(10);
    s.cmdChatServer(1,0);
    s.runTime(10);
    s.cmdChatClient(13,1,1,0,"Hello World!");
    s.runTime(10);
    s.cmdChatBroadcast(1,"12345678901234567890123");
    s.runTime(10);
    s.cmdChatUnicast(1,"Node13","Private Message");
    s.runTime(10);
    s.cmdChatList(1);
    s.runTime(10);
if __name__ == '__main__':
    main()
