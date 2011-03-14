//
//  MainViewController.m
//  CometClient
//
//  Created by Dave Dunkin on 3/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "DDCometClient.h"
#import "DDCometMessage.h"


@implementation MainViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	DDCometClient *client = [[DDCometClient alloc] initWithURL:[NSURL URLWithString:@"http://localhost:8080/cometd"]];
	client.delegate = self;
	[client handshake:NULL];
}

- (void)cometClientHandshakeDidSucceed:(DDCometClient *)client
{
	NSLog(@"Handshake succeeded");
	[client subscribeToChannel:@"/chat/demo" target:self selector:@selector(chatMessageReceived:) error:NULL];
	[client subscribeToChannel:@"/members/demo" target:self selector:@selector(membershipMessageReceived:) error:NULL];
}

- (void)cometClient:(DDCometClient *)client handshakeDidFailWithError:(NSError *)error
{
	NSLog(@"Handshake failed");
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
	NSLog(@"%@: %@", [message.data objectForKey:@"user"], [message.data objectForKey:@"chat"]);
}

- (void)membershipMessageReceived:(DDCometMessage *)message
{
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{    
    FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    controller.delegate = self;
    
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
    
    [controller release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [super dealloc];
}

@end
