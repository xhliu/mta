/**
 * Xiaohui Liu
 * whulxh@gmail.com
 * 7/13/2011
 * Description:  interface to a EDF list (queue) that contains items
 *  of a specific type. The queue has a maximum size.
 */

   
interface EDFQueue<t> {

  /**
   * Returns if the queue is empty.
   *
   * @return Whether the queue is empty.
   */
  command bool empty();

  /**
   * The number of elements currently in the queue.
   * Always less than or equal to maxSize().
   *
   * @return The number of elements in the queue.
   */
  command uint8_t size();

  /**
   * The maximum number of elements the queue can hold.
   *
   * @return The maximum queue size.
   */
  command uint8_t maxSize();

  /**
   * Get the head of the queue without removing it. If the queue
   * is empty, the return value is undefined.
   *
   * @return 't ONE' The head of the queue.
   */
  command t head();
  
  /**
   * Remove the element w/ earliest deadline of the queue. If the queue is empty, the return
   * value is undefined.
   * 
   * 
   * @return 't ONE' The head of the queue.
   */
  command t dequeue();

  /**
   * Enqueue an element to the tail of the queue.
   *
   * @param 't ONE newVal' - the element to enqueue
   * @abs_deadline  - absolute deadline associated with this element
   * @return SUCCESS if the element was enqueued successfully, FAIL
   *                 if it was not enqueued.
   */
  command error_t enqueue(t newVal, uint32_t abs_deadline);

  /**
   * Return the nth element of the queue without dequeueing it, 
   * where 0 is the head of the queue and (size - 1) is the tail. 
   * If the element requested is larger than the current queue size,
   * the return value is undefined.
   *
   * @param index - the index of the element to return
   * @return 't ONE' the requested element in the queue.
   */
  command t element(uint8_t idx);
}
