// MARK: - Home tab refresh

%hook IGTabBarController

- (void)_timelineButtonPressed {
    BOOL noRefresh = sciDisableHomeRefresh();
    BOOL noScroll = sciDisableHomeScroll();

    if (!noRefresh && !noScroll) {
        %orig;
        return;
    }

    UIViewController *selected = nil;
    if ([self respondsToSelector:@selector(selectedViewController)]) {
        selected = [self valueForKey:@"selectedViewController"];
    }

    BOOL onFeedTab = NO;

    if (selected) {
        UIViewController *top =
            [selected isKindOfClass:[UINavigationController class]]
            ? [(UINavigationController *)selected topViewController]
            : selected;

        onFeedTab = [NSStringFromClass([top class]) containsString:@"MainFeed"];
    }

    if (!onFeedTab) {
        %orig;
        return;
    }

    if (noRefresh && !noScroll) {
        return;
    }

    UIViewController *top =
        [selected isKindOfClass:[UINavigationController class]]
        ? [(UINavigationController *)selected topViewController]
        : selected;

    if (!top.view) {
        return;
    }

    NSMutableArray *queue = [NSMutableArray arrayWithObject:top.view];

    int scanned = 0;

    while (queue.count && scanned < 30) {
        UIView *cur = queue.firstObject;
        [queue removeObjectAtIndex:0];

        scanned++;

        if ([cur isKindOfClass:[UICollectionView class]]) {
            UICollectionView *cv = (UICollectionView *)cur;

            [cv setContentOffset:
                CGPointMake(0, -cv.adjustedContentInset.top)
                animated:YES];

            return;
        }

        for (UIView *sub in cur.subviews) {
            [queue addObject:sub];
        }
    }
}


// MARK: - Reels tab refresh

- (void)_discoverVideoButtonPressed {

    if (!sciDisableReelsRefresh()) {
        %orig;
        return;
    }

    UIViewController *selected = nil;

    if ([self respondsToSelector:@selector(selectedViewController)]) {
        selected = [self valueForKey:@"selectedViewController"];
    }

    BOOL onReelsTab = NO;

    if (selected) {
        UIViewController *top =
            [selected isKindOfClass:[UINavigationController class]]
            ? [(UINavigationController *)selected topViewController]
            : selected;

        NSString *cls = NSStringFromClass([top class]);

        onReelsTab =
            [cls containsString:@"Sundial"] ||
            [cls containsString:@"Reels"] ||
            [cls containsString:@"DiscoverVideo"];
    }

    if (!onReelsTab) {
        %orig;
        return;
    }

    // Block refresh but keep tab switching.
}

%end