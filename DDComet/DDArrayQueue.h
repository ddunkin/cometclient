
#import <Foundation/Foundation.h>
#import "DDQueue.h"


@interface DDArrayQueue : NSObject <DDQueue> {
	NSMutableArray *m_array;
	id<DDQueueDelegate> m_delegate;
}

@end
