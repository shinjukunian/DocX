//
//  DocX.h
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

#import <TargetConditionals.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif
//! Project version number for DocX.
FOUNDATION_EXPORT double DocXVersionNumber;

//! Project version string for DocX.
FOUNDATION_EXPORT const unsigned char DocXVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DocX/PublicHeader.h>


