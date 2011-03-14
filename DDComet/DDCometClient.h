
#import <Foundation/Foundation.h>


@class DDCometClientOperation;
@class DDCometMessage;
@class DDCometSubscription;
@protocol DDCometClientDelegate;
@protocol DDQueue;

typedef enum {
	DDCometStateDisconnected,
	DDCometStateConnecting,
	DDCometStateConnected
} DDCometState;

@interface DDCometClient : NSObject {
@private
	NSURL *m_endpointURL;
	volatile int32_t m_messageCounter;
	NSMutableDictionary *m_pendingSubscriptions; // by id
	NSMutableArray *m_subscriptions;
	DDCometState m_state;
	id<DDQueue> m_outgoingQueue;
	id<DDQueue> m_incomingQueue;
	NSOperationQueue *m_communicationOperationQueue;
}

@property (nonatomic, readonly) NSString *clientID;
@property (nonatomic, readonly) NSURL *endpointURL;
@property (nonatomic, assign) id<DDCometClientDelegate> delegate;

- (id)initWithURL:(NSURL *)endpointURL;
- (BOOL)handshake:(NSError **)error;
- (BOOL)connect:(NSError **)error;
- (void)disconnect;
- (BOOL)subscribeToChannel:(NSString *)channel target:(id)target selector:(SEL)selector error:(NSError **)error;
- (BOOL)unsubsubscribeFromChannel:(NSString *)channel target:(id)target selector:(SEL)selector error:(NSError **)error;
- (BOOL)publishMessage:(DDCometMessage *)message toChannel:(NSString *)channel error:(NSError **)error;

@end

@interface DDCometClient (Internal)

- (id<DDQueue>)outgoingQueue;
- (id<DDQueue>)incomingQueue;
- (void)operationDidFinish:(DDCometClientOperation *)operation;

@end

@protocol DDCometClientDelegate <NSObject>
@optional
- (void)cometClientHandshakeDidSucceed:(DDCometClient *)client;
- (void)cometClient:(DDCometClient *)client handshakeDidFailWithError:(NSError *)error;
- (void)cometClient:(DDCometClient *)client subscriptionDidSucceed:(DDCometSubscription *)subscription;
- (void)cometClient:(DDCometClient *)client subscription:(DDCometSubscription *)subscription didFailWithError:(NSError *)error;
@end
