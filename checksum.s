#
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2020 <student name>
#
# Redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential 
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including 
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#---------------------------------------------------------------
#
# handlePacket will need to the calculated header checksum of a 
# given packet. During testing, you should paste the code from
# your solution to lab3 in this file with the line 
# .include "common.s" removed. During grading, a correct 
# implementation of checksum will replace this file.
#
#---------------------------------------------------------------
# 

# Function: checksum            
# Function checksum accepts a0 as parameter which contains starting 
# address of an IP packet in memory. check sum calls function flipHalfwordBytes
# and getHeaderLength to find length of packet's Packet Header Length field and
# converts little-endian format to big-endian format to calculate checksum.
# It uses loop1 to loop through Header to calculate checksum.
#
# Register Usage:
#	a0:  starting address of the IP packet in memory
#	a0:  calculated checksum of the packet in the lower halfword in big-endian byte order
#	s0:  starting address of the IP packet since a0 is used for other functions
#	s1:  stores packet header length 
#	s2:  accumulator, it stores checksum
#	s3:  stores max 16 bit int value which is used for masking during carry process
#	s9:  limit for loop, to make to stop
#	s10: looper counter
#	t0:  used to temporarily store flipped halfword
#	t1:  load number 5, so that loop skips header checksum
#-----------------------------------------------------------------------
# 
checksum:
	addi 	sp, sp, -28 	#push ra and save registers to stack
   	sw   	ra, 24(sp)
   	sw   	s0, 20(sp)
   	sw   	s1, 16(sp)
   	sw   	s2, 12(sp)
   	sw   	s3, 8(sp)
   	sw   	s9, 4(sp)
   	sw   	s10, 0(sp)
   	
   	li 	s3, 0xffff 	#load max value for 16 bit int into s3
   	mv 	s0, a0 		#move starting address of ip packet to s0
   	
   	jal 	getHeaderLength #calls getHeaderLength 
   	mv 	s1, a0 		#move packet header length to s1
   	slli 	s9, s1, 1 	#loop limit
   	li 	s10, 1 		#loop counter
   	
   	li 	s2, 0 			#accumulator 
   	lhu 	a0, 0(s0) 		#load lower halfword
   	jal 	flipHalfwordBytes 	#flip halfword
   	mv 	s2, a0 			#move flipped halfword to s2
   	addi 	s0, s0, 2 		#move to next halfword
   	
   	loop1:
   	bgeu 	s10, s9, end 	#if loop counter(s10) is greater than loop limit(s9) end loop
   	
   	lhu a0, 0(s0) 		#load lower halfword
   	jal flipHalfwordBytes 	#flip halfword
   	mv t0, a0 		#move flipped halfword temporarily to t0
   	
   	li t1, 5 		#position of header checksum
   	beq s10, t1, skip	#if loop reaches header checksum position, it skips it
   	
   	add s2, s2, t0		#add t0 to accumulator
   	bgtu s2, s3, carry	#if accumulator value becomes greater than max 16 bit int value then carry
   	addi s0, s0, 2 		#next halfword
   	addi s10, s10, 1 	#increment looper counter
   	j loop1	
   	
   	end:			#end of checksum, restores save registers and ra
	not s2, s2		#logical complement of accumulater
	slli s2, s2, 16
	srli s2, s2, 16
	mv a0, s2		#moves accumulator to a0 to be returned
	
	lw   ra, 24(sp)
	lw   s0, 20(sp)
   	lw   s1, 16(sp)
   	lw   s2, 12(sp)
   	lw   s3, 8(sp)
   	lw   s9, 4(sp)
   	lw   s10, 0(sp)
   	addi sp, sp, 28
   	
   	jalr zero, ra, 0	#return
   	
#----------------------------------------------------------------------
# Function: flipHalfwordBytes             
# Function flipHalfwordBytes accepts a0 as parameter which  
# should contain a halfword. Function then reverses the order
# of the input byte in lower halfword and then returns it.
# 
# Register Usage:
#        a0: contains the bytes to be flipped
#        a0: the reverse order of the input bytes in the lower halfword
#        t1: used to mask lower halfword from input byte
#-----------------------------------------------------------------------
# 
flipHalfwordBytes:
	andi t1, a0, 0xFF
	slli t1, t1, 8
	srli a0, a0, 8
	add a0, a0, t1
	
	jalr zero, ra, 0

#----------------------------------------------------------------------
# Function: getHeaderLength         
# Function getHeaderLength accepts a0 as parameter which
# should contain tarting address of an IP packet in memory.
# Function extracts the value of the packet's Packet Header 
# Length field in the lowest four bits and then returns it.
# 
# Register Usage:
#        a0: starting address of an IP packet in memory
#        a0: the value of the packet's Packet Header Length field in the lowest four bits
#        t2: used to load 8-bitvalue from a0
#        t2: extract Packet Heaader Length field and store it temporarily
#-----------------------------------------------------------------------
# 
getHeaderLength:
	lbu t2, 0(a0)
	andi t2, t2, 0xf
	mv a0, t2
	
	jalr zero, ra, 0

#----------------------------------------------------------------------
# carry:
#	simple lable to do carry and sum operation
#	uses s2, s3, s10
#-----------------------------------------------------------------------
# 
carry:
	and s2, s2, s3
	addi s2, s2, 1
	addi s0, s0, 2
	addi s10, s10, 1
	
	j loop1 #resume loop

#----------------------------------------------------------------------
# skip:
#	simple lable to skip header checksum
#	uses s0, s10
#-----------------------------------------------------------------------
# 
skip:
	addi s0, s0, 2
	addi s10, s10, 1
	
	j loop1 #resume loop