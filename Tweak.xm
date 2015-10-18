#import <ColorLog.h>
#import "../AASpringRefresh/AASpringRefresh/AASpringRefresh.h"

// interfaces {{{
@interface SBBulletinViewController : UIViewController

@property(nonatomic, assign) id delegate;

@end

@interface SBNotificationCenterViewController
@property(readonly, nonatomic) NSSet *visibleContentViewControllers;
@end

@interface SBNotificationCenterController
@property(retain) SBNotificationCenterViewController *viewController;
+ (id)sharedInstance;
@end

@interface SBBulletinObserverViewController
@property(readonly, nonatomic) NSArray *orderedSectionIDs;
- (id)sectionWithIdentifier:(NSString *)identifier;
- (void)clearSection:(id)section;
- (BOOL)canShowPullToRefresh; //This should be added in the respective observer controllers which want to controll the PullBulletin.
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
    NSArray *allSections;
    SBBulletinObserverViewController *allCtrl;
    SBNotificationCenterController *self = [%c(SBNotificationCenterController) sharedInstance];
    NSSet *s = self.viewController.visibleContentViewControllers;
    // Set of SBBulletinObserverViewController subclass.
    for (id vc in s) {
        if ([vc isKindOfClass:%c(SBBulletinObserverViewController)]) {
            allCtrl = vc;
            allSections = allCtrl.orderedSectionIDs;
            break;
        }
    }

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

%group NCGroup
%hook BulletinVC
- (void)viewDidLoad
{
    %orig;
    // iOS 8: SBWidgetHandlingBulletinViewController and SBBulletinViewController
    // iOS 9: SBWidgetHandlingNCTableViewController and SBNCTableViewController
    if ([self respondsToSelector:@selector(visibleWidgetIDs)] || ([[self delegate] respondsToSelector:@selector(canShowPullToRefresh)] && ![[self delegate] canShowPullToRefresh])) {
        return;
    }
    UITableView *tableView = (UITableView *)[(UIViewController *)self view];

    SetPullView(tableView, AASpringRefreshPositionTop);
    SetPullView(tableView, AASpringRefreshPositionBottom);
}
%end
%end

%ctor {
    @autoreleasepool {
        Class $BulletinVC = objc_getClass("SBNCTableViewController") ?: objc_getClass("SBBulletinViewController");
        %init(NCGroup, BulletinVC = $BulletinVC);
    }
}
