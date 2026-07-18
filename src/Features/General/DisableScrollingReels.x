#import "../../Utils.h"
#import "../../InstagramHeaders.h"

%hook IGUnifiedVideoCollectionView

- (void)didMoveToWindow {
    %orig;

    if ([SCIUtils getBoolPref:@"disable_scrolling_reels"]) {
        NSLog(@"[SCInsta] Disabling scrolling reels");

        self.scrollEnabled = NO;
    }
}

- (void)setScrollEnabled:(BOOL)arg1 {
    if ([SCIUtils getBoolPref:@"disable_scrolling_reels"]) {
        NSLog(@"[SCInsta] Disabling scrolling reels");

        %orig(NO);
        return;
    }

    %orig(arg1);
}

%end


// Disable auto-scrolling reels
%hook _TtC19IGSundialAutoScroll19IGSundialAutoScroll

- (void)setIsEnabled:(BOOL)enabled {
    if ([SCIUtils getBoolPref:@"disable_scrolling_reels"]) {
        %orig(NO);
        return;
    }

    %orig(enabled);
}

%end