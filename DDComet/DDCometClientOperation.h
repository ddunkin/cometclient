
#import <Foundation/Foundation.h>


@class DDCometClient;

@interface DDCometClientOperation : NSOperation {
@private
	DDCometClient *m_client;
	NSMutableData *m_responseData;
}

- (id)initWithClient:(DDCometClient *)client;

@end
