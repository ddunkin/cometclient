
#import "DDCometClientOperation.h"
#import "DDCometClient.h"
#import "DDCometMessage.h"
#import "DDQueue.h"
#import "JSON.h"


@interface DDCometClientOperation ()

- (NSURLRequest *)requestWithMessages:(NSArray *)messages;

@end

@implementation DDCometClientOperation

- (id)initWithClient:(DDCometClient *)client
{
	if ((self = [super init]))
	{
		m_client = [client retain];
	}
	return self;
}

- (void)dealloc
{
	[m_client release];
	[super dealloc];
}

- (void)main
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableArray *messages = [NSMutableArray array];
	DDCometMessage *message;
	id<DDQueue> outgoingQueue = [m_client outgoingQueue];
	while ((message = [outgoingQueue removeObject]))
		[messages addObject:message];
	
	if ([messages count] == 0)
	{
		message = [DDCometMessage messageWithChannel:@"/meta/connect"];
		message.clientID = m_client.clientID;
		message.connectionType = @"long-polling";
		[messages addObject:message];
	}
	NSURLRequest *request = [self requestWithMessages:messages];
	
	NSURLConnection *connection = [NSURLConnection connectionWithRequest:request delegate:self];
	if (connection)
	{
		NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
		[connection scheduleInRunLoop:runLoop forMode:[runLoop currentMode]];
		[connection start];
		[runLoop run];
	}
	
	[m_client operationDidFinish:self];
	
	[pool release];
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
	
	return request;
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	m_responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[m_responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	NSArray *responses = [parser objectWithData:m_responseData];
	[parser release];
	parser = nil;
	[m_responseData release];
	m_responseData = nil;
	
	id<DDQueue> incomingQueue = [m_client incomingQueue];
	
	for (NSDictionary *messageData in responses)
	{
		DDCometMessage *message = [DDCometMessage messageWithJson:messageData];
		[incomingQueue addObject:message];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
}

@end
