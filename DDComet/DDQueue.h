
#import <Foundation/Foundation.h>


@protocol DDQueueDelegate;

@protocol DDQueue <NSObject>

- (void)addObject:(id)object;
- (id)removeObject;

@optional
- (void)setDelegate:(id<DDQueueDelegate>)delegate;

@end

@protocol DDQueueDelegate <NSObject>

- (void)queueDidAddObject:(id<DDQueue>)queue;

@end
