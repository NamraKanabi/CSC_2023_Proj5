#
# This code loads an IP packet from the file specified by the path in the
# program argument into memory and calls checksum with the starting address 
# of the IP packet as the argument.
#
#-------------------------------

#-------------------start of common file-----------------------------------------------

.data
packet:		.space 	128
packetFileName:	.space	64
noFileStr:	.asciz "Couldn't open specified file.\n"

.align 2

.text 

main:
lw	a0, 0(a1)	# Put the filename pointer into a0
li	a1, 0		# Flag: Read Only
li	a7, 1024	# Service: Open File
ecall			# File descriptor gets saved in a0 unless an error happens

bltz	a0, main_err    # Negative means open failed
    
la	a1, packet	# write into my binary space
li	a2, 2048        # read a file of at max 2kb
li	a7, 63          # Read File Syscall
ecall

la	a0, packet	# a0 <- Addr[packet]
jal	handlePacket	# a0 <- handlePacket returnVal1
mv 	s0, a0		# s0 <- handlePacket returnVal1
li	a7, 1		# a7 <- 1
ecall			# PrintInt(handlePacket returnVal1)

li	a0, 0xA		# a0 <- '\n'
li	a7, 11		# a7 <- 11
ecall 			# printChar('\n')

mv	a0, a1		# a0 <- handlePacket returnVal2
bnez	s0, printHex	# if packet should be forwarded then the value in a1 should be printed in hex

li	a7, 1		# a7 <- 1
ecall			# printInt(handlePacket returnVal2)

j	main_done	# goto main_done
    
main_err:
la	a0, noFileStr   # print error message in the event of an error when trying to read a file                       
li	a7, 4           # the number of a system call is specified in a7
ecall             	# Print string whose address is in a0
j	main_done	# goto main_done
 
printHex:   
li	a7, 34		# a7 <- 34
ecall 			# printIntHex(handlePacket returnVal2)
    
main_done:
li	a0, 0xA		# a0 <- '\n'
li	a7, 11		# a7 <- 11
ecall 			# printChar('\n')

   
li      a7, 10          # ecall 10 exits the program with code 0
ecall

#-------------------end of common file-------------------------------------------------
