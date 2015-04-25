#import <objc/runtime.h>
#import <ColorLog.h>
#import "../AASpringRefresh/AASpringRefresh/AASpringRefresh.h"

// interfaces {{{
@interface SBBulletinViewController : UIViewController
@end

@interface SBNotificationCenterController
@property(retain) UIViewController *viewController;
+ (id)sharedInstance;
@end

@interface SBBulletinObserverViewController
- (id)sectionWithIdentifier:(NSString *)identifier;
- (void)clearSection:(id)section;
@end

@interface SBIcon
- (void)setBadge:(id)value;
- (id)badgeNumberOrString;
@end

@interface SBIconModel
- (SBIcon *)applicationIconForBundleIdentifier:(NSString *)bundleIdentifier; //iOS 8
@end

@interface SBIconViewMap
+ (SBIconViewMap *)homescreenMap;
- (SBIconModel *)iconModel;
@end
// }}}

// Inherited from https://github.com/autopear/Notification-Killer/blob/master/Tweak.mm#L118
static void ClearAllBulletin()
{
    SBNotificationCenterController *self = [objc_getClass("SBNotificationCenterController") sharedInstance];
    SBBulletinObserverViewController *allCtrl = MSHookIvar<SBBulletinObserverViewController *>(self.viewController, "_allModeViewController");

    NSMutableArray *_visibleSectionIDs = MSHookIvar<NSMutableArray *>(allCtrl, "_visibleSectionIDs");
    NSArray *allSections = [NSArray arrayWithArray:_visibleSectionIDs];
    for (NSString *identifier in allSections) {
        id sectionInfo = [allCtrl sectionWithIdentifier:identifier];
        if (sectionInfo)
            [allCtrl clearSection:sectionInfo];

        SBIconModel *iconModel = (SBIconModel *)[(SBIconViewMap *)[%c(SBIconViewMap) homescreenMap] iconModel];
        if (iconModel) {
            SBIcon *appIcon = [iconModel applicationIconForBundleIdentifier:identifier];
            if (appIcon && [appIcon badgeNumberOrString])
                [appIcon setBadge:nil];
        }
    }
}

static void SetPullView(UITableView *tableView, AASpringRefreshPosition position)
{
    AASpringRefresh *pull = [tableView addSpringRefreshPosition:position actionHandler:^() {
        ClearAllBulletin();
    }];
    pull.expandedColor = [UIColor whiteColor];
    pull.readyColor = [UIColor orangeColor];
    pull.text = @"MarkAllasRead";
}

%hook SBBulletinViewController
- (void)viewDidLoad
{
    %orig;
    // avoid SBWidgetHandlingBulletinViewController
    if (![self isMemberOfClass:%c(SBBulletinViewController)]) {
        return;
    }
    UITableView *tableView = (UITableView *)self.view;

    SetPullView(tableView, AASpringRefreshPositionTop);
    SetPullView(tableView, AASpringRefreshPositionBottom);
}
%end
