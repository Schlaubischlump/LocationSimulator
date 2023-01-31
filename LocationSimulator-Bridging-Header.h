//
//  LocationSimulator-Bridging-Header.h
//  LocationSimulator
//
//  Created by David Klopp on 30.01.23.
//  Copyright © 2023 David Klopp. All rights reserved.
//

#ifndef LocationSimulator_Bridging_Header_h
#define LocationSimulator_Bridging_Header_h

#import <AppKit/AppKit.h>

@interface NSMenuItem(Private)
- (void)_corePerformAction;
- (BOOL)_viewHandlesEvents;
@end

#endif /* LocationSimulator_Bridging_Header_h */
