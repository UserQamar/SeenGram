#import "../../Utils.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>

typedef void (*SciHandleTapFn)(Class, SEL, id, id, BOOL);
typedef void (*SciHandleTapCompFn)(Class, SEL, id, id, BOOL, id);

static SciHandleTapFn orig_sciHandleTap = NULL;
static SciHandleTapCompFn orig_sciHandleTapComp = NULL;


static void sciConfirmAction(BOOL enabled, void (^action)(void)) {
    if (enabled) {
        [SCIUtils showConfirmation:^{
            action();
        }];
    } else {
        action();
    }
}



static void new_sciHandleTap(Class cls, SEL _cmd, id ctx, id btn, BOOL anim) {

    if (![SCIUtils getBoolPref:@"like_confirm_reels"]) {
        orig_sciHandleTap(cls, _cmd, ctx, btn, anim);
        return;
    }

    __strong id sCtx = ctx;
    __strong id sBtn = btn;

    [SCIUtils showConfirmation:^{
        @try {
            orig_sciHandleTap(cls, _cmd, sCtx, sBtn, anim);
        }
        @catch (__unused id e) {}
    }];
}



static void new_sciHandleTapComp(Class cls, SEL _cmd, id ctx, id btn, BOOL anim, id comp) {

    if (![SCIUtils getBoolPref:@"like_confirm_reels"]) {
        orig_sciHandleTapComp(cls, _cmd, ctx, btn, anim, comp);
        return;
    }

    __strong id sCtx = ctx;
    __strong id sBtn = btn;
    id sComp = comp ? [comp copy] : nil;

    [SCIUtils showConfirmation:^{
        @try {
            orig_sciHandleTapComp(cls, _cmd, sCtx, sBtn, anim, sComp);
        }
        @catch (__unused id e) {}
    }];
}



__attribute__((constructor))
static void _sciHookReelsLikeHandler(void) {

    Class c = NSClassFromString(@"_TtC30IGSundialOverlayActionHandlers38IGSundialViewerLikeButtonActionHandler");

    if (!c)
        return;

    Class meta = object_getClass(c);

    SEL s1 = NSSelectorFromString(@"handleTapWithActionContext:likeButton:willPlayRingsCustomLikeAnimation:");
    SEL s2 = NSSelectorFromString(@"handleTapWithActionContext:likeButton:willPlayRingsCustomLikeAnimation:completion:");

    if (class_getClassMethod(c, s1)) {
        MSHookMessageEx(meta, s1, (IMP)new_sciHandleTap, (IMP *)&orig_sciHandleTap);
    }

    if (class_getClassMethod(c, s2)) {
        MSHookMessageEx(meta, s2, (IMP)new_sciHandleTapComp, (IMP *)&orig_sciHandleTapComp);
    }
}



%hook IGUFIButtonBarView

- (void)_onLikeButtonPressed:(id)arg1 {
    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

- (void)_onLikeButtonPressed {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

%end



%hook IGFeedPhotoView

- (void)_onDoubleTap:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

- (void)_onDoubleTap {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

%end



%hook IGVideoPlayerOverlayContainerView

- (void)_handleDoubleTapGesture:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

%end



%hook IGSundialViewerVideoCell

- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

%end



%hook IGSundialViewerPhotoCell

- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

- (void)swift_photoCell:(id)arg1 didObserveDoubleTapWithLocationInfo:(id)arg2 gestureRecognizer:(id)arg3 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

%end



%hook IGSundialViewerCarouselCell

- (void)controlsOverlayControllerDidTapLikeButton:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

- (void)gestureController:(id)arg1 didObserveDoubleTap:(id)arg2 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

- (void)carouselCell:(id)arg1 didObserveDoubleTapWithLocationInfo:(id)arg2 gestureRecognizer:(id)arg3 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm_reels"], ^{
        %orig;
    });
}

%end



%hook IGCommentCellController

- (void)commentCell:(id)arg1 didTapLikeButton:(id)arg2 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

- (void)commentCell:(id)arg1 didTapLikedByButtonForUser:(id)arg2 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

- (void)commentCellDidLongPressOnLikeButton:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

- (void)commentCellDidEndLongPressOnLikeButton:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

- (void)commentCellDidDoubleTap:(id)arg1 {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

%end



%hook IGFeedItemPreviewCommentCell

- (void)_didTapLikeButton {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

%end



%hook IGDirectThreadViewController

- (void)_didTapLikeButton {

    sciConfirmAction([SCIUtils getBoolPref:@"like_confirm"], ^{
        %orig;
    });
}

%end