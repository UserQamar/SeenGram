#import "../../InstagramHeaders.h"
#import "../../Utils.h"

%hook IGDirectDisappearingModeSwipeHandler

- (void)handleBottomSwipeableScrollUpdate {

    if ([SCIUtils getBoolPref:@"shh_confirm"]) {

        NSLog(@"[SCInsta] Confirm disappearing mode swipe triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];

    } else {

        %orig;

    }
}


- (id)getSwipeableScrollHintTextInfo {

    if ([SCIUtils getBoolPref:@"shh_confirm"]) {

        NSLog(@"[SCInsta] Confirm disappearing mode hint triggered");

        __block id result = nil;

        [SCIUtils showConfirmation:^{
            result = %orig;
        }];

        return result;

    } else {

        return %orig;

    }
}

%end