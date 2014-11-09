#include "TreeRouting.h"

/**
 * A data collection service that uses a tree routing protocol
 * to deliver data to collection roots, following TEP 119.
 *
 * @author Rodrigo Fonseca
 * @author Omprakash Gnawali
 * @author Kyle Jamieson
 * @author Philip Levis
 */


configuration CtpP {
  provides {
    interface StdControl;
    interface RTSend as Send[uint8_t client];
    interface RTReceive as Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t];
    interface RTIntercept as Intercept[collection_id_t id];

    interface Packet;
    interface CollectionPacket;
    interface CtpPacket;

    interface CtpInfo;
    interface LinkEstimator;
    interface CtpCongestion;
    interface RootControl;
  }

  uses {
    interface CollectionId[uint8_t client];
    interface CollectionDebug;
  }
}

implementation {

  components ActiveMessageC;
  components new CtpForwardingEngineP() as Forwarder;
  components MainC, LedsC;
  components UtilsC;
  
  Send = Forwarder;
  StdControl = Forwarder;
  Receive = Forwarder.Receive;
  Snoop = Forwarder.Snoop;
  Intercept = Forwarder;
  Packet = Forwarder;
  CollectionId = Forwarder;
  CollectionPacket = Forwarder;
  CtpPacket = Forwarder;
  CtpCongestion = Forwarder;
  
  components new PoolC(message_t, FORWARD_COUNT) as MessagePoolP;
  components new PoolC(fe_queue_entry_t, FORWARD_COUNT) as QEntryPoolP;
  Forwarder.QEntryPool -> QEntryPoolP;
  Forwarder.MessagePool -> MessagePoolP;

#ifdef EDF
    components new EDFQueueC(fe_queue_entry_t*, QUEUE_SIZE) as SendQueueP;
#else
    components new QueueC(fe_queue_entry_t*, QUEUE_SIZE) as SendQueueP;
#endif
    Forwarder.SendQueue -> SendQueueP;

  components new LruCtpMsgCacheC(CACHE_SIZE) as SentCacheP;
  Forwarder.SentCache -> SentCacheP;

  components new TimerMilliC() as RoutingBeaconTimer;
  components new TimerMilliC() as RouteUpdateTimer;
  components LinkEstimatorP as Estimator;
  Forwarder.LinkEstimator -> Estimator;

#if defined(TOSSIM)
  components new AMSenderC(AM_CTP_DATA);
  components new AMReceiverC(AM_CTP_DATA);
  components new AMSnooperC(AM_CTP_DATA);
  Forwarder.SubSend -> AMSenderC;
    Forwarder.SubReceive -> AMReceiverC;
    Forwarder.SubSnoop -> AMSnooperC;
    Forwarder.SubPacket -> AMSenderC;
    Forwarder.AMPacket -> AMSenderC;
    Forwarder.PacketAcknowledgements -> AMSenderC.Acks;
#else
  //packet level synchronization
  components TimeSyncMessageC;
  Forwarder.SubSend -> TimeSyncMessageC.TimeSyncAMSendMilli[AM_CTP_DATA];
  Forwarder.SubReceive -> TimeSyncMessageC.Receive[AM_CTP_DATA];
  Forwarder.SubSnoop -> TimeSyncMessageC.Snoop[AM_CTP_DATA];
  Forwarder.TimeSyncPacket -> TimeSyncMessageC; 
  Forwarder.SubPacket -> TimeSyncMessageC;
  Forwarder.AMPacket -> TimeSyncMessageC;
//  components CC2420XActiveMessageC;
//  Forwarder.PacketAcknowledgements -> CC2420XActiveMessageC;
  //components CC2420XActiveMessageC;
  Forwarder.PacketAcknowledgements -> ActiveMessageC;
#endif  
  components new TimerMilliC() as RetxmitTimer;
  Forwarder.RetxmitTimer -> RetxmitTimer;

  components new TimerMilliC() as CongestionTimer;
  Forwarder.CongestionTimer -> CongestionTimer;

  components RandomC;
  Router.Random -> RandomC;
  Forwarder.Random -> RandomC;

  MainC.SoftwareInit -> Forwarder;

  Forwarder.RootControl -> Router;
  Forwarder.UnicastNameFreeRouting -> Router.Routing;
  Forwarder.RadioControl -> ActiveMessageC;
  Forwarder.Leds -> LedsC;
  //
  Forwarder.RoutingTable -> Router;
  components UartLogC;
  Forwarder.UartLog -> UartLogC;
  components LocalTimeMilliC;
  Forwarder.LocalTimeMilli -> LocalTimeMilliC;
  Forwarder.Utils -> UtilsC;  

  //components new CtpRoutingEngineP(TREE_ROUTING_TABLE_SIZE, 128, 512000) as Router;
  components new CtpRoutingEngineP(NEIGHBOR_TABLE_SIZE, MIN_BEACON_PERIOD, MAX_BEACON_PERIOD) as Router;
  
  StdControl = Router;
  StdControl = Estimator;
  RootControl = Router;
  MainC.SoftwareInit -> Router;
  Router.BeaconSend -> Estimator.Send;
  Router.BeaconReceive -> Estimator.Receive;
  Router.LinkEstimator -> Estimator.LinkEstimator;

  Router.CompareBit -> Estimator.CompareBit;

  Router.AMPacket -> ActiveMessageC;
  Router.RadioControl -> ActiveMessageC;
  Router.BeaconTimer -> RoutingBeaconTimer;
  Router.RouteTimer -> RouteUpdateTimer;
  Router.CollectionDebug = CollectionDebug;
  Forwarder.CollectionDebug = CollectionDebug;
  Forwarder.CtpInfo -> Router;
  Router.CtpCongestion -> Forwarder;
  CtpInfo = Router;
  //
  Router.UartLog -> UartLogC;
  Router.DataPanel -> Forwarder;
  Router.LocalTimeMilli -> LocalTimeMilliC;
#ifdef DS_P2
	Router.Utils -> UtilsC;
#endif
#if defined(SDRCS) && !defined(TOSSIM)
	components CC2420PacketC;
	Router.CC2420Packet -> CC2420PacketC;
#endif	
#if !defined(TOSSIM)
    Router.TimeSyncPacket -> TimeSyncMessageC;
#endif
  
#if defined(TOSSIM)  
    components new AMSenderC(AM_CTP_ROUTING) as SendControl;
    components new AMReceiverC(AM_CTP_ROUTING) as ReceiveControl;
    Estimator.AMSend -> SendControl;
    Estimator.SubReceive -> ReceiveControl;
    Estimator.SubPacket -> SendControl;
    Estimator.SubAMPacket -> SendControl;
#else
    Estimator.AMSend -> TimeSyncMessageC.TimeSyncAMSendMilli[AM_CTP_ROUTING];
    Estimator.SubReceive -> TimeSyncMessageC.Receive[AM_CTP_ROUTING];
    Estimator.SubPacket -> TimeSyncMessageC;
    Estimator.SubAMPacket -> TimeSyncMessageC;
#endif
  //Estimator.RoutingTable -> Router;
  LinkEstimator = Estimator;
  
  Estimator.Random -> RandomC;
#ifdef LINE_TOPOLOGY
	Estimator.Utils -> UtilsC;
#endif    

#if defined(PLATFORM_TELOSB) || defined(PLATFORM_MICAZ)
#ifndef TOSSIM
	//cc2420x stack
  //components CC2420ActiveMessageC as PlatformActiveMessageC;
  components DummyActiveMessageP as PlatformActiveMessageC;
#else
  components DummyActiveMessageP as PlatformActiveMessageC;
#endif
#elif defined (PLATFORM_MICA2) || defined (PLATFORM_MICA2DOT)
  components CC1000ActiveMessageC as PlatformActiveMessageC;
#else
  components DummyActiveMessageP as PlatformActiveMessageC;
#endif
    //????use dummy since cc2420x stack may not implement LinkPacketMetadata interface
  Estimator.LinkPacketMetadata -> PlatformActiveMessageC;

  // eventually
  //  Estimator.LinkPacketMetadata -> ActiveMessageC;

  MainC.SoftwareInit -> Estimator;
}
