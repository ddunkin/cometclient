
#import <Foundation/Foundation.h>


@class DDCometClient;

@interface DDCometLongPollingTransport : NSObject
{
@private
	DDCometClient *m_client;
	volatile BOOL m_shouldCancel;
	NSMutableDictionary *m_responseDatas;
}

- (id)initWithClient:(DDCometClient *)client;
- (void)start;
- (void)cancel;

@end
