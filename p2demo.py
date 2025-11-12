from TestSim import TestSim
import ctypes

def main():
    # Get simulation ready to run.
    s = TestSim();

    # Before we do anything, lets simulate the network off.
    s.runTime(1);

    # Load the the layout of the network.
    s.loadTopo("long_line.topo");

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt");

    # Turn on all of the sensors.
    s.bootAll();

    # Add the main channels. These channels are declared in includes/channels.h
    # s.addChannel(s.COMMAND_CHANNEL);
    s.addChannel(s.GENERAL_CHANNEL);
    # s.addChannel(s.FLOODING_CHANNEL);
    # s.addChannel(s.NEIGHBOR_CHANNEL);


    s.runTime(10);

    s.cmdTestServer(10, 80);
    s.runTime(100);

    s.cmdTestClient(5, 1, 10, 80, 2001);
    s.runTime(100);
    # After sending a ping, simulate a little to prevent collision.
    # s.runTime(1);
    # s.neighborDMP(5);
    # s.runTime(200);

    # s.routeDMP(4);
    # s.runTime(10);
    # s.ping(90,100, "Test1");
    # s.runTime(1000);

    # s.moteOff(9);
    # s.runTime(100);

    # s.ping(5,10, "Test2");
    # s.runTime(10);

    # s.routeDMP(7);
    # s.runTime(10);



if __name__ == '__main__':
    main()
