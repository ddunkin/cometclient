
#import "DDCometLongPollingTransport.h"
#import "DDCometClient.h"
#import "DDCometMessage.h"
#import "DDQueue.h"
#import "JSON.h"


@interface DDCometLongPollingTransport ()

- (NSURLConnection *)sendMessages:(NSArray *)messages;
- (NSArray *)outgoingMessages;
- (NSURLRequest *)requestWithMessages:(NSArray *)messages;
- (id)keyWithConnection:(NSURLConnection *)connection;

@end

@implementation DDCometLongPollingTransport

- (id)initWithClient:(DDCometClient *)client
{
	if ((self = [super init]))
	{
		m_client = [client retain];
		m_responseDatas = [[NSMutableDictionary alloc] initWithCapacity:2];
	}
	return self;
}

- (void)dealloc
{
	[m_responseDatas release];
	[m_client release];
	[super dealloc];
}

- (void)start
{
	[self performSelectorInBackground:@selector(main) withObject:nil];
}

- (void)cancel
{
	m_shouldCancel = YES;
}

#pragma mark -

- (void)main
{
	do
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSArray *messages = [self outgoingMessages];
		
		BOOL isPolling;
		if ([messages count] == 0)
		{
			if (m_client.state == DDCometStateConnected)
			{
				isPolling = YES;
				DDCometMessage *message = [DDCometMessage messageWithChannel:@"/meta/connect"];
				message.clientID = m_client.clientID;
				message.connectionType = @"long-polling";
				NSLog(@"Sending long-poll message: %@", message);
				messages = [NSArray arrayWithObject:message];
			}
			else
			{
				[NSThread sleepForTimeInterval:0.01];
			}
		}
		
		NSURLConnection *connection = [self sendMessages:messages];
		if (connection)
		{
			NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
			while ([runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]])
			{
				if (isPolling)
				{
					if (m_shouldCancel)
					{
						m_shouldCancel = NO;
						[connection cancel];
					}
					else
					{
						messages = [self outgoingMessages];
						[self sendMessages:messages];
					}
				}
			}
		}
		[pool release];
	} while (m_client.state != DDCometStateDisconnected);
}

- (NSURLConnection *)sendMessages:(NSArray *)messages
{
	NSURLConnection *connection = nil;
	if ([messages count] != 0)
	{
		NSURLRequest *request = [self requestWithMessages:messages];
		connection = [NSURLConnection connectionWithRequest:request delegate:self];
		if (connection)
		{
			NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
			[connection scheduleInRunLoop:runLoop forMode:[runLoop currentMode]];
			[connection start];
		}
	}
	return connection;
}

- (NSArray *)outgoingMessages
{
	NSMutableArray *messages = [NSMutableArray array];
	DDCometMessage *message;
	id<DDQueue> outgoingQueue = [m_client outgoingQueue];
	while ((message = [outgoingQueue removeObject]))
		[messages addObject:message];
	return messages;
}

- (NSURLRequest *)requestWithMessages:(NSArray *)messages
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:m_client.endpointURL];
	
	SBJsonWriter *jsonWriter = [[SBJsonWriter alloc] init];    
    NSData *body = [jsonWriter dataWithObject:messages];
    [jsonWriter release];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/json;charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:body];
	
	NSNumber *timeout = [m_client.advice objectForKey:@"timeout"];
	if (timeout)
		[request setTimeoutInterval:([timeout floatValue] / 1000)];
	
	return request;
}

- (id)keyWithConnection:(NSURLConnection *)connection
{
	return [NSNumber numberWithUnsignedInteger:[connection hash]];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[m_responseDatas setObject:[NSMutableData data] forKey:[self keyWithConnection:connection]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSMutableData *responseData = [m_responseDatas objectForKey:[self keyWithConnection:connection]];
	[responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSData *responseData = [[m_responseDatas objectForKey:[self keyWithConnection:connection]] retain];
	[m_responseDatas removeObjectForKey:[self keyWithConnection:connection]];
	
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *responses = [parser objectWithData:responseData];
	[parser release];
	parser = nil;
	[responseData release];
	responseData = nil;
	
	id<DDQueue> incomingQueue = [m_client incomingQueue];
	
	for (NSDictionary *messageData in responses)
	{
		DDCometMessage *message = [DDCometMessage messageWithJson:messageData];
		[incomingQueue addObject:message];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[m_responseDatas removeObjectForKey:[self keyWithConnection:connection]];
}

@end
