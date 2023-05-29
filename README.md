This is a RISC-V program. It simulates how a data package gets handles in a router. Program reads the IP address and checks version, checksum, and TTL(Time to live). If all of them are valid then program passess the data package. It not then program scraps the data package(package would be considered corrupted). 

handlePacket_final.s is main file that contains data package handling code.

common.s is the file needed by handlePacket_final.s to run.

examplePacket.in is an example for input. 

You can use RARs to run the program.