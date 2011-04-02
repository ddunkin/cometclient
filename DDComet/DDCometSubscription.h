
#import <Foundation/Foundation.h>


@interface DDCometSubscription : NSObject

@property (nonatomic, readonly) NSString *channel;
@property (nonatomic, readonly) id target;
@property (nonatomic, readonly) SEL selector;

- (id)initWithChannel:(NSString *)channel target:(id)target selector:(SEL)selector;
- (BOOL)matchesChannel:(NSString *)channel;

@end
