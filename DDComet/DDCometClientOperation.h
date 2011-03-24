
#import <Foundation/Foundation.h>


@class DDCometClient;

@interface DDCometClientOperation : NSOperation
{
@private
	DDCometClient *m_client;
	volatile BOOL m_cancelPolling;
	NSMutableData *m_responseData;
}

- (id)initWithClient:(DDCometClient *)client;
- (void)cancelPolling;

@end
