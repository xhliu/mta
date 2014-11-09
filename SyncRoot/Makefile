COMPONENT=CommanderC
#PFLAGS = -DSTAMPMICRO

# Much software is in IAtsync/ subdirectory
#PFLAGS += -I../IAtsync -I../tos/chips/cc2420 -I../tos/chips/cc2420/packet 
#PFLAGS += -I../tos/chips/cc2420/transmit -I../tos/chips/cc2420/receive 
#CFLAGS += -I$(TOSROOT)/../Programming/TinyOS/Utils
# use -DTRACK to get neighborhood
# tracking (biconnected links, 
# needed for skew compensation)  
# (note: TRACK and POWCON together
#        is an untested combo)
#PFLAGS += -DTRACK

CFLAGS    += -DCC2420_DEF_RFPOWER=31 #31, 27, 23, 19, 15, 11, 7, 3. 
CFLAGS    += -DTOSH_DATA_LENGTH=114
PFLAGS    += -DCC2420_DEF_CHANNEL=26

include $(MAKERULES)
