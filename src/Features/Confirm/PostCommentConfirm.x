#import "../../InstagramHeaders.h"
#import "../../Utils.h"

%hook IGCommentComposer.IGCommentComposerController

- (void)onSendButtonTap {

    if ([SCIUtils getBoolPref:@"post_comment_confirm"]) {

        NSLog(@"[SCInsta] Confirm comment post triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}

%end