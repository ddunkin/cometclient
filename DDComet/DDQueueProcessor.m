
#import "DDQueueProcessor.h"


void DDQueueProcessorPerform(void *info);

@implementation DDQueueProcessor

+ (DDQueueProcessor *)queueProcessorWithQueue:(id<DDQueue>)queue
									   target:(id)target
									 selector:(SEL)selector
{
	DDQueueProcessor *processor = [[[DDQueueProcessor alloc] initWithTarget:target selector:selector] autorelease];
	[queue setDelegate:processor];
	[processor scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	return processor;
}

- (id)initWithTarget:(id)target selector:(SEL)selector
{
	if ((self = [super init]))
	{
		m_target = target;
		m_selector = selector;
		
		CFRunLoopSourceContext context =
		{
			0, self, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
			DDQueueProcessorPerform
		};
		
		m_source = CFRunLoopSourceCreate(NULL, 0, &context);
	}
	return self;
}

- (void)dealloc
{
	if (m_runLoop)
		CFRunLoopRemoveSource([m_runLoop getCFRunLoop], m_source, (CFStringRef)m_mode);

	[m_runLoop release];
	[m_mode release];
	CFRelease(m_source);
    [super dealloc];
}

- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode
{
	@synchronized(self)
	{
		CFRunLoopAddSource([runLoop getCFRunLoop], m_source, (CFStringRef)mode);
		[m_runLoop release];
		m_runLoop = [runLoop retain];
		[m_mode release];
		m_mode = [mode retain];
	}
}

- (void)queueDidAddObject:(id<DDQueue>)queue
{
	CFRunLoopSourceSignal(m_source);
	CFRunLoopWakeUp([m_runLoop getCFRunLoop]);
}

- (void)makeTargetPeformSelector
{
	[m_target performSelector:m_selector];
}

@end

void DDQueueProcessorPerform(void *info)
{
	DDQueueProcessor *processor = info;
	[processor makeTargetPeformSelector];
}
