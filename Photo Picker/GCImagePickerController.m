//
//  QSPhotoPickerController.m
//  GUI Cocoa Common Code Library for iOS
//
//  Created by Caleb Davenport on 2/14/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>

#import "GCImagePickerController.h"
#import "GCImageListBrowserController.h"
#import "GCImageGridBrowserController.h"

@implementation GCImagePickerController

#pragma mark - class methods
+ (GCImagePickerController *)pickerWithSourceType:(UIImagePickerControllerSourceType)source {
    if (source == UIImagePickerControllerSourceTypePhotoLibrary) {
        return [[[GCImageListBrowserController alloc] init] autorelease];
    }
    else if (source == UIImagePickerControllerSourceTypeSavedPhotosAlbum) {
        GCImagePickerController *picker = [[GCImageGridBrowserController alloc]
                                           initWithAssetsGroupTypes:ALAssetsGroupSavedPhotos
                                           title:GCImagePickerControllerLocalizedString(@"CAMERA_ROLL")
                                           groupID:nil];
        return [picker autorelease];
    }
    else {
        [NSException
         raise:NSInvalidArgumentException
         format:@"%@ does not support the specified source type.", NSStringFromClass(self)];
        return nil;
    }
}
+ (NSData *)dataForAssetRepresentation:(ALAssetRepresentation *)rep {
    [rep retain];
    long long size = [rep size], offset = 0;
    NSMutableData *data = [NSMutableData dataWithCapacity:size];
    while (offset < size) {
        uint8_t bytes[1024];
        NSError *error = nil;
        NSUInteger written = [rep getBytes:bytes fromOffset:offset length:1024 error:&error];
        if (error != nil) {
			GC_LOG_ERROR(@"%@", error);
			data = nil;
			break;
		}
        [data appendBytes:bytes length:written];
        offset += written;
    }
    [rep release];
    return data;
}
+ (void)writeDataForAssetRepresentation:(ALAssetRepresentation *)rep toFile:(NSString *)path atomically:(BOOL)atomically {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return;
    }
    [rep retain];
	NSString *writePath = path;
	if (atomically) {
		writePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[path lastPathComponent]];
	}
	[[NSFileManager defaultManager] createFileAtPath:writePath contents:nil attributes:nil];
	NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:writePath];
	long long size = [rep size], offset = 0;
	while (offset < size) {
		NSMutableData *buffer = [NSMutableData dataWithLength:1024];
		NSError *error = nil;
		NSUInteger written = [rep getBytes:[buffer mutableBytes] fromOffset:offset length:1024 error:&error];
        if (error != nil) {
			GC_LOG_ERROR(@"%@", error);
			[handle closeFile];
			[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
			break;
		}
		[handle writeData:[buffer subdataWithRange:NSMakeRange(0, written)]];
		offset += written;
	}
	[handle closeFile];
	if (atomically) {
		[[NSFileManager defaultManager] moveItemAtPath:writePath toPath:path error:nil];
	}
    [rep release];
}
+ (NSString *)extensionForAssetRepresentation:(ALAssetRepresentation *)rep {
    NSString *UTI = [rep UTI];
    if (UTI == nil) {
        GC_LOG_ERROR(@"Missing UTI for asset representation %@", UTI);
        return nil;
    }
    else {
        return [GCImagePickerController extensionForUTI:(CFStringRef)UTI];
    }
}
+ (NSString *)extensionForUTI:(CFStringRef)UTI {
    if (UTI == NULL) {
        GC_LOG_WARN(@"Requested extension for nil UTI");
        return nil;
    }
    else if (CFStringCompare(UTI, kUTTypeJPEG, 0) == kCFCompareEqualTo) {
        return @"jpg";
    }
    else {
        CFStringRef extension = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassFilenameExtension);
        if (extension == NULL) {
            GC_LOG_ERROR(@"Missing extension for UTI %@", (NSString *)UTI);
            return nil;
        }
        else {
            return [(NSString *)extension autorelease];
        }
    }
}

@synthesize actionBlock=_actionBlock;
@synthesize actionTitle=_actionTitle;
@synthesize actionEnabled=_actionEnabled;
@synthesize failureBlock=_failureBlock;
@synthesize mediaTypes=_mediaTypes;

#pragma mark - object lifecycle
- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)bundle {
    self = [super initWithNibName:name bundle:bundle];
    if (self) {
        if (GC_IS_IPAD) { self.contentSizeForViewInPopover = CGSizeMake(320, 460); }
		else { self.wantsFullScreenLayout = YES; }
        self.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        _failureBlock = Block_copy(^(NSError *error){
            GC_LOG_ERROR(@"%@", error);
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:GCImagePickerControllerLocalizedString(@"LOCATION_SERVICES")
                                  message:GCImagePickerControllerLocalizedString(@"PHOTO_ROLL_LOCATION_ERROR")
                                  delegate:nil
                                  cancelButtonTitle:GCImagePickerControllerLocalizedString(@"OK")
                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        });
    }
    return self;
}
- (void)dealloc {
    Block_release(_failureBlock);_failureBlock = nil;
    self.actionBlock = nil;
    self.actionTitle = nil;
    self.mediaTypes = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - object methods
- (void)presentFromViewController:(UIViewController *)controller {
    if (GC_IS_IPAD) {
		[NSException
		 raise:NSInternalInconsistencyException
		 format:@"%s should not be called on iPad", __PRETTY_FUNCTION__];
	}
	UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self];
	[nav.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
	[controller presentModalViewController:nav animated:YES];
	[nav release];
}
- (UIPopoverController *)popoverController {
    if (!GC_IS_IPAD) {
		[NSException
		 raise:NSInternalInconsistencyException
		 format:@"%s should not be called on iPhone", __PRETTY_FUNCTION__];
	}
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:self];
    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:nav];
    [nav release];
    return [popover autorelease];
}
- (ALAssetsFilter *)assetsFilter {
    BOOL images = [self.mediaTypes containsObject:(NSString *)kUTTypeImage];
    BOOL videos = [self.mediaTypes containsObject:(NSString *)kUTTypeVideo];
    if (images && videos) { return [ALAssetsFilter allAssets]; }
    else if (videos) { return [ALAssetsFilter allVideos]; }
    else { return [ALAssetsFilter allPhotos]; }
}

@end
