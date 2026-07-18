// Rewrite Instagram share links — replace domain + optionally strip tracking params.
// Waits for IG's async clipboard write via changeCount, then rewrites once.

#import "../../Utils.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>

static NSString *sciRewriteIGURL(NSString *url) {
    if (!url.length) {
        return url;
    }

    // Domain replacement
    if ([SCIUtils getBoolPref:@"embed_links"]) {
        NSString *domain = [SCIUtils getStringPref:@"embed_link_domain"];

        if (!domain.length) {
            domain = @"kkinstagram.com";
        }

        if (![url containsString:domain]) {
            NSArray *igDomains = @[
                @"www.instagram.com",
                @"instagram.com",
                @"www.instagr.am",
                @"instagr.am"
            ];

            for (NSString *d in igDomains) {
                NSRange range = [url rangeOfString:d];

                if (range.location != NSNotFound) {
                    NSString *target = [d hasPrefix:@"www."]
                        ? [NSString stringWithFormat:@"www.%@", domain]
                        : domain;

                    url = [url stringByReplacingCharactersInRange:range
                                                       withString:target];
                    break;
                }
            }
        }
    }

    // Strip tracking params
    if ([SCIUtils getBoolPref:@"strip_tracking_params"]) {
        NSURLComponents *components = [NSURLComponents componentsWithString:url];

        if (components.queryItems.count) {
            NSArray *stripParams = @[
                @"igsh",
                @"ig_rid",
                @"utm_source",
                @"utm_medium",
                @"utm_campaign"
            ];

            NSMutableArray *cleanItems = [NSMutableArray array];

            for (NSURLQueryItem *item in components.queryItems) {
                if (![stripParams containsObject:item.name]) {
                    [cleanItems addObject:item];
                }
            }

            components.queryItems = cleanItems.count ? cleanItems : nil;

            NSString *result = components.string;

            if (result.length) {
                url = result;
            }
        }
    }

    return url;
}

static BOOL sciShouldRewrite(void) {
    return [SCIUtils getBoolPref:@"embed_links"] ||
           [SCIUtils getBoolPref:@"strip_tracking_params"];
}


// Rewrite clipboard once after IG writes
static void sciPollAndRewrite(NSInteger countBefore, NSInteger polls, double interval) {
    __block BOOL done = NO;

    for (NSInteger i = 0; i < polls; i++) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)((interval + (i * interval)) * NSEC_PER_SEC)
            ),
            dispatch_get_main_queue(),
            ^{
                if (done) {
                    return;
                }

                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

                if (pasteboard.changeCount == countBefore) {
                    return;
                }

                NSString *clip = pasteboard.string;

                if (!clip || ![clip containsString:@"instagram"]) {
                    return;
                }

                NSString *rewritten = sciRewriteIGURL(clip);

                if (![rewritten isEqualToString:clip]) {
                    pasteboard.string = rewritten;
                }

                done = YES;
            }
        );
    }
}


// ============ Hooks ============

static void (*orig_copyLink)(id, SEL, id);

static void new_copyLink(id self, SEL _cmd, id vc) {
    if (!sciShouldRewrite()) {
        orig_copyLink(self, _cmd, vc);
        return;
    }

    NSInteger countBefore = [UIPasteboard generalPasteboard].changeCount;

    orig_copyLink(self, _cmd, vc);

    sciPollAndRewrite(countBefore, 30, 0.05);
}


static void (*orig_shareMore)(id, SEL, id);

static void new_shareMore(id self, SEL _cmd, id vc) {
    if (!sciShouldRewrite()) {
        orig_shareMore(self, _cmd, vc);
        return;
    }

    NSInteger countBefore = [UIPasteboard generalPasteboard].changeCount;

    orig_shareMore(self, _cmd, vc);

    sciPollAndRewrite(countBefore, 120, 0.1);
}


__attribute__((constructor))
static void _embedLinksInit(void) {
    Class cls = NSClassFromString(@"IGExternalShareOptionsViewController");

    if (!cls) {
        return;
    }

    SEL copySelector = NSSelectorFromString(@"_shareToClipboardFromVC:");

    if (class_getInstanceMethod(cls, copySelector)) {
        MSHookMessageEx(
            cls,
            copySelector,
            (IMP)new_copyLink,
            (IMP *)&orig_copyLink
        );
    }


    SEL moreSelector = NSSelectorFromString(@"_shareToMoreFromVC:");

    if (class_getInstanceMethod(cls, moreSelector)) {
        MSHookMessageEx(
            cls,
            moreSelector,
            (IMP)new_shareMore,
            (IMP *)&orig_shareMore
        );
    }
}