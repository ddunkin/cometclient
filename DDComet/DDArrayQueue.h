
#import <Foundation/Foundation.h>
#import "DDQueue.h"


@interface DDArrayQueue : NSObject <DDQueue>
{
@private
	NSMutableArray *m_array;
	id<DDQueueDelegate> m_delegate;
}

@end
