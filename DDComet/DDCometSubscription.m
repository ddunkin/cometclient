
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

@end
