/**
 *  A general EDF queue component, whose queue has a bounded size.
 *
 * Xiaohui Liu
 * whulxh@gmail.com
 * 7/13/2011
 */

   
generic module EDFQueueC(typedef queue_t, uint8_t QUEUE_SIZE) {
    provides interface EDFQueue<queue_t> as Queue;
}

implementation {

queue_t ONE_NOK queue[QUEUE_SIZE];
uint32_t deadlines[QUEUE_SIZE];
uint8_t head = 0;
uint8_t size = 0;

command bool Queue.empty() {
    return (0 == size);
}

command uint8_t Queue.size() {
    return size;
}

command uint8_t Queue.maxSize() {
    return QUEUE_SIZE;
}

command queue_t Queue.head() {
    return queue[head];
}

void printQueue() {
	uint8_t i, j;
	
	dbg_clear("EDFQueueDbg", "queue elements: ");
	for (i = 0; i < size; i++) {
		j = (head + i) % QUEUE_SIZE;
		dbg_clear("EDFQueueDbg", "<%u, %u>, ", queue[j], deadlines[j]);
	}
	dbg_clear("EDFQueueDbg", "\n");
}

command queue_t Queue.dequeue() {
    queue_t t = queue[head];
    dbg("QueueC", "%s: size is %hhu\n", __FUNCTION__, size);
    //printQueue();
    
    if (size > 0) {
    	head = (head + 1) % QUEUE_SIZE;
    	size--;
    }
    return t;
}

command error_t Queue.enqueue(queue_t newVal, uint32_t abs_deadline) {
    uint8_t i, j, k;
    uint8_t pos;

    if (size < QUEUE_SIZE) {
        //find the location
        for (i = 0; i < size; i++) {
        	j = (head + i) % QUEUE_SIZE;
            if (abs_deadline < deadlines[j])
                break;
        }
        //relative position w/ regard to head
        pos = i;
        //TODO: adjust head only if new element has smallest deadline
//         if (size > 0) {
//             for (i = size - 1; i >= pos; i--) {
//                 loop_cnt_2++;
//                 j = (head + i) % QUEUE_SIZE;
//                 k = (head + i + 1) % QUEUE_SIZE;
//                 queue[k] = queue[j];
//                 deadlines[k] = deadlines[j];
//                 //special case of pos 0: to break from inf loop caused by unsigned number always i >= 0
//                 if (0 == pos && i == pos)
//                     break;
//             }
//         }
        if (size > 0) {
            //move backward elements w/ larger deadlines
            if (0 == pos) {
                //adjust head only if new element has smallest deadline
                head = (head + QUEUE_SIZE - 1) % QUEUE_SIZE;
            } else {
                for (i = size; i > pos; i--) {
                    j = (head + i - 1) % QUEUE_SIZE;
                    k = (head + i) % QUEUE_SIZE;
                    queue[k] = queue[j];
                    deadlines[k] = deadlines[j];
                }
            }
        }
        //insert
        pos = (head + pos) % QUEUE_SIZE;
        queue[pos] = newVal;
        deadlines[pos] = abs_deadline;
        size++;
        //printQueue();
        return SUCCESS;
    } else {
        //full
        return FAIL;
    }
}

command queue_t Queue.element(uint8_t idx) {
    idx = (head + idx) % QUEUE_SIZE;
    return queue[idx];
}  

}
