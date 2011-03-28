
#import "DDCometClient.h"

@interface MainViewController : UIViewController <UITextFieldDelegate, DDCometClientDelegate>
{
@private
	DDCometClient *m_client;
	UITextView *m_textView;
	UITextField *m_textField;
}

@property (nonatomic, assign) IBOutlet UITextView *textView;
@property (nonatomic, assign) IBOutlet UITextField *textField;

@end
