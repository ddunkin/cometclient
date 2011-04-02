
#import "DDCometSubscription.h"


@implementation DDCometSubscription

@synthesize channel = m_channel,
	target = m_target,
	selector = m_selector;

- (id)initWithChannel:(NSString *)channel target:(id)target selector:(SEL)selector
{
	if ((self = [super init]))
	{
		m_channel = [channel retain];
		m_target = target;
		m_selector = selector;
	}
	return self;
}

- (void)dealloc
{
	[m_channel release];
	[super dealloc];
}

- (BOOL)matchesChannel:(NSString *)channel
{
	if ([m_channel isEqualToString:channel])
		return YES;
	if ([m_channel hasSuffix:@"/**"])
	{
		NSString *prefix = [m_channel substringToIndex:([m_channel length] - 2)];
		if ([channel hasPrefix:prefix])
			return YES;
	}
	else if ([m_channel hasSuffix:@"/*"])
	{
		NSString *prefix = [m_channel substringToIndex:([m_channel length] - 1)];
		if ([channel hasPrefix:prefix] && [[channel substringFromIndex:([m_channel length] - 1)] rangeOfString:@"*"].location == NSNotFound)
			return YES;
	}
	return NO;
}

@end
