
#import "NSMutableArray+Queue.h"


@implementation NSMutableArray (Queue)

- (id)removeObject
{
	if ([self count] == 0)
		return nil;
	id object = [[self objectAtIndex:0] retain];
	[self removeObjectAtIndex:0];
	return [object autorelease];
}

@end
