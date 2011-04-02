
#import "DDCometMessage.h"

@interface NSDate (ISO8601)

+ (NSDate *)dateWithISO8601String:(NSString *)string;
- (NSString *)ISO8601Representation;

@end

@implementation NSDate (ISO8601)

+ (NSDate *)dateWithISO8601String:(NSString *)string
{
	NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
	[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	return [fmt dateFromString:string];
}

- (NSString *)ISO8601Representation
{
	NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
	[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	return [fmt stringFromDate:self];
}

@end

@interface NSError (Bayeux)

+ (NSError *)errorWithBayeuxFormat:(NSString *)string;
- (NSString *)bayeuxFormat;

@end

@implementation NSError (Bayeux)

+ (NSError *)errorWithBayeuxFormat:(NSString *)string
{
	NSArray *components = [string componentsSeparatedByString:@":"];
	NSInteger code = [[components objectAtIndex:0] integerValue];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[components objectAtIndex:2], NSLocalizedDescriptionKey, nil];
	return [[[NSError alloc] initWithDomain:@"" code:code userInfo:userInfo] autorelease];
}

- (NSString *)bayeuxFormat
{
	NSString *args = @"";
	NSArray *components = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%d", [self code]], args, [self localizedDescription], nil];
	return [components componentsJoinedByString:@":"];
}

@end

@implementation DDCometMessage

@synthesize channel = m_channel,
	version = m_version,
	minimumVersion = m_minimumVersion,
	supportedConnectionTypes = m_supportedConnectionTypes,
	clientID = m_clientID,
	advice = m_advice,
	connectionType = m_connectionType,
	ID = m_ID,
	timestamp = m_timestamp,
	data = m_data,
	successful = m_successful,
	subscription = m_subscription,
	error = m_error,
	ext = m_ext;

- (void)dealloc
{
    [m_channel release];
	[m_version release];
	[m_minimumVersion release];
	[m_supportedConnectionTypes release];
	[m_clientID release];
	[m_advice release];
	[m_connectionType release];
	[m_ID release];
	[m_timestamp release];
	[m_data release];
	[m_successful release];
	[m_subscription release];
	[m_error release];
	[m_ext release];
    [super dealloc];
}

+ (DDCometMessage *)messageWithChannel:(NSString *)channel
{
	DDCometMessage *message = [[[DDCometMessage alloc] init] autorelease];
	message.channel = channel;
	return message;
}

@end

@implementation DDCometMessage (JSON)

+ (DDCometMessage *)messageWithJson:(NSDictionary *)jsonData
{
	DDCometMessage *message = [[[DDCometMessage alloc] init] autorelease];
	for (NSString *key in [jsonData keyEnumerator])
	{
		id object = [jsonData objectForKey:key];
		
		if ([key isEqualToString:@"channel"])
			message.channel = object;
		else if ([key isEqualToString:@"version"])
			message.version = object;
		else if ([key isEqualToString:@"minimumVersion"])
			message.minimumVersion = object;
		else if ([key isEqualToString:@"supportedConnectionTypes"])
			message.supportedConnectionTypes = object;
		else if ([key isEqualToString:@"clientId"])
			message.clientID = object;
		else if ([key isEqualToString:@"advice"])
			message.advice = object;
		else if ([key isEqualToString:@"connectionType"])
			message.connectionType = object;
		else if ([key isEqualToString:@"id"])
			message.ID = object;
		else if ([key isEqualToString:@"timestamp"])
			message.timestamp = [NSDate dateWithISO8601String:object];
		else if ([key isEqualToString:@"data"])
			message.data = object;
		else if ([key isEqualToString:@"successful"])
			message.successful = object;
		else if ([key isEqualToString:@"subscription"])
			message.subscription = object;
		else if ([key isEqualToString:@"error"])
			message.error = [NSError errorWithBayeuxFormat:object];
		else if ([key isEqualToString:@"ext"])
			message.ext = object;
	}
	return message;
}

- (NSDictionary *)proxyForJson
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	if (m_channel)
		[dict setObject:m_channel forKey:@"channel"];
	if (m_version)
		[dict setObject:m_version forKey:@"version"];
	if (m_minimumVersion)
		[dict setObject:m_minimumVersion forKey:@"minimumVersion"];
	if (m_supportedConnectionTypes)
		[dict setObject:m_supportedConnectionTypes forKey:@"supportedConnectionTypes"];
	if (m_clientID)
		[dict setObject:m_clientID forKey:@"clientId"];
	if (m_advice)
		[dict setObject:m_advice forKey:@"advice"];
	if (m_connectionType)
		[dict setObject:m_connectionType forKey:@"connectionType"];
	if (m_ID)
		[dict setObject:m_ID forKey:@"id"];
	if (m_timestamp)
		[dict setObject:[m_timestamp ISO8601Representation] forKey:@"timestamp"];
	if (m_data)
		[dict setObject:m_data forKey:@"data"];
	if (m_successful)
		[dict setObject:m_successful forKey:@"successful"];
	if (m_subscription)
		[dict setObject:m_subscription forKey:@"subscription"];
	if (m_error)
		[dict setObject:[m_error bayeuxFormat] forKey:@"error"];
	if (m_ext)
		[dict setObject:m_ext forKey:@"ext"];
	return dict;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@", [super description], [self proxyForJson]];
}

@end
