
#import "DDConcurrentQueue.h"
#import <libkern/OSAtomic.h>


@interface DDConcurrentQueueNode : NSObject
{
@private
    id m_object;
	DDConcurrentQueueNode * volatile m_next;
}

@property (nonatomic, retain) id object;
@property (nonatomic, readonly) DDConcurrentQueueNode *next;

- (BOOL)compareNext:(DDConcurrentQueueNode *)old andSet:(DDConcurrentQueueNode *)new;

@end

@implementation DDConcurrentQueueNode

@synthesize object = m_object, next = m_next;

- (id)initWithObject:(id)object
{
	if ((self = [super init]))
	{
		m_object = [object retain];
	}
	return self;
}

- (void)dealloc
{
	[m_object release];
	[m_next release];
	[super dealloc];
}

- (BOOL)compareNext:(DDConcurrentQueueNode *)old andSet:(DDConcurrentQueueNode *)new
{
	return OSAtomicCompareAndSwapPtrBarrier(old, new, (void * volatile *)&m_next);
}

@end

@interface DDConcurrentQueue ()

- (BOOL)compareHead:(DDConcurrentQueueNode *)old andSet:(DDConcurrentQueueNode *)new;
- (BOOL)compareTail:(DDConcurrentQueueNode *)old andSet:(DDConcurrentQueueNode *)new;

@end

@implementation DDConcurrentQueue

- (id)init
{
	if ((self = [super init]))
	{
		DDConcurrentQueueNode *node = [[DDConcurrentQueueNode alloc] init];
		m_head = node;
		m_tail = node;
	}
	return self;
}

- (void)addObject:(id)object
{
	DDConcurrentQueueNode *node = [[DDConcurrentQueueNode alloc] initWithObject:object];
	while (YES)
	{
		DDConcurrentQueueNode *tail = m_tail;
		DDConcurrentQueueNode *next = tail.next;
		if (tail == m_tail)
		{
			if (next == nil)
			{
				if ([tail compareNext:next andSet:node])
				{
					[self compareTail:tail andSet:node];
					break;
				}
			}
			else
			{
				[self compareTail:tail andSet:node];
			}
		}
	}
	if (m_delegate) {
		[m_delegate queueDidAddObject:self];
    }
    [node release];
}

- (id)removeObject
{
	while (YES)
	{
		DDConcurrentQueueNode *head = m_head;
		DDConcurrentQueueNode *tail = m_tail;
		DDConcurrentQueueNode *first = head.next;
		if (head == m_head)
		{
			if (head == tail)
			{
				if (first == nil)
					return nil;
				else
					[self compareTail:tail andSet:first];
			}
			else if ([self compareHead:head andSet:first])
			{
				id object = [[first.object retain] autorelease];
				if (object != nil)
				{
					first.object = nil;
					return object;
				}
				// else skip over deleted item, continue loop
			}
		}
	}
}

- (void)setDelegate:(id<DDQueueDelegate>)delegate
{
	m_delegate = delegate;
}

- (BOOL)compareHead:(DDConcurrentQueueNode *)old andSet:(DDConcurrentQueueNode *)new
{
	return OSAtomicCompareAndSwapPtrBarrier(old, new, (void * volatile *)&m_head);
}

- (BOOL)compareTail:(DDConcurrentQueueNode *)old andSet:(DDConcurrentQueueNode *)new
{
	return OSAtomicCompareAndSwapPtrBarrier(old, new, (void * volatile *)&m_tail);
}

@end
