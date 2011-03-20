
#import <Foundation/Foundation.h>
#import "DDQueue.h"


@interface DDQueueProcessor : NSObject <DDQueueDelegate> {
	id m_target;
	SEL m_selector;
	CFRunLoopSourceRef m_source;
	NSRunLoop *m_runLoop;
	NSString *m_mode;
}

+ (DDQueueProcessor *)queueProcessorWithQueue:(id<DDQueue>)queue
									   target:(id)target
									 selector:(SEL)selector;
- (id)initWithTarget:(id)target selector:(SEL)selector;
- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;

@end
