
#import "MainViewController.h"
#import "DDCometClient.h"
#import "DDCometMessage.h"


@implementation MainViewController

@synthesize textView = m_textView,
	textField = m_textField;

- (void)dealloc
{
	[m_client release];
	[super dealloc];
}

- (void)viewDidLoad
{
	if (m_client == nil)
	{
		m_client = [[DDCometClient alloc] initWithURL:[NSURL URLWithString:@"http://localhost:8080/cometd"]];
		m_client.delegate = self;
		[m_client scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[m_client handshake];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[m_textField becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:m_textField.text, @"chat", @"iPhone user", @"user", nil];
	[m_client publishData:data toChannel:@"/chat/demo"];
	
	m_textField.text = @"";
	return YES;
}

- (void)appendText:(NSString *)text
{
	m_textView.text = [m_textView.text stringByAppendingFormat:@"%@\n", text];
}

#pragma mark -

- (void)cometClientHandshakeDidSucceed:(DDCometClient *)client
{
	NSLog(@"Handshake succeeded");

	[self appendText:@"[connected]"];
	
	[client subscribeToChannel:@"/chat/demo" target:self selector:@selector(chatMessageReceived:)];
	[client subscribeToChannel:@"/members/demo" target:self selector:@selector(membershipMessageReceived:)];
	
	NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:@"/chat/demo", @"room", @"iPhone user", @"user", nil];
	[m_client publishData:data toChannel:@"/service/members"];
}

- (void)cometClient:(DDCometClient *)client handshakeDidFailWithError:(NSError *)error
{
	NSLog(@"Handshake failed");
}

- (void)cometClientConnectDidSucceed:(DDCometClient *)client
{
	NSLog(@"Connect succeeded");
}

- (void)cometClient:(DDCometClient *)client connectDidFailWithError:(NSError *)error
{
	NSLog(@"Connect failed");
}

- (void)cometClient:(DDCometClient *)client subscriptionDidSucceed:(DDCometSubscription *)subscription
{
	NSLog(@"Subsription succeeded");
}

- (void)cometClient:(DDCometClient *)client subscription:(DDCometSubscription *)subscription didFailWithError:(NSError *)error
{
	NSLog(@"Subsription failed");
}

- (void)chatMessageReceived:(DDCometMessage *)message
{
	if (message.successful == nil)
		[self appendText:[NSString stringWithFormat:@"%@: %@", [message.data objectForKey:@"user"], [message.data objectForKey:@"chat"]]];
	else if (![message.successful boolValue])
		[self appendText:@"Unable to send message"];
}

- (void)membershipMessageReceived:(DDCometMessage *)message
{
	if ([message.data isKindOfClass:[NSDictionary class]])
		[self appendText:[NSString stringWithFormat:@"[%@ are in the chat]", [message.data objectForKey:@"user"]]];
	if ([message.data isKindOfClass:[NSArray class]])
		[self appendText:[NSString stringWithFormat:@"[%@ are in the chat]", [message.data componentsJoinedByString:@", "]]];
}

@end
