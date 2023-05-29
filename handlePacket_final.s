
.include "common.s"
.include "checksum.s"
#----------------------------------------------------------------------
# Function: handlePacket         
# Function handlePacket verifies that the packet is IPv4, the header checksum is valid, 
# and the TTL is greater than one. If any of these conditions fail, the packet will be dropped. 
# If valid, decrements the TTL and recalculates the header checksum so that the packet can be forwarded.
#
# Argument:
#	a0: starting address of an IP packet in memory.
#
# Return:
#	a0: 1 if packet is valid and 0 if invalid
#	a1: starting address of IP packet is valid OR
#	    0 if the calculated checksum does not match the Header Checksum field
#	    1 if the TTL is less than or equal to one
#	    2 if the IP Version is not four
# 
# Register Usage:
#        a0: argument, return value and input values for functions that will be called
#        a1: return address of IP Packet or values
#	 s0: contain starting address of IP packet
#	 t0: temporarily load TTL from IP packet 
#-----------------------------------------------------------------------
# 
handlePacket:
	addi	sp, sp, -8 #save ra and s0 to stack
	sw	ra, 4(sp)
	sw	s0, 0(sp)

	mv 	s0, a0 #store starting address of IP Packet into s0
	
	jal 	validateIP #validate IP version
	beqz 	a0, notValid_IP
	
	mv 	a0, s0 #load back starting address into a0 for validateChecksum
	jal 	validateChecksum #validate checksum
	beqz 	a0, notValid_sum
	
	mv 	a0, s0 #load back starting address into a0 for validateTTL
	jal 	validateTTL #validate TTL
	beqz 	a0, notValid_TTL
	
	#All three conditions have been fullfilled, packet is valid
	lbu 	t0, 8(s0) #load TTL of the packet
	addi 	t0, t0, -1 #decremenrt TTL
	sb 	t0, 8(s0) #save decreased TTL back to original packet
	
	mv 	a0, s0 #load back starting address into a0 for checksum
	jal 	checksum 
	sb 	a0, 11(s0) #save new headerchecksum back to original packet
	srli 	a0, a0, 8
	sb 	a0, 10(s0)
	
	li 	a0, 1 #load 1 into a0 signifying valid packet
	
	j 	True_end
	
	notValid_IP: #not valid IP version, return 0 and 2 in a0 and a1 respectively
		li 	a0, 0
		li 	a1, 2
		j 	True_end
	
	notValid_TTL: #not valid IP TTL, return 0 and 1 in a0 and a1 respectively
		li 	a0, 0
		li 	a1, 1
		j 	True_end
	
	notValid_sum: #not valid IP checksum, return 0 and 0 in a0 and a1 respectively
		li 	a0, 0
		li 	a1, 0
		j 	True_end

#----------------------------------------------------------------------
# Function: validateChecksum            
# Function validateChecksum verifies that the packet's Header Checksum is valid.
# It calls function checksum and calculates checksum and compares it to Packet's
# header checksum.
#
# Argument:
#	a0: starting address of an IP packet in memory
#
# Return:
#	a0: 1 if header checksum is valid and 0 if invalid
# 
# Register Usage:
#        a0: starting address of an IP packet in memory
#        s0: header checksum from the IP Packet
#        t1: used to mask header checksum to convert it into big-endian
#-----------------------------------------------------------------------
validateChecksum:
	addi 	sp, sp, -8 #save ra and s0 to stack
	sw 	ra, 4(sp)
	sw 	s0, 0(sp)

	lhu 	s0, 10(a0) #load header checksum from packet
	andi 	t1, s0, 0xFF #convert it to big-endian
	slli 	t1, t1, 8
	srli 	s0, s0, 8
	add 	s0, s0, t1
	
	jal 	checksum #call function to calculate checksum
	
	beq 	a0, s0, validSum #check if calculated headerchecksum matches headerchecksum field
	
	li 	a0, 0 #returns 0 if not match
	j 	sum_end
	
	validSum: #return if matches
		li 	a0, 1
		j 	sum_end
	
	sum_end: #end of validateChecksum regardless of result
		lw 	ra, 4(sp) #load ra and s0 back from stack and return 
		lw 	s0, 0(sp)
		addi 	sp, sp, 8
		jalr 	zero, ra, 0

#----------------------------------------------------------------------
# Function: validateTTL          
# Function validateTTL verifies that the packet's TTL is valid.
# If TTL is higher than 1 then it's valid and if less or
# equal to 1 then invalid.
#
# Argument:
#	a0: starting address of an IP packet in memory
#
# Return:
#	a0: 1 if TTL is greater than 1 and 0 if not
# 
# Register Usage:
#        a0: starting address of an IP packet in memory
#        t0: load 1 (used to compare with packet's TTL)
#        t1: load TTL from the packet
#-----------------------------------------------------------------------
validateTTL: #validates IP TTL
	li 	t0, 1 #minimum life for packet
	lbu 	t1, 8(a0) #load TTL of the packet
	
	bgtu 	t1, t0, validTTL #check if TTL is higher than 1
	
	li 	a0, 0 #return 0 if TTL is not higher than 1
	jalr 	zero, ra, 0
	
	validTTL: #return 1 if TTl if higher than 1
		li 	a0, 1
		jalr 	zero, ra, 0

#----------------------------------------------------------------------
# Function: validateIP          
# Function validateIP verifies that the packet's IP version is valid.
# If version is 4 then it's valid and if not then invalid.
#
# Argument:
#	a0: starting address of an IP packet in memory
#
# Return:
#	a0: 1 if IP version is 4 and 0 if not
# 
# Register Usage:
#        a0: starting address of an IP packet in memory
#        t0: load 4 (used to compare with packet's IP version)
#        t1: load IP version from the packet
#-----------------------------------------------------------------------
validateIP: #validates IP version
	li 	t0, 4 #required IP version
	lbu 	t1, 0(a0)
	srli 	t1, t1, 4 #get IP version 
	
	beq 	t0, t1, validIP #check if IP version is 4
	
	li 	a0, 0 #return 0 if IP version is not 4
	jalr 	zero, ra, 0
	
	validIP: #return 1 if IP version is 4
		li 	a0, 1
		jalr 	zero, ra, 0

#----------------------------------------------------------------------
# Simple label for end of function handlePacket
# loads back all stored registers from stack and returns 
#-----------------------------------------------------------------------	
True_end:
	lw	ra, 4(sp)
	lw	s0, 0(sp)
	addi	sp, sp, 8
	
	jalr	zero, ra, 0
	
