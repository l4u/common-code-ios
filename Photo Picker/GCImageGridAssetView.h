//
//  GCImageGridAssetView.h
//  QuickShot
//
//  Created by Caleb Davenport on 3/17/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface GCImageGridAssetView : UIView {
    
}

@property (nonatomic, retain) ALAsset *asset;
@property (nonatomic, assign) BOOL selected;

@end