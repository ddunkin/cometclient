
#import <Foundation/Foundation.h>


@class DDCometLongPollingTransport;
@class DDCometMessage;
@class DDCometSubscription;
@class DDQueueProcessor;
@protocol DDCometClientDelegate;
@protocol DDQueue;

typedef enum
{
	DDCometStateDisconnected,
	DDCometStateConnecting,
	DDCometStateConnected,
	DDCometStateDisconnecting
} DDCometState;

@interface DDCometClient : NSObject
{
@private
	NSURL *m_endpointURL;
	volatile int32_t m_messageCounter;
	NSMutableDictionary *m_pendingSubscriptions; // by id
	NSMutableArray *m_subscriptions;
	DDCometState m_state;
	NSDictionary *m_advice;
	id<DDQueue> m_outgoingQueue;
	id<DDQueue> m_incomingQueue;
	DDCometLongPollingTransport *m_transport;
	DDQueueProcessor *m_incomingProcessor;
}

@property (nonatomic, readonly) NSString *clientID;
@property (nonatomic, readonly) NSURL *endpointURL;
@property (nonatomic, readonly) DDCometState state;
@property (nonatomic, readonly) NSDictionary *advice;
@property (nonatomic, assign) id<DDCometClientDelegate> delegate;

- (id)initWithURL:(NSURL *)endpointURL;
- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode;
- (DDCometMessage *)handshake;
- (DDCometMessage *)disconnect;
- (DDCometMessage *)subscribeToChannel:(NSString *)channel target:(id)target selector:(SEL)selector;
- (DDCometMessage *)unsubsubscribeFromChannel:(NSString *)channel target:(id)target selector:(SEL)selector;
- (DDCometMessage *)publishData:(id)data toChannel:(NSString *)channel;

@end

@interface DDCometClient (Internal)

- (id<DDQueue>)outgoingQueue;
- (id<DDQueue>)incomingQueue;

@end

@protocol DDCometClientDelegate <NSObject>
@optional
- (void)cometClientHandshakeDidSucceed:(DDCometClient *)client;
- (void)cometClient:(DDCometClient *)client handshakeDidFailWithError:(NSError *)error;
- (void)cometClientConnectDidSucceed:(DDCometClient *)client;
- (void)cometClient:(DDCometClient *)client connectDidFailWithError:(NSError *)error;
- (void)cometClient:(DDCometClient *)client subscriptionDidSucceed:(DDCometSubscription *)subscription;
- (void)cometClient:(DDCometClient *)client subscription:(DDCometSubscription *)subscription didFailWithError:(NSError *)error;
@end
