
#import "DDCometClient.h"
#import <libkern/OSAtomic.h>
#import "DDCometClientOperation.h"
#import "DDCometMessage.h"
#import "DDCometSubscription.h"
#import "DDConcurrentQueue.h"
#import "DDQueueProcessor.h"


@interface DDCometClient ()

- (NSString *)nextMessageID;
- (void)sendMessage:(DDCometMessage *)message;
- (void)handleMessage:(DDCometMessage *)message;

@end

@implementation DDCometClient

@synthesize clientID = m_clientID,
	endpointURL = m_endpointURL,
	delegate = m_delegate;

- (id)initWithURL:(NSURL *)endpointURL
{
	if ((self = [super init]))
	{
		m_endpointURL = [endpointURL retain];
		m_pendingSubscriptions = [[NSMutableDictionary alloc] init];
		m_subscriptions = [[NSMutableArray alloc] init];
		m_outgoingQueue = [[DDConcurrentQueue alloc] init];
		m_incomingQueue = [[DDConcurrentQueue alloc] init];
		m_communicationOperationQueue = [[NSOperationQueue alloc] init];
		[m_communicationOperationQueue setMaxConcurrentOperationCount:1];
	}
	return self;
}

- (void)dealloc
{
	[m_communicationOperationQueue release];
	[m_incomingQueue release];
	[m_outgoingQueue release];
	[m_subscriptions release];
	[m_pendingSubscriptions release];
	[m_endpointURL release];
	[m_clientID release];
	[m_incomingProcessor release];
	[super dealloc];
}

- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode
{
	m_incomingProcessor = [[DDQueueProcessor alloc] initWithTarget:self selector:@selector(processIncomingMessages)];
	[m_incomingQueue setDelegate:m_incomingProcessor];
	[m_incomingProcessor scheduleInRunLoop:runLoop forMode:mode];
}

- (BOOL)handshake:(NSError **)error
{
	m_state = DDCometStateConnecting;
	
	DDCometMessage *message = [DDCometMessage messageWithChannel:@"/meta/handshake"];
	message.version = @"1.0";
	message.supportedConnectionTypes = [NSArray arrayWithObject:@"long-polling"];

	[self sendMessage:message];
	return YES;
}

- (BOOL)connect:(NSError **)error
{
	return YES;
}

- (void)disconnect
{
	
}

- (BOOL)subscribeToChannel:(NSString *)channel target:(id)target selector:(SEL)selector error:(NSError **)error
{
	DDCometMessage *message = [DDCometMessage messageWithChannel:@"/meta/subscribe"];
	message.ID = [self nextMessageID];
	message.subscription = channel;
	DDCometSubscription *subscription = [[[DDCometSubscription alloc] initWithChannel:channel target:target selector:selector] autorelease];
	@synchronized(m_pendingSubscriptions)
	{
		[m_pendingSubscriptions setObject:subscription forKey:message.ID];
	}
	[self sendMessage:message];
	return YES;
}

- (BOOL)unsubsubscribeFromChannel:(NSString *)channel target:(id)target selector:(SEL)selector error:(NSError **)error
{
	return YES;
}

- (BOOL)publishMessage:(DDCometMessage *)message toChannel:(NSString *)channel error:(NSError **)error
{
	return YES;
}

#pragma mark -

- (id<DDQueue>)outgoingQueue
{
	return m_outgoingQueue;
}

- (id<DDQueue>)incomingQueue
{
	return m_incomingQueue;
}

- (void)operationDidFinish:(DDCometClientOperation *)operation
{
	if (m_state != DDCometStateDisconnected)
		[m_communicationOperationQueue addOperation:[[[DDCometClientOperation alloc] initWithClient:self] autorelease]];
}

#pragma mark -

- (NSString *)nextMessageID
{
	return [NSString stringWithFormat:@"%d", OSAtomicIncrement32Barrier(&m_messageCounter)];
}

- (void)sendMessage:(DDCometMessage *)message
{
	message.clientID = m_clientID;
	if (!message.ID)
		message.ID = [self nextMessageID];
	[m_outgoingQueue addObject:message];
	
	if ([m_communicationOperationQueue operationCount] == 0)
		[m_communicationOperationQueue addOperation:[[[DDCometClientOperation alloc] initWithClient:self] autorelease]];
}

- (void)handleMessage:(DDCometMessage *)message
{
	NSLog(@"%@", message);
	NSString *channel = message.channel;
	if ([channel isEqualToString:@"/meta/handshake"])
	{
		if ([message.successful boolValue])
		{
			m_clientID = [message.clientID retain];
			m_state = DDCometStateConnected;
			if (m_delegate && [m_delegate respondsToSelector:@selector(cometClientHandshakeDidSucceed:)])
				[m_delegate cometClientHandshakeDidSucceed:self];
		}
		else
		{
			m_state = DDCometStateDisconnected;
			if (m_delegate && [m_delegate respondsToSelector:@selector(cometClient:handshakeDidFailWithError:)])
				[m_delegate cometClient:self handshakeDidFailWithError:message.error];
		}
	}
	else if ([channel isEqualToString:@"/meta/subscribe"])
	{
		DDCometSubscription *subscription = nil;
		@synchronized(m_pendingSubscriptions)
		{
			subscription = [[[m_pendingSubscriptions objectForKey:message.ID] retain] autorelease];
			if (subscription)
				[m_pendingSubscriptions removeObjectForKey:message.ID];
		}
		if ([message.successful boolValue])
		{
			@synchronized(m_subscriptions)
			{
				[m_subscriptions addObject:subscription];
			}
			if (m_delegate && [m_delegate respondsToSelector:@selector(cometClient:subscriptionDidSucceed:)])
				[m_delegate cometClient:self subscriptionDidSucceed:subscription];
		}
		else
		{
			if (m_delegate && [m_delegate respondsToSelector:@selector(cometClient:subscription:didFailWithError:)])
				[m_delegate cometClient:self subscription:subscription didFailWithError:message.error];
		}
	}
	else
	{
		NSMutableArray *subscriptions = [NSMutableArray array];
		@synchronized(m_subscriptions)
		{
			for (DDCometSubscription *subscription in m_subscriptions)
			{
				if ([channel isEqualToString:subscription.channel]) // TODO: handle wildcards
					[subscriptions addObject:subscription];
			}
		}
		for (DDCometSubscription *subscription in subscriptions)
			[subscription.target performSelector:subscription.selector withObject:message];
	}
}

- (void)processIncomingMessages
{
	DDCometMessage *message;
	while ((message = [m_incomingQueue removeObject]))
		[self handleMessage:message];
}
@end
