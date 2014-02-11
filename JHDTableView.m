//
//  JHDTableView.m
//  MiniSwitch
//
//  Created by Justin Hawkwood on 9/26/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JHDTableView.h"


@implementation JHDTableView

- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    if (([theEvent type] == NSRightMouseDown) || 
        (([theEvent type] == NSLeftMouseDown) && 
        ([theEvent modifierFlags] & NSControlKeyMask))) {
        NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil]; 
	int row = [self rowAtPoint:point]; 
 	if (row < 0) {
            [self deselectAll:self];
        } else {
            if (![self isRowSelected:row]) {
                [self selectRow:row byExtendingSelection:NO];  
            }
        }
    }
    return [super menuForEvent:theEvent];
}

@end
