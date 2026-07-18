#import "../../Utils.h"
#import "../../InstagramHeaders.h"

%hook IGFollowController

- (void)_didPressFollowButton {
    NSInteger status = self.user.followStatus;

    if (status == 2 && [SCIUtils getBoolPref:@"follow_confirm"]) {
        NSLog(@"[SCInsta] Confirm follow triggered");

        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}

- (void)_performUnfollow {
    if ([SCIUtils getBoolPref:@"unfollow_confirm"]) {

        [SCIUtils showConfirmation:^{
            %orig;
        } title:SCILocalized(@"Unfollow?")];

    } else {
        %orig;
    }
}

%end


%hook IGDiscoverPeopleButtonGroupView

- (void)_onFollowButtonTapped:(id)arg1 {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {
        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}


- (void)_onFollowingButtonTapped:(id)arg1 {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {
        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}

%end


%hook IGHScrollAYMFCell

- (void)_didTapAYMFActionButton {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {
        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}

%end


%hook IGHScrollAYMFActionButton

- (void)_didTapTextActionButton {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {
        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}

%end


%hook IGUnifiedVideoFollowButton

- (void)_hackilyHandleOurOwnButtonTaps:(id)arg1 event:(id)arg2 {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {
        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}

%end


%hook IGProfileViewController

- (void)navigationItemsControllerDidTapHeaderFollowButton:(id)arg1 {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {
        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}

%end


%hook IGStorySectionController

- (void)followButtonTapped:(id)arg1 cell:(id)arg2 {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {
        [SCIUtils showConfirmation:^{
            %orig;
        }];
    } else {
        %orig;
    }
}

%end


static void (*orig_listSectionController)(id, SEL, id, id);

static void hooked_listSectionController(id self, SEL _cmd, id arg1, id arg2) {

    if ([SCIUtils getBoolPref:@"follow_confirm"]) {

        [SCIUtils showConfirmation:^{
            orig_listSectionController(self, _cmd, arg1, arg2);
        }];

        return;
    }

    orig_listSectionController(self, _cmd, arg1, arg2);
}


%ctor {

    Class cls = objc_getClass(
        "IGDirectDetailMembersKit.IGDirectThreadDetailsMembersListViewController"
    );

    if (!cls)
        return;


    MSHookMessageEx(
        cls,
        @selector(listSectionController:didTapHeaderButtonWithViewModel:),
        (IMP)hooked_listSectionController,
        (IMP *)&orig_listSectionController
    );
}