/*
 
 Copyright (C) 2011 GUI Cocoa, LLC.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 */

#import "GCAssetBrowser.h"

@implementation GCAssetBrowser

@synthesize title=_title;
@synthesize browserDelegate=_browserDelegate;
@synthesize assetsLibrary=_assetsLibrary;
@synthesize view=_view;

- (id)initWithAssetsLibrary:(ALAssetsLibrary *)library {
    self = [super init];
    if (self) {
        if (library == nil) { _assetsLibrary = [[ALAssetsLibrary alloc] init]; }
        else { _assetsLibrary = [library retain]; }
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(libraryDidChange:)
         name:ALAssetsLibraryChangedNotification
         object:_assetsLibrary];
    }
    return self;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:ALAssetsLibraryChangedNotification
     object:_assetsLibrary];
    [_assetsLibrary release];
    _assetsLibrary = nil;
    self.view = nil;
    [super dealloc];
}
- (void)reloadData {
    
}
- (void)libraryDidChange:(NSNotification *)notif {
    [self reloadData];
}

@end
