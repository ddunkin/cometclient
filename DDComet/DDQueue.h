
#import <Foundation/Foundation.h>


@protocol DDQueue <NSObject>

- (void)addObject:(id)object;
- (id)removeObject;

@end
