
#import <Foundation/Foundation.h>
#import "DDQueue.h"


@class DDConcurrentQueueNode;

/**
 * Lock-free queue based on Doug Lea's ConcurrentLinkedQueue, based on
 * http://www.cs.rochester.edu/u/michael/PODC96.html by Maged M. Michael and Michael L. Scott.
 */
@interface DDConcurrentQueue : NSObject <DDQueue> {
@private
	DDConcurrentQueueNode * volatile m_head;
	DDConcurrentQueueNode * volatile m_tail;
	id<DDQueueDelegate> m_delegate;
}

@end
