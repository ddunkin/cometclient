
#import "DDCometClient.h"
#import <libkern/OSAtomic.h>
#import "DDCometLongPollingTransport.h"
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
	state = m_state,
	advice = m_advice,
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
	}
	return self;
}

- (void)dealloc
{
	[m_transport release];
	[m_incomingQueue release];
	[m_outgoingQueue release];
	[m_subscriptions release];
	[m_pendingSubscriptions release];
	[m_endpointURL release];
	[m_clientID release];
	[m_incomingProcessor release];
	[m_advice release];
	[super dealloc];
}

- (void)scheduleInRunLoop:(NSRunLoop *)runLoop forMode:(NSString *)mode
{
	m_incomingProcessor = [[DDQueueProcessor alloc] initWithTarget:self selector:@selector(processIncomingMessages)];
	[m_incomingQueue setDelegate:m_incomingProcessor];
	[m_incomingProcessor scheduleInRunLoop:runLoop forMode:mode];
}

- (DDCometMessage *)handshake
{
	m_state = DDCometStateConnecting;
	
	DDCometMessage *message = [DDCometMessage messageWithChannel:@"/meta/handshake"];
	message.version = @"1.0";
	message.supportedConnectionTypes = [NSArray arrayWithObject:@"long-polling"];

	[self sendMessage:message];
	return message;
}

- (DDCometMessage *)disconnect
{
	m_state = DDCometStateDisconnecting;
	
	DDCometMessage *message = [DDCometMessage messageWithChannel:@"/meta/disconnect"];
	[self sendMessage:message];
	return message;
}

- (DDCometMessage *)subscribeToChannel:(NSString *)channel target:(id)target selector:(SEL)selector
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
	return message;
}

- (DDCometMessage *)unsubsubscribeFromChannel:(NSString *)channel target:(id)target selector:(SEL)selector
{
	DDCometMessage *message = [DDCometMessage messageWithChannel:@"/meta/unsubscribe"];
	message.ID = [self nextMessageID];
	message.subscription = channel;
	@synchronized(m_subscriptions)
	{
		NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
		NSUInteger count = [m_subscriptions count];
		for (NSUInteger i = 0; i < count; i++)
		{
			DDCometSubscription *subscription = [m_subscriptions objectAtIndex:i];
			if ([subscription.channel isEqualToString:channel] && subscription.target == target && subscription.selector == selector)
			{
				[indexes addIndex:i]; 
			}
		}
		[m_subscriptions removeObjectsAtIndexes:indexes];
	}
	return message;
}

- (DDCometMessage *)publishData:(id)data toChannel:(NSString *)channel
{
	DDCometMessage *message = [DDCometMessage messageWithChannel:channel];
	message.data = data;
	[self sendMessage:message];
	return message;
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
	NSLog(@"Sending message: %@", message);
	[m_outgoingQueue addObject:message];
	
	if (m_transport == nil)
	{
		m_transport = [[DDCometLongPollingTransport alloc] initWithClient:self];
		[m_transport start];
	}
}

- (void)handleMessage:(DDCometMessage *)message
{
	NSLog(@"Message received: %@", message);
	NSString *channel = message.channel;
	if ([channel hasPrefix:@"/meta/"])
	{
		if ([channel isEqualToString:@"/meta/handshake"])
		{
			if ([message.successful boolValue])
			{
				m_clientID = [message.clientID retain];
				
				[self sendMessage:[DDCometMessage messageWithChannel:@"/meta/connect"]];
				
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
		else if ([channel isEqualToString:@"/meta/connect"])
		{
			if (message.advice)
			{
				[m_advice release];
				m_advice = [message.advice retain];
			}
			if (![message.successful boolValue])
			{
				m_state = DDCometStateDisconnected;
				if (m_delegate && [m_delegate respondsToSelector:@selector(cometClient:connectDidFailWithError:)])
					[m_delegate cometClient:self connectDidFailWithError:message.error];
			}
			else if (m_state == DDCometStateConnecting)
			{
				m_state = DDCometStateConnected;
				if (m_delegate && [m_delegate respondsToSelector:@selector(cometClientConnectDidSucceed:)])
					[m_delegate cometClientConnectDidSucceed:self];
			}
		}
		else if ([channel isEqualToString:@"/meta/disconnect"])
		{
			m_state = DDCometStateDisconnected;
			[m_transport cancel];
			[m_transport release];
			m_transport = nil;
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
			NSLog(@"Unhandled meta message");
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
