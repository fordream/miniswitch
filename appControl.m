#import "appControl.h"
#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>

//#include <sys/types.h>
//#include <sys/stat.h>

#define NSAppKitVersionNumber10_1 620
#define NSAppKitVersionNumber10_2 663

#define kFixedDockMenuAppKitVersion 632

static NSString *JHDAutoQuit = @"Auto Quit On Close";
static NSString *JHDDockDefault = @"Default Dock Application";
static NSString *JHDSwitchArray = @"Switch Array";
static NSString *JHDSwitchApp = @"Switchable Application";
static NSString *JHDAppFiles = @"Switchable Application's Files";
static NSString *JHDSwitchFile = @"Switchable File";
static NSString *JHDSwitchSelected = @"Switchable Item Selected";
static NSString *JHDSymLinkUse = @"Use Symbolic Links";

@implementation appControl

+ (void)initialize
{
    //Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    // Put defaults in the dictionary
    [defaultValues setObject:[NSNumber numberWithInt:0] 
        forKey:JHDAutoQuit];
    [defaultValues setObject:[NSNumber numberWithInt:0] 
        forKey:JHDSymLinkUse];
    [defaultValues setObject:[NSString stringWithString:@"Mail.app"] 
        forKey:JHDDockDefault];
    [defaultValues setObject: [NSMutableArray arrayWithObjects:
	[NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"Mail.app", [NSMutableArray arrayWithObjects:
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Preferences/com.apple.mail.plist", 
		[NSNumber numberWithInt:1], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]],
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Mail", 
		[NSNumber numberWithInt:1], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]],
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Mail Downloads", 
		[NSNumber numberWithInt:0], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]], nil], 
		[NSNumber numberWithInt:-1], nil] 
	    forKeys:[NSMutableArray arrayWithObjects:JHDSwitchApp, JHDAppFiles, JHDSwitchSelected, nil]],
	    
	[NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"Address Book.app", [NSMutableArray arrayWithObjects:
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Preferences/com.apple.AddressBook.plist", 
		[NSNumber numberWithInt:0], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]],
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Application Support/AddressBook", 
		[NSNumber numberWithInt:0], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]],
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Address Book Plug-Ins", 
		[NSNumber numberWithInt:0], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]], nil], 
		[NSNumber numberWithInt:0], nil] 
	    forKeys:[NSMutableArray arrayWithObjects:JHDSwitchApp, JHDAppFiles, JHDSwitchSelected, nil]],
	    
	[NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"iCal.app", [NSMutableArray arrayWithObjects:
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Preferences/com.apple.iCal.plist", 
		[NSNumber numberWithInt:0], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]],
	    [NSMutableDictionary dictionaryWithObjects:[NSMutableArray arrayWithObjects: @"~/Library/Application Support/iCal", 
		[NSNumber numberWithInt:0], nil] forKeys:[NSMutableArray 
		arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]], nil], 
		[NSNumber numberWithInt:0], nil] 
	    forKeys:[NSMutableArray arrayWithObjects:JHDSwitchApp, JHDAppFiles, JHDSwitchSelected, nil]],
	nil] forKey:JHDSwitchArray];

    // Register the dictionary defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];
}

- (id)init
{
    NSDictionary *tempAppDict;
    NSArray *tempFileArr;
    NSDictionary *tempFileDict;
    NSMutableArray *mutFileArr;
    int i, j;
    
    if (self = [super init]) {
	users = [[NSMutableArray alloc] init];
	switches = [[NSMutableArray alloc] init];
	
	for (i = 0; i < [[[NSUserDefaults standardUserDefaults] arrayForKey:JHDSwitchArray] count]; i++) {
	    tempAppDict = [[[NSUserDefaults standardUserDefaults] arrayForKey:JHDSwitchArray] objectAtIndex:i];
	    [switches addObject:[NSMutableDictionary dictionaryWithDictionary:tempAppDict]];
	    tempFileArr = [[switches objectAtIndex:i] objectForKey:JHDAppFiles];
	    mutFileArr = [[NSMutableArray alloc] init];
	    for (j = 0; j < [tempFileArr count]; j++) {
		tempFileDict = [tempFileArr objectAtIndex:j];
		[mutFileArr addObject:[tempFileDict mutableCopy]];
	    }
	    [[switches objectAtIndex:i] setObject:mutFileArr forKey:JHDAppFiles];
	    [mutFileArr release];
	} 
//	NSLog(@"switches has class %@ and is \n%@", [switches className], [switches description]);

	fileMan = [NSFileManager defaultManager];
	fileManError = [[NSString alloc] initWithString:@""];
	miniSwitchPath = [[NSString alloc] initWithString:[[NSHomeDirectory() 
	    stringByAppendingPathComponent:@"Library"] 
	    stringByAppendingPathComponent:@"MiniSwitch"]];
	
	dockUserMenu = [[NSMenu alloc] initWithTitle:@"DockMenu"];
        [dockUserMenu setAutoenablesItems:NO];
	[dockPopUp setAutoenablesItems:NO];
	runningApps = [[NSMutableArray alloc] init];
	relaunchApps = [[NSMutableArray alloc] init];
	
//	toolbar = [[NSToolbar alloc] initWithIdentifier:@"msToolbar"];
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
            selector:@selector(switchAppDidQuit:) 
            name:NSWorkspaceDidTerminateApplicationNotification object:nil]; 
        
        currentUser = nil;
    }
    return self;
}

- (void) dealloc {
    [users release];
    [switches release];
    [miniSwitchPath release];
    [dockUserMenu release];
    [runningApps release];
    [relaunchApps release];
//    [toolbar release];
    [fileManError release];
    [super dealloc];
}

- (void)awakeFromNib
{
    int row;
    [self prepMSDir];
        
/*    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    [miniSwitchWindow setToolbar:toolbar]; */
    
    // prepare prefWindow
    [autoQuitCB setState:[[NSUserDefaults standardUserDefaults] boolForKey:JHDAutoQuit]];
    [symlinkCB setState:[[NSUserDefaults standardUserDefaults] boolForKey:JHDSymLinkUse]];
    
    row = [users indexOfObject:currentUser];
    if (row != NSNotFound) {
        [userList selectRow:row byExtendingSelection:NO];
    }
    
    [addSwitchPU setAutoenablesItems:YES];
    [switchableFiles setAutosaveExpandedItems:YES];
    [[[switchableFiles tableColumnWithIdentifier:@"selects"] dataCell] setAllowsMixedState:YES];
    [self updateUserWinBtnEnables];
    [switchableFiles reloadData];
    [self refreshDockPopUp];
    
    // set tooltips
    [addUserBtn setToolTip:NSLocalizedString(@"addUserTT", nil)];
    [delUserBtn setToolTip:NSLocalizedString(@"delUserTT", nil)];
    [switchUserBtn setToolTip:NSLocalizedString(@"switchUserTT", nil)];
    [delSwitchBtn setToolTip:NSLocalizedString(@"delSwitchTT", nil)];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem  // DONE
{
//    NSLog(@"anItem selector = %@", NSStringFromSelector([anItem action]));
    if ([@"newUser:" isEqualToString:NSStringFromSelector([anItem action])]) {
	return TRUE;
    } else if ([@"deleteUsers:" isEqualToString:NSStringFromSelector([anItem action])]) {
	if ([userList numberOfSelectedRows] >= 1) {
	    return TRUE;
	} else return FALSE;
    } else if ([@"switchAndLaunch:" isEqualToString:NSStringFromSelector([anItem action])]) {
	if ([userList numberOfSelectedRows] == 1) {
	    if (([anItem tag] == -1) && ([users indexOfObject:currentUser] == [userList selectedRow])) return FALSE;
	    return TRUE;
	} else return FALSE;
    } else if ([@"showHelp:" isEqualToString:NSStringFromSelector([anItem action])]) {
	return TRUE;
    } else if ([@"addSwApp:" isEqualToString:NSStringFromSelector([anItem action])]) {
	return TRUE;
    } else if ([@"AddSwFiles:" isEqualToString:NSStringFromSelector([anItem action])]) {
	if (([switchableFiles numberOfSelectedRows] == 1) && 
	    ([[switchableFiles itemAtRow:[switchableFiles selectedRow]] objectForKey:JHDAppFiles] != nil)) {
	    return TRUE;
	} else return FALSE;
    } else if ([@"showMiniSwitchWindow:" isEqualToString:NSStringFromSelector([anItem action])]) {
	return TRUE;
    } else if ([@"openFromDock:" isEqualToString:NSStringFromSelector([anItem action])]) {
	return TRUE;
    } else if ([@"updateDockDefault:" isEqualToString:NSStringFromSelector([anItem action])]) {
	return TRUE;
    }
    return [super validateMenuItem:anItem];
}

- (void)refreshDockPopUp {  // DONE
    int i;
    [dockPopUp removeAllItems];
    for (i = [cAppMenu numberOfItems] - 1; i > 1; i--) {
	[cAppMenu removeItemAtIndex:i];
    }
    for (i = [mAppMenu numberOfItems] - 1; i > 1; i--) {
	[mAppMenu removeItemAtIndex:i];
    }
    for (i = [wAppMenu numberOfItems] - 1; i > 2; i--) {
	[wAppMenu removeItemAtIndex:i];
    }
    for (i = 0; i < [switches count]; i++) {
	if ([[[switches objectAtIndex:i] objectForKey:JHDSwitchSelected] boolValue]) {
	    [dockPopUp addItemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp]];
	    [cAppMenu addItemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp] 
		action:@selector(switchAndLaunch:) keyEquivalent:@""];
	    [[cAppMenu itemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp]] setTag:0];
	    [mAppMenu addItemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp] 
		action:@selector(switchAndLaunch:) keyEquivalent:[NSString stringWithFormat:@"%d", (i + 1)]];
	    [[mAppMenu itemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp]] setTag:0];
	    [[mAppMenu itemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp]] 
		setKeyEquivalentModifierMask:NSCommandKeyMask];
	    [wAppMenu addItemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp] 
		action:@selector(switchAndLaunch:) keyEquivalent:@""];
	    [[wAppMenu itemWithTitle:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp]] setTag:0];
	//    [toolbar insertItemWithItemIdentifier:[[dockPopUp itemAtIndex:i] title] atIndex:0];
	}
    }
    if ([dockPopUp numberOfItems] == 0) {
	[dockPopUp addItemWithTitle:NSLocalizedString(@"none", nil)];
	[dockPopUp selectItemAtIndex:0];
	[dockPopUp setEnabled:FALSE];
    } else {
	[dockPopUp setEnabled:TRUE];
	if ([dockPopUp indexOfItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:JHDDockDefault]] == nil) {
	    [dockPopUp selectItemAtIndex:0];
	    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithString:[dockPopUp titleOfSelectedItem]] 
		forKey:JHDDockDefault];
	} else {
	    [dockPopUp selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:JHDDockDefault]];
	}
    }
}

- (void)prepMSDir // DONE
{
    NSString *mailSwPath = [[NSString alloc] initWithString:[[NSHomeDirectory() 
	    stringByAppendingPathComponent:@"Library"] 
	    stringByAppendingPathComponent:@"MailSwitch"]];
    BOOL firstRun = FALSE;
    BOOL isDir;
    int i, uCnt;
    NSArray *msContent;
    NSMutableArray *updateLog = [NSMutableArray array];
    BOOL errorOut = FALSE;
    NSString *userPath;
    NSString *userLibPath;
    NSString *userPrefPath;
    NSString *userAppSupPath;
    // verify MiniSwitch and currentUser exist
    if ([fileMan fileExistsAtPath: miniSwitchPath]) {
	// Set users to folders in miniSwitchPath
	[self reloadUsers];
    } else {
	// see if old MailSwitch user
	if ([fileMan fileExistsAtPath: mailSwPath isDirectory:&isDir] && isDir) {
	    // prompt user must change 
	    if (NSRunAlertPanel(NSLocalizedString(@"mailSwfoundT", nil), 
		NSLocalizedString(@"mailSwfoundM", nil), 
		NSLocalizedString(@"okay", nil),
		NSLocalizedString(@"quit", nil), nil) == NSAlertAlternateReturn) {
		[NSApp terminate:self];
		return;
	   } else {
		// rename MailSwPath to miniSwitchPath
		if (![fileMan movePath:mailSwPath toPath:miniSwitchPath handler:self]) {
		    NSRunCriticalAlertPanel(NSLocalizedString(@"msErrorT", nil), 
			[NSString stringWithFormat:NSLocalizedString(@"movePathFail", nil), fileManError],
			NSLocalizedString(@"quit", nil),
			nil, nil);
		    [NSApp terminate:self];
		    return;
		}
		[updateLog addObject:NSLocalizedString(@"updateRenameSuc", nil)];
		// move files to appropriately added folders
		msContent = [fileMan directoryContentsAtPath: miniSwitchPath];
		uCnt = [msContent count];
		for (i = 0; ((i < uCnt) && (!errorOut)); i++) {
		    userPath = [miniSwitchPath stringByAppendingPathComponent:
			[msContent objectAtIndex: i]];
		    if ([fileMan fileExistsAtPath:userPath isDirectory:&isDir] && isDir) {
			[updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"updateLogStartUser", nil), 
			    [userPath lastPathComponent]]];
			// add Library folder
			userLibPath = [userPath stringByAppendingPathComponent:@"Library"];
			if ((![fileMan fileExistsAtPath:userLibPath isDirectory:&isDir]) &&
			    (![fileMan createDirectoryAtPath:userLibPath attributes:nil])) {
			    // error
			    [updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDirFail", nil), 
				userLibPath]];
			    [updateLog addObject:[NSString stringWithString:fileManError]];
			    errorOut = TRUE;
			}
			// move Mail, if exists
			if ((!errorOut) && ([fileMan fileExistsAtPath:[userPath stringByAppendingPathComponent:@"Mail"]]) &&
			    (![fileMan movePath:[userPath stringByAppendingPathComponent:@"Mail"] 
			    toPath:[userLibPath stringByAppendingPathComponent:@"Mail"] handler:self])) {
				// error
				[updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"updateLogMoveFail", nil), 
				    [userPath stringByAppendingPathComponent:@"Mail"], [userLibPath stringByAppendingPathComponent:@"Mail"]]];
				[updateLog addObject:[NSString stringWithString:fileManError]];
				errorOut = TRUE;
			}
			// add Preferences folder
			userPrefPath = [userLibPath stringByAppendingPathComponent:@"Preferences"];
			if ((!errorOut) && (![fileMan fileExistsAtPath:userPrefPath isDirectory:&isDir]) &&
			    (![fileMan createDirectoryAtPath:userPrefPath attributes:nil])) {
			    // error
			    [updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDirFail", nil), 
				userPrefPath]];
			    [updateLog addObject:[NSString stringWithString:fileManError]];
			    errorOut = TRUE;
			}
			// move Mail Pref, if exists
			if ((!errorOut) && ([fileMan fileExistsAtPath:[userPath stringByAppendingPathComponent:@"com.apple.mail.plist"]])) {
			    if (![fileMan movePath:[userPath stringByAppendingPathComponent:@"com.apple.mail.plist"] 
				toPath:[userPrefPath stringByAppendingPathComponent:@"com.apple.mail.plist"] handler:self]) {
				// error
				[updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"updateLogMoveFail", nil), 
				    [userPath stringByAppendingPathComponent:@"com.apple.mail.plist"], 
				    [userPrefPath stringByAppendingPathComponent:@"com.apple.mail.plist"]]];
				[updateLog addObject:[NSString stringWithString:fileManError]];
				errorOut = TRUE;
			    }
			}
			// move AddressBook Pref, if exists
			if ((!errorOut) && ([fileMan fileExistsAtPath:[userPath stringByAppendingPathComponent:@"com.apple.AddressBook.plist"]])) {
			    if (![fileMan movePath:[userPath stringByAppendingPathComponent:@"com.apple.AddressBook.plist"] 
				toPath:[userPrefPath stringByAppendingPathComponent:@"com.apple.AddressBook.plist"] handler:self]) {
				// error
				[updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"updateLogMoveFail", nil), 
				    [userPath stringByAppendingPathComponent:@"com.apple.AddressBook.plist"], 
				    [userPrefPath stringByAppendingPathComponent:@"com.apple.AddressBook.plist"]]];
				[updateLog addObject:[NSString stringWithString:fileManError]];
				errorOut = TRUE;
			    }
			}
			// move Addresses, if exists
			if ((!errorOut) && ([fileMan fileExistsAtPath:[userPath stringByAppendingPathComponent:@"Addresses"]]) &&
			    (![fileMan movePath:[userPath stringByAppendingPathComponent:@"Addresses"] 
			    toPath:[userLibPath stringByAppendingPathComponent:@"Addresses"] handler:self])) {
				// error
				[updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"updateLogMoveFail", nil), 
				    [userPath stringByAppendingPathComponent:@"Addresses"], 
				    [userLibPath stringByAppendingPathComponent:@"Addresses"]]];
				[updateLog addObject:[NSString stringWithString:fileManError]];
				errorOut = TRUE;
			}
			// move AddressBook, if exists
			if ((!errorOut) && ([fileMan fileExistsAtPath:[userPath stringByAppendingPathComponent:@"AddressBook"]])) {
			    // add Application Support folder
			    userAppSupPath = [userLibPath stringByAppendingPathComponent:@"Application Support"];
			    if ((![fileMan fileExistsAtPath:userAppSupPath isDirectory:&isDir]) &&
				(![fileMan createDirectoryAtPath:userAppSupPath attributes:nil])) {
				// error
				[updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDirFail", nil), 
				    userAppSupPath]];
				[updateLog addObject:[NSString stringWithString:fileManError]];
				errorOut = TRUE;
			    }
			    if (![fileMan movePath:[userPath stringByAppendingPathComponent:@"AddressBook"] 
			    toPath:[userAppSupPath stringByAppendingPathComponent:@"AddressBook"] handler:self]) {
				// error
				[updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"updateLogMoveFail", nil), 
				    [userPath stringByAppendingPathComponent:@"AddressBook"], 
				    [userAppSupPath stringByAppendingPathComponent:@"AddressBook"]]];
				[updateLog addObject:[NSString stringWithString:fileManError]];
				errorOut = TRUE;
			    }  //*/
			}
			if (!errorOut) [updateLog addObject:[NSString stringWithFormat:NSLocalizedString(@"updateLogFinUser", nil), 
			    [userPath lastPathComponent]]];
		    }
		}
		if (errorOut) {
		    NSBeep();
		    NSRunCriticalAlertPanel(NSLocalizedString(@"msErrorT", nil), 
			[NSString stringWithFormat:NSLocalizedString(@"updateUserFail", nil), [updateLog componentsJoinedByString:@"\n\t"]], 
			NSLocalizedString(@"quit", nil),
			nil, nil);
		    [NSApp terminate:self];
		    return;
		}
		[self reloadUsers];
		firstRun = TRUE;
	    }
	} else {
	    if (![fileMan createDirectoryAtPath: miniSwitchPath attributes:nil]) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"msErrorT", nil), 
		    NSLocalizedString(@"createPathFail", nil), 
		    NSLocalizedString(@"quit", nil),
		    nil, nil);
		[NSApp terminate:self];
		return;
	    }
	    [self newUser:self];
	    firstRun = TRUE;
	}
    }
    if (firstRun) {
	[prefWindow makeKeyAndOrderFront:self];
	if (NSRunAlertPanel(NSLocalizedString(@"welcomeT", nil), 
	    NSLocalizedString(@"welcomeM", nil), 
	    NSLocalizedString(@"okay", nil),
	    NSLocalizedString(@"moreInfo", nil), nil) == NSAlertAlternateReturn)
	    NSRunAlertPanel(NSLocalizedString(@"explanationT", nil), 
		NSLocalizedString(@"explanationM", nil), 
		NSLocalizedString(@"close", nil),
		nil, nil);
    }
}

- (void)reloadUsers  // DONE
{
    BOOL isDir;
    int i;
    NSString *userFullPath;
    NSArray *msContent = [fileMan directoryContentsAtPath: miniSwitchPath];
    [users removeAllObjects];
    for (i = 0; i < [msContent count]; i++) {
        userFullPath = [miniSwitchPath stringByAppendingPathComponent:
            [msContent objectAtIndex: i]];
        if ([fileMan fileExistsAtPath:userFullPath isDirectory:&isDir] && isDir) {
            [users addObject: userFullPath];
        }
    }
    [userList reloadData];
    [self readinCurrentUser];
        
    // Clear out old dockUserMenu
    for (i = [dockUserMenu numberOfItems]; i > 0; i--) {
        if (NSAppKitVersionNumber < kFixedDockMenuAppKitVersion) {
            [[[dockUserMenu itemAtIndex:0] target] release];
        }
        [dockUserMenu removeItemAtIndex:0];
    }
    // (re)build the dock Menu
    [dockUserMenu insertItem:[self createItem:NSLocalizedString(@"userwindow", nil)
        action:@selector(showMiniSwitchWindow:)] atIndex:0];
    [dockUserMenu insertItem:[NSMenuItem separatorItem] atIndex:0];          
    for (i = ([users count] - 1); i >= 0; i--) {
        [dockUserMenu insertItem:[self createItem:((NSString *)[[users objectAtIndex: i] 
	    lastPathComponent]) action:@selector(openFromDock:)] atIndex:0];
    }
}

- (void)readinCurrentUser // DONE?
{
    NSString *cuPath;
    int i;
    
    if (currentUser != nil) {
	cuPath = [currentUser stringByAppendingPathComponent:@"Current User"];
	if (![fileMan fileExistsAtPath:cuPath]) {
            [currentUser release];
            currentUser = nil;
        }
    }
    for (i = 0; i < [users count]; i++) {
        cuPath = [[users objectAtIndex:i] stringByAppendingPathComponent:@"Current User"];
	if ([fileMan fileExistsAtPath:cuPath]) {
	    if (currentUser != nil) {
                if (![[users objectAtIndex:i] isEqualToString:currentUser]) {
                    // dispose of extra CUPs
                    if (![fileMan removeFileAtPath:cuPath handler:self]) {
			// error failed delete
			NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
			    [NSString stringWithFormat:NSLocalizedString(@"delOtherCUP", nil), fileManError], 
			    NSLocalizedString(@"Okay", nil),
			    nil, nil);			
		    }
                }
	    } else {
		currentUser = [[users objectAtIndex:i] copy];
	    }
	}
    }
    if (currentUser == nil) {
	//  NSLog(@"Warning: Could not find a \"Current User.\"");
	NSRunAlertPanel(NSLocalizedString(@"msWarningT", nil), 
	    NSLocalizedString(@"findCUFail", nil),  
	    NSLocalizedString(@"Okay", nil),
	    nil, nil);
	[self newUser:self];
    }
}

/*- (int)currentUserIndex // CHANGED TO [users indexOfObject:currentUser]
{
    int i, index = -1;
    //[self readinCurrentUser];
    if (currentUser == nil) return -1;
    for (i = 0; i < [users count]; i++) {
        if ([currentUser isEqualToString: [users objectAtIndex:i]]) {
            index = i;
        }
    }
    return index;
} */

- (NSMenuItem *)createItem:(NSString *)name action:(SEL)aSelector
{
    NSMenuItem *newItem;
    if (NSAppKitVersionNumber>=kFixedDockMenuAppKitVersion)
    {
        newItem = [[[NSMenuItem alloc] initWithTitle:name action:aSelector 
            keyEquivalent:@""] autorelease];
        [newItem setTarget:self];
        [newItem setEnabled:YES];    
    }
    else {//we're running on an OS version that isn't fixed; use NSInvocation
        //This invocation is going to be of the form aSelector
        NSInvocation *myInv=[NSInvocation invocationWithMethodSignature:[self 
            methodSignatureForSelector:aSelector]];
	newItem=[[[NSMenuItem alloc] initWithTitle:name 
            action:@selector(invoke) keyEquivalent:@""] autorelease];
        [myInv setSelector:aSelector];
        [myInv setTarget:self];
        [myInv setArgument:&newItem atIndex:2];
        [newItem setTarget:[myInv retain]];
        [newItem setEnabled:YES];
    }
    return newItem;
}

- (IBAction)switchAndLaunch:(id)sender // DONE?
{
    NSArray *runningApplications;
    NSDictionary *applInfo;
    NSEnumerator *enumerator;
    int i;
    AEDesc addressDesc;
    AppleEvent event, reply;
    OSErr err;
    pid_t aePid;
    NSMutableArray *aeErrs = [NSMutableArray array];
    
    [relaunchApps removeAllObjects];
    if (sender == nil) {
	// launch dock default
	[relaunchApps addObject:[NSString stringWithString:[dockPopUp titleOfSelectedItem]]];
    } else if ([sender tag] == 1) {
	// launch all switchable applications
	for (i = 0; i < [dockPopUp numberOfItems]; i++) {
	    [relaunchApps addObject:[NSString stringWithString:[[dockPopUp itemAtIndex:i] title]]];
	}
    } else if ([sender tag] == 0) {
	// launch specific application
	[relaunchApps addObject:[NSString stringWithString:[sender title]]];
    } else if ([sender tag] == -2) {
	[relaunchApps addObject:[NSString stringWithString:[sender itemIdentifier]]];
    } // no relaunch
    if ([users indexOfObject:currentUser] != [userList selectedRow]) {
	// prep runningApps for quiting
	[runningApps removeAllObjects];
	for (i = 0; i < [dockPopUp numberOfItems]; i++) {
	    [runningApps addObject:[NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString 
		stringWithString:[[dockPopUp itemAtIndex:i] title]], [NSNumber numberWithInt:-1], nil] 
		forKeys:[NSArray arrayWithObjects: @"appName", @"pid", nil]]]; 
	}
	runningApplications = [[NSWorkspace sharedWorkspace] launchedApplications];
	enumerator = [runningApplications objectEnumerator];
	while(applInfo = [enumerator nextObject]) {
	    for (i = 0; i < [runningApps count]; i++) {
		if([[[applInfo objectForKey:@"NSApplicationPath"] lastPathComponent] isEqualToString:[[runningApps objectAtIndex:i] 
		    objectForKey:@"appName"]]) {
		    [[runningApps objectAtIndex:i] setObject:[applInfo objectForKey:@"NSApplicationProcessIdentifier"] 
			forKey:@"pid"];
		}
	    }
	}
	for (i = [runningApps count] - 1; i >= 0; i--) {
	    if([[[runningApps objectAtIndex:i] objectForKey:@"pid"] intValue] == -1) {
		[runningApps removeObjectAtIndex:i];
	    }
	}	
	if ([runningApps count] > 0) {
	    // start quitTimer
	    quitTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(quitTimedOut:) userInfo:nil repeats:NO];
	    for (i = 0; i < [runningApps count]; i++) {
		aePid = [[[runningApps objectAtIndex:i] objectForKey:@"pid"] intValue];
		err = AECreateDesc(typeKernelProcessID, &aePid, sizeof(pid_t), &addressDesc);
		if (err == noErr) {
		    err = AECreateAppleEvent(kCoreEventClass, kAEQuitApplication, &addressDesc, 
			kAutoGenerateReturnID, kAnyTransactionID, &event);
		} 
		if (err == noErr) {
//		    err = AESend(&event, &reply, kAENoReply, kAENormalPriority, kAEDefaultTimeout, NULL, NULL);
		    err = AESendMessage(&event, &reply, kAENoReply, kAEDefaultTimeout);
		} 
//		AESend(<#const AppleEvent * theAppleEvent#>,<#AppleEvent * reply#>,<#AESendMode sendMode#>,<#AESendPriority sendPriority#>,<#long timeOutInTicks#>,<#AEIdleUPP idleProc#>,<#AEFilterUPP filterProc#>)
//		AESendMessage(<#const AppleEvent * event#>,<#AppleEvent * reply#>,<#AESendMode sendMode#>,<#long timeOutInTicks#>)
		if (err != noErr) {
		    [aeErrs addObject:[NSString stringWithFormat:NSLocalizedString(@"aeErrFail", nil), aePid, err]];
		} 
	    }
	    // if errors cancel timer
	    if ([aeErrs count] > 0) {
		[quitTimer invalidate];
		// notify user
		NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
		    [NSString stringWithFormat:NSLocalizedString(@"quitAppFail", nil), [aeErrs componentsJoinedByString:@"\n\t"]], 
		    NSLocalizedString(@"cancel", nil),
		    nil, nil);
	    }
	} else [self switchUser];
    } else [self launchRelaunchApps];
}    

- (void)switchAppDidQuit:(NSNotification *)aNotification // DONE
{
    NSDictionary *userDict;
    NSString *name;
    int i;
    
    if ([runningApps count] > 0) {
        userDict = [aNotification userInfo];
        name = [[userDict objectForKey:@"NSApplicationPath"] lastPathComponent];
	for (i = [runningApps count] - 1; i >= 0; i--) {
	    if([name isEqualToString:[[runningApps objectAtIndex:i] objectForKey:@"appName"]]) {
		[runningApps removeObjectAtIndex:i];
	    }
	}
	if (([runningApps count] == 0) && ([quitTimer isValid])) {
	    [quitTimer invalidate];
	    [self switchUser];
	}
    }
}

- (void)quitTimedOut:(NSTimer*)theTimer{
    NSMutableArray *apps = [NSMutableArray array];
    int i;
    if ([runningApps count] > 0) {
	for (i = 0; i < [runningApps count]; i++) {
	    [apps addObject:[[runningApps objectAtIndex:i] objectForKey:@"appName"]];
	}
	// error: following applications did not quit.
	NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
	    [NSString stringWithFormat:NSLocalizedString(@"quitAppTimeOut", nil), [apps componentsJoinedByString:@", "]], 
	    NSLocalizedString(@"cancel", nil),
	    nil, nil);
	[quitTimer invalidate];
	[runningApps removeAllObjects];
    }
}

- (void)switchUser // DONE
{
    int i, j;
    BOOL errorOut = FALSE;
    BOOL isDir;
    NSMutableArray *switchFiles = [NSMutableArray array];
    NSMutableArray *moveLog = [NSMutableArray array];
    NSMutableArray *pathArray = [NSMutableArray array];
    NSString *destPath;
    NSString *srcPath;
    NSMutableString *dirPath;
//    struct stat linkstat;
    // if not current user
    if ([users indexOfObject:currentUser] != [userList selectedRow]) {
	// build list of files to switch
	for (i = 0; i < [switches count]; i++) {
	    for (j = 0; j < [[[switches objectAtIndex:i] objectForKey:JHDAppFiles] count]; j++) {
		if ([[[[[switches objectAtIndex:i] objectForKey:JHDAppFiles] objectAtIndex:j] 
		    objectForKey:JHDSwitchSelected] intValue] == 1) {
		    [switchFiles addObject:[[[[[switches objectAtIndex:i] objectForKey:JHDAppFiles] 
			objectAtIndex:j] objectForKey:JHDSwitchFile] copy]];
		}
	    }
	}
	// put back current users files
	[moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogRetCUStart", nil), 
	    [currentUser lastPathComponent]]];
	for (i = 0; ((i < [switchFiles count]) && (!errorOut)); i++) {
	    srcPath = [[switchFiles objectAtIndex:i] stringByExpandingTildeInPath];
	    [pathArray removeAllObjects];
	    [pathArray addObjectsFromArray:[[switchFiles objectAtIndex:i] pathComponents]];
	    [pathArray removeObjectAtIndex:0];
	    destPath = [NSString stringWithString:[currentUser 
		stringByAppendingPathComponent:[pathArray componentsJoinedByString:@"/"]]];
	    if ([fileMan fileExistsAtPath:srcPath]) {
	   // if ((lstat([srcPath fileSystemRepresentation], &linkstat) != -1) && (S_ISLNK(linkstat.st_mode))) {
		if ([[fileMan pathContentOfSymbolicLinkAtPath:srcPath] isEqualToString:destPath]) {
		    // delete symlink
		    if (![fileMan removeFileAtPath:srcPath handler:self]) {
			[moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDelSLFail", nil), srcPath]];
			[moveLog addObject:[NSString stringWithString:fileManError]];
			errorOut = TRUE;
		    } else {
			[moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDelSLSuc", nil), srcPath]];
		    }
		} else { // move files
		    if (![fileMan fileExistsAtPath:[destPath stringByDeletingLastPathComponent] isDirectory:&isDir]) {
			dirPath = [NSMutableString stringWithString:currentUser];
			for (j = 0; j < [pathArray count] - 1; j++) {
			    [dirPath appendFormat:@"/%@", [pathArray objectAtIndex:j]];
			    if (![fileMan fileExistsAtPath:dirPath isDirectory:&isDir]) {
				if (![fileMan createDirectoryAtPath:dirPath attributes:nil]) {
				    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDirFail", nil), dirPath]];
				    [moveLog addObject:[NSString stringWithString:fileManError]];
				    errorOut = TRUE;
				}
			    }
			}
		    }
		    if (!errorOut) {
			if (![fileMan movePath:srcPath toPath:destPath handler:self]) {
			    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogRetCUFileFail", nil), srcPath]];
			    [moveLog addObject:[NSString stringWithString:fileManError]];
			    errorOut = TRUE;
			} else {
			    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogRetCUFileSuc", nil), srcPath]];
			}
		    }
		}
	    }
	}
	if (!errorOut) {
	    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogRetCUFin", nil), 
		[currentUser lastPathComponent]]];
	    
	    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogPutNewStart", nil), 
		[[users objectAtIndex:[userList selectedRow]] lastPathComponent]]];
	}
	// place new users files
	for (i = 0; ((i < [switchFiles count]) && (!errorOut)); i++) {
	    destPath = [[switchFiles objectAtIndex:i] stringByExpandingTildeInPath];
	    [pathArray removeAllObjects];
	    [pathArray addObjectsFromArray:[[switchFiles objectAtIndex:i] pathComponents]];
	    [pathArray removeObjectAtIndex:0];
	    srcPath = [NSString stringWithString:[[users objectAtIndex:[userList selectedRow]] 
		stringByAppendingPathComponent:[pathArray componentsJoinedByString:@"/"]]];
	    
	    if ([fileMan fileExistsAtPath:srcPath isDirectory:&isDir]) {
		if (([symlinkCB state]) && isDir) {
		    // create symlink for folders
		    if (![fileMan createSymbolicLinkAtPath:destPath pathContent:srcPath]) {
			[moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogCreSLFail", nil), srcPath]];
			[moveLog addObject:[NSString stringWithString:fileManError]];
			errorOut = TRUE;
		    } else {
			[moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogCreSLSuc", nil), srcPath]];
		    }
		} else { // move file
		    if (![fileMan fileExistsAtPath:[destPath stringByDeletingLastPathComponent] isDirectory:&isDir]) {
			dirPath = [NSMutableString stringWithString:NSHomeDirectory()];
			for (j = 0; j < [pathArray count] - 1; j++) {
			    [dirPath appendFormat:@"/%@", [pathArray objectAtIndex:j]];
			    if (![fileMan fileExistsAtPath:dirPath isDirectory:&isDir]) {
				if (![fileMan createDirectoryAtPath:dirPath attributes:nil]) {
				    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDirFail", nil), dirPath]];
				    [moveLog addObject:[NSString stringWithString:fileManError]];
				    errorOut = TRUE;
				}
			    }
			}
		    }
		    if (!errorOut) {
			if (![fileMan movePath:srcPath toPath:destPath handler:self]) {
			    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogPutNewFileFail", nil), srcPath]];
			    [moveLog addObject:[NSString stringWithString:fileManError]];
			    errorOut = TRUE;
			} else {
			    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogPutNewFileSuc", nil), srcPath]];
			}
		    }
		}
	    }
	}
    }
    if (!errorOut) {
	//- change CUP to new user
	if (![fileMan removeFileAtPath:[currentUser stringByAppendingPathComponent:@"Current User"] handler:self]) {
	    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogDelCUFail", nil), [currentUser lastPathComponent]]];
	    [moveLog addObject:[NSString stringWithString:fileManError]];
	    errorOut = TRUE;
	} 	
	if (![fileMan createFileAtPath:[[users objectAtIndex:[userList selectedRow]] 
	    stringByAppendingPathComponent:@"Current User"] contents:nil attributes:nil]) {
	    [moveLog addObject:[NSString stringWithFormat:NSLocalizedString(@"moveLogCreateNewCUFail", nil), 
		[[users objectAtIndex:[userList selectedRow]] lastPathComponent]]];
	    [moveLog addObject:[NSString stringWithString:fileManError]];
	    errorOut = TRUE;
	}
    }
    if (!errorOut) {
	[self readinCurrentUser];
	[self updateUserWinBtnEnables];
	[self launchRelaunchApps];
	[userList reloadData];
    } else {
	// notify user of error
	NSBeep();
	NSRunCriticalAlertPanel(NSLocalizedString(@"msErrorT", nil), 
	    [NSString stringWithFormat:NSLocalizedString(@"switchUserFail", nil), [moveLog componentsJoinedByString:@"\n\t"]], 
	    NSLocalizedString(@"cancel", nil),
	    nil, 
	    nil);
    }
}

- (void)launchRelaunchApps // DONE
{
    int i, j;
    BOOL appLaunched = FALSE;
    for (i = 0; (i < [relaunchApps count]); i++) {
	for (j = 0; (!appLaunched && (j < 5)); j++) {
	    appLaunched = [[NSWorkspace sharedWorkspace] launchApplication:[relaunchApps objectAtIndex:i]];
	}
	if (!appLaunched) {
	    // failed to launch
	    NSBeep();
	    NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
		[NSString stringWithFormat:NSLocalizedString(@"launchAppFail", nil), [relaunchApps objectAtIndex:i], 
		[relaunchApps objectAtIndex:i]], NSLocalizedString(@"okay", nil),
		nil, nil);
	} else appLaunched = FALSE; 
    }
}

-(BOOL)fileManager:(NSFileManager *)manager shouldProceedAfterError:(NSDictionary *)errorDict
{
    [fileManError release];
    fileManError = [[NSString alloc] initWithString:[errorDict description]];
    return NO;
}

- (IBAction)addSwApp:(id)sender  // DONE
{
    BOOL i, appExists = 0;
    NSOpenPanel *selAppPanel = [NSOpenPanel openPanel];
    [selAppPanel setPrompt:NSLocalizedString(@"select", nil)];
    [selAppPanel setTitle:NSLocalizedString(@"selAppT", nil)];
    [selAppPanel setAllowsMultipleSelection:NO];
    if ([selAppPanel runModalForDirectory:@"/Applications" file:nil types:[NSArray 
	arrayWithObjects:@"app", NSFileTypeForHFSTypeCode('APPL'), nil]] == NSOKButton) {
	for (i = 0; i < [switches count]; i++) {
	    if ([[[switches objectAtIndex:i] objectForKey:JHDSwitchApp] 
		isEqualToString:[[[selAppPanel filenames] objectAtIndex:0] lastPathComponent]]) appExists = 1;
	}
	if (appExists) {
	    NSRunAlertPanel(NSLocalizedString(@"appExistsT", nil), 
	    [NSString stringWithFormat: NSLocalizedString(@"appExistsM", nil), 
		[[[selAppPanel filenames] objectAtIndex:0] lastPathComponent]], 
	    NSLocalizedString(@"okay", nil), nil, nil);
	} else {
	    [switches addObject:[NSMutableDictionary dictionaryWithObjects:[NSMutableArray 
		arrayWithObjects:[[[selAppPanel filenames] objectAtIndex:0] lastPathComponent], [NSMutableArray array], 
		[NSNumber numberWithInt:0], nil]
		forKeys:[NSMutableArray arrayWithObjects:JHDSwitchApp, JHDAppFiles, JHDSwitchSelected, nil]]];
	    [switchableFiles reloadData];
	    [[NSUserDefaults standardUserDefaults] setObject:switches forKey:JHDSwitchArray];
	}
    }
}

- (IBAction)AddSwFiles:(id)sender
{
    BOOL filesSkipped = FALSE;
    int i, j, cnt;
    NSOpenPanel *selFilesPanel = [NSOpenPanel openPanel];
    NSMutableArray *swFilesAll = [NSMutableArray array];
    [selFilesPanel setPrompt:NSLocalizedString(@"select", nil)];
    [selFilesPanel setTitle:[NSString stringWithFormat:NSLocalizedString(@"selFilesT", nil), 
	[[switchableFiles itemAtRow:[switchableFiles selectedRow]] objectForKey:JHDSwitchApp]]];
    [selFilesPanel setAllowsMultipleSelection:YES];
    [selFilesPanel setCanChooseDirectories:YES];
    if ([selFilesPanel runModalForDirectory:NSHomeDirectory() file:nil types:nil] == NSOKButton) {
	for (i = 0; i < [switches count]; i++) {
	    for (j = 0; j < [[[switches objectAtIndex:i] objectForKey:JHDAppFiles] count]; j++) {
		[swFilesAll addObject:[[[[switches objectAtIndex:i] objectForKey:JHDAppFiles] 
		    objectAtIndex:j] objectForKey:JHDSwitchFile]];
	    }
	}
	cnt = [[selFilesPanel filenames] count];
	for (i = 0; i < cnt; i++) {
	    if ([swFilesAll indexOfObject:[[[selFilesPanel filenames] objectAtIndex:i] 
		stringByAbbreviatingWithTildeInPath]] != NSNotFound) {
		filesSkipped = TRUE;
	    } else {
		[[[switchableFiles itemAtRow:[switchableFiles selectedRow]] objectForKey:JHDAppFiles]
		    addObject:[NSMutableDictionary dictionaryWithObjects:[NSMutableArray 
		    arrayWithObjects: [[[selFilesPanel filenames] objectAtIndex:i] stringByAbbreviatingWithTildeInPath], 
		    [NSNumber numberWithInt:1], nil] forKeys:[NSMutableArray 
		    arrayWithObjects:JHDSwitchFile, JHDSwitchSelected, nil]]];
	    }
	}
	[self updateAppSwitchSelected];
	[switchableFiles reloadData];
	[self refreshDockPopUp];
	[[NSUserDefaults standardUserDefaults] setObject:switches forKey:JHDSwitchArray];
	if (filesSkipped) {
	    NSRunAlertPanel(NSLocalizedString(@"fileExistsT", nil), 
	    NSLocalizedString(@"fileExistsM", nil), NSLocalizedString(@"okay", nil), nil, nil);
	}
    }
}

- (IBAction)deleteSelectedSw:(id)sender
{
    NSIndexSet *iSet;
    BOOL removedSW;
    int i, j;
    if (NSRunAlertPanel(NSLocalizedString(@"delSwT", nil), NSLocalizedString(@"delSwM", nil), 
	NSLocalizedString(@"okay", nil), NSLocalizedString(@"cancel", nil), nil) == NSAlertDefaultReturn) {
	iSet = [switchableFiles selectedRowIndexes];
	i = [iSet lastIndex];
	while (i != NSNotFound) {
	    removedSW = FALSE;
	    if ([[switchableFiles itemAtRow:i] objectForKey:JHDAppFiles] != nil) {
		// remove application
		[switches removeObject:[switchableFiles itemAtRow:i]];
	    } else {
		// remove file from application
		for (j = [switches count] - 1; (j >= 0) && (!removedSW); j--) {
		    if ([[[switches objectAtIndex:j] objectForKey:JHDAppFiles] 
			    indexOfObject:[switchableFiles itemAtRow:i]] != NSNotFound) {
			//NSLog(@"%@", [[switchableFiles itemAtRow:i] description]);
			[[[switches objectAtIndex:j] objectForKey:JHDAppFiles] 
			    removeObject:[switchableFiles itemAtRow:i]];
			removedSW = TRUE;
		    }
		}
	    }
	    i = [iSet indexLessThanIndex:i];
	}
	[self updateAppSwitchSelected];
	[switchableFiles reloadData];
	[self refreshDockPopUp];
	[[NSUserDefaults standardUserDefaults] setObject:switches forKey:JHDSwitchArray];
    }
}

- (IBAction)deleteUsers:(id)sender  // DONE
{
    NSMutableArray *trashableUsers = [NSMutableArray array];
    NSString *trashedUser;
    NSIndexSet *iSet = [userList selectedRowIndexes];
    int j, i = [iSet firstIndex];
    
    // build trashableUsers
    while (i != NSNotFound) {
	if ([users indexOfObject:currentUser] == i) {
	    if ([iSet count] > 1) {
		if (NSRunAlertPanel(NSLocalizedString(@"msWarningT", nil), 
		    [NSString stringWithFormat:NSLocalizedString(@"delCUSelected1", nil), [[users objectAtIndex:i] lastPathComponent]], 
		    NSLocalizedString(@"skip", nil), NSLocalizedString(@"cancel", nil), nil) == NSAlertAlternateReturn) return;
	    } else {
		NSRunAlertPanel(NSLocalizedString(@"msWarningT", nil), 
		    [NSString stringWithFormat:NSLocalizedString(@"delCUSelected2", nil), [[users objectAtIndex:i] lastPathComponent]], 
		    NSLocalizedString(@"cancel", nil), nil, nil);
		return;
	    }
	} else {
	    [trashableUsers addObject:[users objectAtIndex:i]];
	}
	i = [iSet indexGreaterThanIndex:i];
    }
    if ([trashableUsers count] > 0) {
	if (NSRunAlertPanel(NSLocalizedString(@"msWarningT", nil), 
	    [NSString stringWithFormat:NSLocalizedString(@"delUsersConf", nil), [trashableUsers count]], 
	    NSLocalizedString(@"continue", nil), NSLocalizedString(@"cancel", nil), nil) == NSAlertAlternateReturn) return;
	// delete trashableUsers
	for (i = 0; i < [trashableUsers count]; i++) {
	    trashedUser = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] 
		stringByAppendingPathComponent:[[trashableUsers objectAtIndex:i] lastPathComponent]];
	    j = 1;
	    while ([fileMan fileExistsAtPath:trashedUser]) {
		trashedUser = [NSString stringWithFormat:@"%@ %d", [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] 
		stringByAppendingPathComponent:[[trashableUsers objectAtIndex:i] lastPathComponent]], j];
		j++;
	    }
	    if (![fileMan movePath:[trashableUsers objectAtIndex:i] toPath:trashedUser handler:self]) {
		NSBeep();
		NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
		    [NSString stringWithFormat:NSLocalizedString(@"delUserFail", 
		    nil), [[trashableUsers objectAtIndex:i] lastPathComponent], fileManError], 
		    NSLocalizedString(@"okay", nil), 
		    nil, nil);
	    }
	}
    }
    [self updateUserWinBtnEnables];
    [self reloadUsers];
    
/*    NSEnumerator *e = [userList selectedRowEnumerator]; 
    NSNumber *nextNum;
    int i, j, cuI = -1;
    NSMutableArray *trashableUsers = [NSMutableArray array];
    int answer = NSAlertDefaultReturn;
    while ((answer == NSAlertDefaultReturn) && (nextNum = [e nextObject])) {
	i = [nextNum intValue];
	if (i == [users indexOfObject:currentUser]) cuI = i;
	else [trashableUsers addObject:[users objectAtIndex:i]];
    }
    
    if ([trashableUsers count] > 0) {
	if (cuI >= 0) {
	    NSBeep();
	    answer = NSRunAlertPanel(NSLocalizedString(@"msWarningT", nil), 
		[NSString stringWithFormat:NSLocalizedString(@"delCUSelected1", nil), [[users objectAtIndex:i] lastPathComponent]], 
		NSLocalizedString(@"skip", nil), 
		NSLocalizedString(@"cancel", nil), nil);
	}
	if (answer == NSAlertDefaultReturn) {
	    // delete trashable users
	    for (i = 0; i < [trashableUsers count]; i++) {
		trashedUser = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] 
		    stringByAppendingPathComponent:[[users objectAtIndex:i] lastPathComponent]];
		j = 1;
		while ([fileMan fileExistsAtPath:trashedUser]) {
		    trashedUser = [NSString stringWithFormat:@"%@ %d", [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] 
		    stringByAppendingPathComponent:[[users objectAtIndex:i] lastPathComponent]], j];
		    j++;
		}
		if (![fileMan movePath:[users objectAtIndex:i] toPath:trashedUser handler:self]) {
		    NSBeep();
		    NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
			[NSString stringWithFormat:NSLocalizedString(@"delUserFail", 
			nil), [[users objectAtIndex:i] lastPathComponent], fileManError], 
			NSLocalizedString(@"okay", nil), 
			nil, nil);
		}
	    }
	}
    } else if (cuI >= 0) {
	// cannot delete current User
	NSBeep();
	NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
	    [NSString stringWithFormat:NSLocalizedString(@"delCUSelected2", nil), [[users objectAtIndex:i] lastPathComponent]], 
	    NSLocalizedString(@"cancel", nil), 
	    nil, nil);
    }
    [self reloadUsers]; */
}

- (IBAction)newUser:(id)sender // DONE?
{
    int i = 1;
    NSString *name = NSLocalizedString(@"mainu", nil);
    NSString *returnErr;
    if ([users count] > 0) {
        name = NSLocalizedString(@"newu", nil);
        while ([self usersIndexForName:name] >= 0) {
            name = [NSString localizedStringWithFormat:@"%@ %d", 
                NSLocalizedString(@"newu", nil), i];
            i++;
        }
    }
    returnErr = [self createNewUserWithName:name];
    if (returnErr != nil) {
        // failed to create new user
        NSBeep();
	NSRunCriticalAlertPanel(NSLocalizedString(@"msErrorT", nil), 
	    [NSString stringWithFormat:NSLocalizedString(@"genFailWithError", nil), returnErr],
	    NSLocalizedString(@"okay", nil),
	    nil, 
	    nil);
    } else {
        [userList selectRow:[self usersIndexForName:name] 
            byExtendingSelection:FALSE];
	[self updateUserWinBtnEnables];
    }
}

- (int)usersIndexForName:(NSString *)name // DONE
{
    int i, index = -1;
    for (i = 0; i < [users count]; i++) {
        if ([[[users objectAtIndex:i] lastPathComponent] isEqualToString:name]) {
            index = i;
        }
    }
    return index;
}

- (NSString *)createNewUserWithName:(NSString *)name  // DONE?
{
    NSString *userPath = [miniSwitchPath stringByAppendingPathComponent:name];
    NSString *cuPath = [userPath stringByAppendingPathComponent:@"Current User"];
//    NSString *tempPath;
//    BOOL dirCreated = TRUE;
    if ([fileMan createDirectoryAtPath:userPath attributes:nil]) {
        if ([users indexOfObject:currentUser] == NSNotFound) {
            if (![fileMan createFileAtPath:cuPath contents:nil attributes:nil]) {
                [fileMan removeFileAtPath:userPath handler:self];
                return [NSString stringWithFormat:NSLocalizedString(@"createCUPFail", nil), cuPath, fileManError];
            } 
        } 
    /*else {
            tempPath = [userPath stringByAppendingPathComponent:@"Mail"];
            dirCreated = [fileMan createDirectoryAtPath:tempPath 
                attributes:nil];
            if (dirCreated) {
		tempPath = [tempPath stringByAppendingPathComponent:@"Mailboxes"];
		dirCreated = [fileMan createDirectoryAtPath:tempPath 
		    attributes:nil];
	    }
	}
        if (dirCreated) {
            [self reloadUsers];
            return @"";
        } else {
            [fileMan removeFileAtPath:userPath handler:self];
            NSLog(@"Error: Failed to create directory at %@", tempPath);
        } */
    } else return [NSString stringWithFormat:NSLocalizedString(@"createUserFail", nil), name];
    [self reloadUsers];
    return nil;
}

- (IBAction)showHelp:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL 
        URLWithString:@"http://www.hawkwood.com/miniswitch/"]];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode
    contextInfo:(void *)contextInfo
{
   // NSLog(@"sheet %@ ended with a %d", [sheet title], returnCode);
}

- (IBAction)setQuitOnCloseWindow:(id)sender // DONE
{
    [[NSUserDefaults standardUserDefaults] setInteger:[autoQuitCB state] forKey:JHDAutoQuit];
}

- (IBAction)updateDockDefault:(id)sender  // DONE
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithString:[dockPopUp titleOfSelectedItem]] 
	forKey:JHDDockDefault];
}

- (IBAction)updateSymLinkUse:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:[symlinkCB state] forKey:JHDSymLinkUse];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
    hasVisibleWindows:(BOOL)flag
{
    if (!flag) {
        [miniSwitchWindow makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:TRUE];
    }
    return YES;
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return [autoQuitCB state];
}

//*** start Dock Menu selectors *** // DONE?
- (IBAction)showMiniSwitchWindow:(id)sender
{
    [miniSwitchWindow makeKeyAndOrderFront:self];
}

- (IBAction)openFromDock:(id)sender
{
    // Open default dock app with "user"
    [userList selectRow:[self usersIndexForName:[sender title]] 
	byExtendingSelection:FALSE];
    [self switchAndLaunch:nil];
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    return dockUserMenu;
}
//*** end Dock Menu selectors ***

//*** start tableview datasource methods *** // DONE?
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [users count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:
    (NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"userList"]) return [[users objectAtIndex:rowIndex] lastPathComponent];
    if (([[aTableColumn identifier] isEqualToString:@"cuList"]) && (rowIndex == [users indexOfObject:currentUser])) 
	return [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"cu", nil) attributes:[NSDictionary 
	    dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont systemFontOfSize:10.0], [NSColor redColor], nil] 
	    forKeys:[NSArray arrayWithObjects: NSFontAttributeName, NSForegroundColorAttributeName, 
	     nil]]] autorelease];
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject
    forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSString *oldPath = [users objectAtIndex:rowIndex];
    NSString *newPath = [miniSwitchPath
        stringByAppendingPathComponent: anObject];
    
    if (![[[users objectAtIndex:rowIndex] lastPathComponent] isEqualToString: anObject]) {
        if ([fileMan fileExistsAtPath:newPath]) {
            NSBeep();
            NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
                [NSString stringWithFormat:NSLocalizedString(@"changeNameExists", nil), anObject],
                NSLocalizedString(@"cancel", nil), 
                nil, nil);
	} else if (![fileMan movePath:oldPath toPath:newPath handler:self]) {
            NSBeep();
            NSRunAlertPanel(NSLocalizedString(@"msErrorT", nil), 
                [NSString stringWithFormat:NSLocalizedString(@"changeNameFail", nil), 
		    [[users objectAtIndex:rowIndex] lastPathComponent], anObject, fileManError], 
                NSLocalizedString(@"cancel", nil), 
                nil, nil);
        } 
    }
    [self reloadUsers];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    [self updateUserWinBtnEnables];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
//    NSLog(@"textShouldBeginEditing called w: %@", [fieldEditor string]);
    if (rowIndex == [users indexOfObject:currentUser]) {
	NSBeep();
	return FALSE;
    }
    return TRUE;
}
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
/*    if (rowIndex == [users indexOfObject:currentUser]) 
	[aCell setTextColor:[NSColor darkGrayColor]];
    else [aCell setTextColor:[NSColor blackColor]];
*/
}
//*** end tableview datasource methods ***

- (void) updateUserWinBtnEnables
{
    if (([userList selectedRow] == [users indexOfObject:currentUser]) || ([userList numberOfSelectedRows] > 1)) {
	[switchUserBtn setEnabled:FALSE];
    } else {
	[switchUserBtn setEnabled:TRUE];
    }
    if (([userList numberOfSelectedRows] == 1) && ([userList selectedRow] == [users indexOfObject:currentUser])) {
	[delUserBtn setEnabled:FALSE];
    } else { 
	[delUserBtn setEnabled:TRUE];
    }
}

//*** start outlineview datasource methods ***
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if (item == nil) {
	return [switches objectAtIndex:index];
    } else {
	return [[item objectForKey:JHDAppFiles] objectAtIndex:index];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
//    if (item == nil) return YES;
    if ([item objectForKey:JHDAppFiles] != nil) return YES;
    
    return NO;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) return [switches count];
    
    if ([item objectForKey:JHDAppFiles] != nil) 
	return [[item objectForKey:JHDAppFiles] count];
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
   // int i, appState = 0;
    if ([[tableColumn identifier] isEqualToString:@"files"]) {
//	if (item == nil) return @"~";
	if ([item objectForKey:JHDSwitchApp] != nil) 
	return [item objectForKey:JHDSwitchApp];
	if ([item objectForKey:JHDSwitchFile] != nil) 
	return [item objectForKey:JHDSwitchFile];
    } else if ([[tableColumn identifier] isEqualToString:@"selects"]) {
	if ([item objectForKey:JHDSwitchSelected] != nil)
	return [item objectForKey:JHDSwitchSelected];
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object 
    forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    int cCnt, i;
    if ([[tableColumn identifier] isEqualToString:@"selects"]) {
	if([object intValue] == NSMixedState) object = [NSNumber numberWithInt:1];	
	if ([item objectForKey:JHDAppFiles] != nil) {
	    // set all appFiles same as app
	    [item setObject:object forKey:JHDSwitchSelected];
	    cCnt = [self outlineView:outlineView numberOfChildrenOfItem:item];
	    for (i = 0; i < cCnt; i++) {
		[[self outlineView:outlineView child:i ofItem:item] setObject:object forKey:JHDSwitchSelected];
	    }
	} else if ([item objectForKey:JHDAppFiles] == nil) {
	    // change app's select to match current settings
	    [item setObject:object forKey:JHDSwitchSelected];
	    [self updateAppSwitchSelected];
	}
	[[NSUserDefaults standardUserDefaults] setObject:switches forKey:JHDSwitchArray];
    }
    [outlineView reloadData];
    [self refreshDockPopUp];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
    shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item 
{
    if ([[tableColumn identifier] isEqualToString:@"selects"]) return YES;
    return NO;
}

- (void)updateAppSwitchSelected
{
    int i, j, appState;
    for (j = 0; j < [switches count]; j++) {
	appState = 0;
	for (i = 0; i < ([[[switches objectAtIndex:j] objectForKey:JHDAppFiles] count]); i++) {
	    if (i == 0) appState = [[[[[switches objectAtIndex:j] objectForKey:JHDAppFiles] objectAtIndex:i] 
		objectForKey:JHDSwitchSelected] intValue];
	    else if ((appState == 0) && ([[[[[switches objectAtIndex:j] objectForKey:JHDAppFiles] objectAtIndex:i] 
		objectForKey:JHDSwitchSelected] intValue] == 1)) appState = -1;
	    else if ((appState == 1) && ([[[[[switches objectAtIndex:j] objectForKey:JHDAppFiles] objectAtIndex:i] 
		objectForKey:JHDSwitchSelected] intValue] == 0)) appState = -1;
	}
	[[switches objectAtIndex:j] setObject:[NSNumber numberWithInt:appState] forKey:JHDSwitchSelected];
    }
}

- (void)outlineViewSelectionIsChanging:(NSNotification *)notification
{
    if ([switchableFiles selectedRow] != -1) {
	[[addSwitchPU lastItem] setEnabled:TRUE];
	[delSwitchBtn setEnabled:TRUE];
    } else { 
	[[addSwitchPU lastItem] setEnabled:TRUE];
	[delSwitchBtn setEnabled:FALSE];
    }
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    if ([switchableFiles selectedRow] != -1) {
	[[addSwitchPU lastItem] setEnabled:TRUE];
	[delSwitchBtn setEnabled:TRUE];
    } else { 
	[[addSwitchPU lastItem] setEnabled:TRUE];
	[delSwitchBtn setEnabled:FALSE];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
    return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object
{
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
{
    return nil;
}
//*** end outlineview datasource methods ***

- (void)windowWillClose:(NSNotification *)aNotification
{
    if ([[aNotification object] isEqual:miniSwitchWindow] && [autoQuitCB state]) [prefWindow orderOut:self];
}

/*** start toolbar display methods ***
- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if ([[theItem itemIdentifier] isEqualToString:@"tbNewUser"]) {
	return TRUE;
    } else if ([[theItem itemIdentifier] isEqualToString:@"tbDeleteUser"]) {
	if ([userList numberOfSelectedRows] >= 1) return TRUE;
    } else if ([[theItem itemIdentifier] isEqualToString:@"tbSwitchUser"]) {
	if (([userList numberOfSelectedRows] == 1) 
	    && ([userList selectedRow] != [users indexOfObject:currentUser])) 
	    return TRUE;
    } else if ([userList numberOfSelectedRows] == 1) return TRUE;
    return FALSE;
 }

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString 
    *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *newItem = [[[NSToolbarItem alloc] 
        initWithItemIdentifier:itemIdentifier] autorelease];

    if ([itemIdentifier isEqualToString:@"tbNewUser"]) {
        [newItem setLabel:NSLocalizedString(@"tbNewUserLab", nil)];
        [newItem setPaletteLabel:NSLocalizedString(@"tbNewUserLab", nil)];
        [newItem setToolTip:NSLocalizedString(@"tbNewUserTip", nil)];
        [newItem setImage:[NSImage imageNamed:@"newUser.tiff"]];
        [newItem setAction:@selector(newUser:)];    
    } else if ([itemIdentifier isEqualToString:@"tbDeleteUser"]) {
        [newItem setLabel:NSLocalizedString(@"tbDeleteUserLab", nil)];
        [newItem setPaletteLabel:NSLocalizedString(@"tbDeleteUserLab", nil)];
        [newItem setToolTip:NSLocalizedString(@"tbDeleteUserTip", nil)];
        [newItem setImage:[NSImage imageNamed:@"deleteUser.tiff"]];
        [newItem setAction:@selector(deleteUsers:)];        
    } else if ([itemIdentifier isEqualToString:@"tbSwitchUser"]) {
        [newItem setLabel:NSLocalizedString(@"tbSwitchUserLab", nil)];
        [newItem setPaletteLabel:NSLocalizedString(@"tbSwitchUserLab", nil)];
        [newItem setToolTip:NSLocalizedString(@"tbSwitchUserTip", nil)];
        [newItem setImage:[NSImage imageNamed:@"switchUser.tiff"]];
	[newItem setTag:-1];
        [newItem setAction:@selector(switchAndLaunch:)];    
    } else {
	//return nil;
        [newItem setLabel:[NSString stringWithFormat:NSLocalizedString(@"tbOpenAppLab", nil), itemIdentifier]];
        [newItem setPaletteLabel:[NSString stringWithFormat:NSLocalizedString(@"tbOpenAppLab", nil), itemIdentifier]];
        [newItem setToolTip:[NSString stringWithFormat:NSLocalizedString(@"tbOpenAppTip", nil), itemIdentifier]];
        [newItem setImage:[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace 
            sharedWorkspace] fullPathForApplication:itemIdentifier]]];
	[newItem setTag:-2];
        [newItem setAction:@selector(switchAndLaunch:)];    
    }
    
    [newItem setTarget:self];
    [newItem setMenuFormRepresentation:NULL];
    return newItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{ 
    return [NSArray arrayWithObjects:@"tbNewUser", @"tbDeleteUser", 
        NSToolbarFlexibleSpaceItemIdentifier, @"tbSwitchUser", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    int i;
    NSMutableArray *allowedItems = [NSMutableArray arrayWithObjects:@"tbNewUser", @"tbDeleteUser", @"tbSwitchUser",
	NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, 
	NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, nil];
/*    for (i = 0; i < [[dockPopUp items] count]; i++) {
	[allowedItems addObject:[NSString stringWithString:[[dockPopUp itemAtIndex:i] title]]];
    }  * /
    for (i = 0; i < [switches count]; i++) {
	if ([[[switches objectAtIndex:i] objectForKey:JHDSwitchSelected] boolValue]) {
	    [allowedItems addObject:[[switches objectAtIndex:i] objectForKey:JHDSwitchApp]];
	}
    }
    return allowedItems;
}
//*** end toolbar display methods ***/

@end
