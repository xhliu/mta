/** 
  * The basic address-free message sending interface for RT messages.
  */ 


#include <TinyError.h>
#include <message.h>

interface RTSend {

  /** 
    * Send a packet with a data payload of <tt>len</tt>. To determine
    * the maximum available size, use the Packet interface of the
    * component providing Send. If send returns SUCCESS, then the
    * component will signal the sendDone event in the future; if send
    * returns an error, it will not signal sendDone.  Note that a
    * component may accept a send request which it later finds it
    * cannot satisfy; in this case, it will signal sendDone with an
    * appropriate error code.
    *
    * @param   	'message_t* ONE msg'     the packet to send
    * @param   	len     the length of the packet payload
    * @param	relative_deadline   relative deadline of the packet
    * @param	e2e_pdr_req: e2e pdr requirement of the packet
    * @return          SUCCESS if the request was accepted and will issue
    *                  a sendDone event, EBUSY if the component cannot accept
    *                  the request now but will be able to later, FAIL
    *                  if the stack is in a state that cannot accept requests
    *                  (e.g., it's off).
    */ 
  command error_t send(message_t* msg, uint8_t len, uint32_t relative_deadline, uint16_t e2e_pdr_req);

  /**
    * Cancel a requested transmission. Returns SUCCESS if the 
    * transmission was cancelled properly (not sent in its
    * entirety). Note that the component may not know
    * if the send was successfully cancelled, if the radio is
    * handling much of the logic; in this case, a component
    * should be conservative and return an appropriate error code.
    *
    * @param   'message_t* ONE msg'    the packet whose transmission should be cancelled
    * @return         SUCCESS if the packet was successfully cancelled, FAIL
    *                 otherwise
    */
  command error_t cancel(message_t* msg);

  /** 
    * Signaled in response to an accepted send request. <tt>msg</tt>
    * is the sent buffer, and <tt>error</tt> indicates whether the
    * send was succesful, and if not, the cause of the failure.
    * 
    * @param 'message_t* ONE msg'   the message which was requested to send
    * @param error SUCCESS if it was transmitted successfully, FAIL if
    *              it was not, ECANCEL if it was cancelled via <tt>cancel</tt>
    */ 
  event void sendDone(message_t* msg, error_t error);

   /**
   * Return the maximum payload length that this communication layer
   * can provide. This command behaves identically to
   * <tt>Packet.maxPayloadLength</tt> and is included in this
   * interface as a convenience.
   *
   * @return  the maximum payload length
   */

  
  command uint8_t maxPayloadLength();


   /**
    * Return a pointer to a protocol's payload region in a packet which
    * at least a certain length.  If the payload region is smaller than
    * the len parameter, then getPayload returns NULL. This command
    * behaves identicallt to <tt>Packet.getPayload</tt> and is
    * included in this interface as a convenience.
    *
    * @param   'message_t* ONE msg'    the packet
    * @return  'void* COUNT_NOK(len)'  a pointer to the packet's payload
    */
  command void* getPayload(message_t* msg, uint8_t len);

}
