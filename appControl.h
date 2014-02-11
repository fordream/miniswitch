/* appControl */

#import <Cocoa/Cocoa.h>

@interface appControl : NSObject
{
    IBOutlet id autoQuitCB;
    IBOutlet id cAppMenu;
    IBOutlet id dockPopUp;
    IBOutlet id mAppMenu;
    IBOutlet id miniSwitchWindow;
    IBOutlet id prefWindow;
    IBOutlet id switchableFiles;
    IBOutlet id symlinkCB;
    IBOutlet id userList;
    IBOutlet id wAppMenu;
    IBOutlet id addSwitchPU;
    IBOutlet id delSwitchBtn;
    IBOutlet id addUserBtn;
    IBOutlet id delUserBtn;
    IBOutlet id switchUserBtn;
    
    NSMutableArray *users;
    NSMutableArray *switches;
    NSFileManager *fileMan;
    NSString *fileManError;
    NSString *miniSwitchPath;
    
    NSMenu *dockUserMenu;
    NSString *currentUser;
    NSMutableArray *runningApps;
    NSMutableArray *relaunchApps;
    NSTimer *quitTimer;
//    NSToolbar *toolbar;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

- (void)refreshDockPopUp;
- (void)prepMSDir;
- (void)reloadUsers;
- (void)readinCurrentUser;
//- (int)currentUserIndex;
- (NSMenuItem *)createItem:(NSString *)name action:(SEL)aSelector;

- (IBAction)switchAndLaunch:(id)sender;
- (void)switchAppDidQuit:(NSNotification *)aNotification;
- (void)quitTimedOut:(NSTimer*)theTimer;
- (void)switchUser;
- (void)launchRelaunchApps;
- (BOOL)fileManager:(NSFileManager *)manager 
    shouldProceedAfterError:(NSDictionary *)errorDict;

- (IBAction)addSwApp:(id)sender;
- (IBAction)AddSwFiles:(id)sender;
- (IBAction)deleteSelectedSw:(id)sender;

- (IBAction)deleteUsers:(id)sender;
- (IBAction)newUser:(id)sender;
- (int)usersIndexForName:(NSString *)name;
- (NSString *)createNewUserWithName:(NSString *)name;

- (IBAction)setQuitOnCloseWindow:(id)sender;
- (IBAction)updateDockDefault:(id)sender;
- (IBAction)updateSymLinkUse:(id)sender;

//*** start Dock Menu selectors ***
- (IBAction)showMiniSwitchWindow:(id)sender;
- (IBAction)openFromDock:(id)sender;
//- (NSMenu *)applicationDockMenu:(NSApplication *)sender;
//*** end Dock Menu selectors ***

//*** start tableview datasource methods ***
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:
    (NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject
    forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn 
    row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell 
    forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
//*** end tableview datasource methods ***

- (void) updateUserWinBtnEnables;

//*** start outlineview datasource methods ***
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:
    (NSTableColumn *)tableColumn byItem:(id)item;
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object 
    forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (void)updateAppSwitchSelected;
- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object;
- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item;
//*** end outlineview datasource methods ***

- (void)windowWillClose:(NSNotification *)aNotification;

/*** start toolbar display methods ***
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString 
    *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
//*** end toolbar display methods ***/
@end
