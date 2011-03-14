//
//  MainViewController.h
//  CometClient
//
//  Created by Dave Dunkin on 3/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import "DDCometClient.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, DDCometClientDelegate> {

}


- (IBAction)showInfo:(id)sender;

@end
