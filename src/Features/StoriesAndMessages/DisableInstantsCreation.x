#import "../../Utils.h"

// Demangled name: IGQuickSnapExperimentation.IGQuickSnapExperimentationHelper
%hook _TtC26IGQuickSnapExperimentation32IGQuickSnapExperimentationHelper

+ (_Bool)isQuicksnapEnabled:(id)enabled {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

+ (_Bool)isQuicksnapEnabledInFeed:(id)feed {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

+ (_Bool)isQuicksnapEnabledInInbox:(id)inbox {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

+ (_Bool)isQuicksnapEnabledInStories:(id)stories {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

+ (_Bool)isQuicksnapEnabledInNotesTray:(id)tray {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

+ (_Bool)isQuicksnapEnabledInNotesTrayWithPeek:(id)peek {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

+ (_Bool)isQuicksnapEnabledInNotesTrayWithPog:(id)pog {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

+ (_Bool)isQuicksnapNotesTrayEmptyPogEnabled:(id)enabled {
    if ([SCIUtils getBoolPref:@"disable_instants_creation"]) {
        return false;
    }
    return %orig;
}

%end

// %hook IGDirectNotesTrayRowCell
// - (_Bool)isQuicksnapPeekVisible {
//     return true;
// }
// %end

// %hook IGDirectNotesTrayRowSectionController
// - (_Bool)isQuicksnapPeekVisible {
//     return true;
// }
// %end