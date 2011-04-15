//
//  GCImageBrowserController_iPad.m
//  GUI Cocoa Common Code Library for iOS
//
//  Created by Caleb Davenport on 3/31/11.
//  Copyright 2011 GUI Cocoa, LLC. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "GCImageBrowserViewController.h"
#import "GCImageBrowserViewController_iPad.h"

#define kGreyOutViewTag 100

@interface GCImageBrowserViewController_iPad (private)

// update toolbar items
- (void)updateToolbarItemsForOrientation:(UIInterfaceOrientation)orientation;
- (void)updateToolbarItems;

// update view layout
- (void)updateViewLayoutForOrientation:(UIInterfaceOrientation)orientation;
- (void)updateViewLayout;

// release resources
- (void)cleanup;

// get standard button items
- (UIBarButtonItem *)popoverButtonItem;
- (UIBarButtonItem *)flexibleSpaceButtonItem;

@end

@implementation GCImageBrowserViewController_iPad (private)
- (void)updateToolbarItemsForOrientation:(UIInterfaceOrientation)orientation {
    NSMutableArray *array = [NSMutableArray array];
    if (gridController.editing) {
        if (gridController.actionButtonItem) {
            [array addObject:gridController.actionButtonItem];
        }
        [array addObject:[self flexibleSpaceButtonItem]];
        [array addObject:gridController.cancelButtonItem];
    }
    else {
        
        // done button
        {
            UIBarButtonItem *item = [[UIBarButtonItem alloc]
                                     initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                     target:self
                                     action:@selector(doneAction)];
            [array addObject:item];
            [item release];
        }
        
        // popover button
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            UIBarButtonItem *item = [[UIBarButtonItem alloc]
                                     initWithTitle:listController.title
                                     style:UIBarButtonItemStyleBordered
                                     target:self
                                     action:@selector(popoverAction:)];
            [array addObject:item];
            [item release];
        }
        
        // space
        [array addObject:[self flexibleSpaceButtonItem]];
        
        // select button
        if (gridController.selectButtonItem) {
            [array addObject:gridController.selectButtonItem];
        }
        
    }
    self.toolbar.items = array;
}
- (void)updateToolbarItems {
    [self updateToolbarItemsForOrientation:self.interfaceOrientation];
}
- (void)updateViewLayoutForOrientation:(UIInterfaceOrientation)orientation {
    CGFloat originY = self.toolbar.bounds.size.height;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        self.leftView.frame = CGRectMake(0, originY, self.leftView.bounds.size.width, self.view.bounds.size.height - originY);
        self.rightView.frame = CGRectMake(320.0, originY, self.view.bounds.size.width - 320.0, self.view.bounds.size.height - originY);
    }
    else {
        self.leftView.frame = CGRectMake(-320.0, originY, self.leftView.bounds.size.width, self.view.bounds.size.height - originY);
        self.rightView.frame = CGRectMake(0, originY, self.view.bounds.size.width, self.view.bounds.size.height - originY);
    }
}
- (void)updateViewLayout {
    [self updateViewLayoutForOrientation:self.interfaceOrientation];
}
- (void)cleanup {
    [popoverController dismissPopoverAnimated:NO];
    [popoverController release];
    popoverController = nil;
    [gridController removeObserver:self forKeyPath:@"editing"];
    [gridController removeObserver:self forKeyPath:@"title"];
    [gridController removeObserver:self forKeyPath:@"actionButtonItem"];
    [gridController release];
    gridController = nil;
    [listController release];
    listController = nil;
    self.leftView = nil;
    self.rightView = nil;
}
- (UIBarButtonItem *)popoverButtonItem {
    return [[[UIBarButtonItem alloc]
             initWithTitle:listController.title
             style:UIBarButtonItemStyleBordered
             target:self
             action:@selector(popoverAction:)]
            autorelease];
}
- (UIBarButtonItem *)flexibleSpaceButtonItem {
    return [[[UIBarButtonItem alloc]
             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
             target:nil
             action:nil]
            autorelease];
}
@end

@implementation GCImageBrowserViewController_iPad

@synthesize dataSource=_dataSource;
@synthesize leftView=_leftView;
@synthesize rightView=_rightView;
@synthesize toolbar=_toolbar;
@synthesize titleLabel=_titleLabel;

#pragma mark - object lifecycle
- (id)init {
    self = [super initWithNibName:@"GCImageBrowserViewController_iPad" bundle:nil];
    if (self) {
        [self
         addObserver:self
         forKeyPath:@"title"
         options:0
         context:nil];
    }
    return self;
}
- (void)dealloc {
    [self removeObserver:self forKeyPath:@"title"];
    [self cleanup];
    [super dealloc];
}

#pragma mark - view lifecycle
- (void)viewDidLoad {
    
    // super
    [super viewDidLoad];
        
    // make list view
    listController = [[GCImageListBrowserController alloc] init];
    listController.view.frame = self.leftView.bounds;
    listController.view.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    listController.dataSource = self.dataSource;
    listController.delegate = self;
    listController.showDisclosureIndicator = NO;
    [listController reloadData];
    [self.leftView addSubview:listController.view];
    
    // set asset group view
    NSArray *groups = listController.assetsGroups;
    if ([groups count]) {
        ALAssetsGroup *group = [listController.assetsGroups objectAtIndex:0];
        [self listBrowser:listController didSelectAssetGroup:group];
    }
    
}
- (void)viewDidUnload {
    [super viewDidUnload];
    [self cleanup];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self updateViewLayout];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.toolbar setNeedsLayout];
    [gridController.tableView flashScrollIndicators];
    [listController.tableView flashScrollIndicators];
}

#pragma mark - list browser delegate
- (void)listBrowser:(GCImageListBrowserController *)controller didSelectAssetGroup:(ALAssetsGroup *)group {
    
    // dsimiss popover
    [popoverController dismissPopoverAnimated:YES];
    [popoverController release];
    popoverController = nil;
    
    // get group stuff
    NSString *groupID = [group valueForProperty:ALAssetsGroupPropertyPersistentID];
    
    // unload old view
    [gridController.view removeFromSuperview];
    [gridController removeObserver:self forKeyPath:@"editing"];
    [gridController removeObserver:self forKeyPath:@"title"];
    [gridController removeObserver:self forKeyPath:@"actionButtonItem"];
    [gridController release];
    
    // make new view
    gridController = [[GCImageGridBrowserController alloc] initWithAssetsGroupIdentifier:groupID];
    [gridController addObserver:self forKeyPath:@"editing" options:0 context:nil];
    [gridController addObserver:self forKeyPath:@"title" options:0 context:nil];
    [gridController addObserver:self forKeyPath:@"actionButtonItem" options:0 context:nil];
    gridController.view.frame = self.rightView.bounds;
    gridController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    gridController.dataSource = self.dataSource;
    gridController.numberOfAssetsPerRow = 6;
    gridController.assetViewPadding = 10.0;
    gridController.tableView.contentInset = UIEdgeInsetsMake(gridController.assetViewPadding, 0, 0, 0);
    [gridController reloadData];
    [self.rightView addSubview:gridController.view];
    
    // update interface
    [self updateToolbarItems];
    [self updateViewLayout];
    NSIndexPath *indexPath = [controller.tableView indexPathForSelectedRow];
    [controller.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - view roration
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    
    // update toolbar
    if ([self isViewLoaded]) { [self updateToolbarItemsForOrientation:orientation]; }
    
    // make sure we aren't rotating to a similar orientation
    if (UIInterfaceOrientationIsPortrait(orientation) == UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        return;
    }
    
    // do stuff depending on the new orientation
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        [popoverController dismissPopoverAnimated:NO];
        [popoverController release];
        popoverController = nil;
        listController.view.frame = self.leftView.bounds;
        [self.leftView addSubview:listController.view];
        [self.leftView sendSubviewToBack:listController.view];
    }
        
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration {
    [self updateViewLayoutForOrientation:orientation];
}

#pragma mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self && [keyPath isEqualToString:@"title"]) {
        self.titleLabel.text = self.title;
    }
    else if (object == gridController && [keyPath isEqualToString:@"editing"]) {
        [self updateToolbarItems];
        [popoverController dismissPopoverAnimated:YES];
        [popoverController release];
        popoverController = nil;
        if (gridController.editing) {
            UIView *greyOut = [[UIView alloc] initWithFrame:self.leftView.bounds];
            greyOut.backgroundColor = [UIColor blackColor];
            greyOut.alpha = 0.0;
            greyOut.tag = kGreyOutViewTag;
            greyOut.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
            [self.leftView addSubview:greyOut];
            [UIView
             animateWithDuration:0.3
             animations:^{
                 greyOut.alpha = 0.5;
             }];
            [greyOut release];
        }
        else {
            UIView *greyOut = [self.leftView viewWithTag:kGreyOutViewTag];
            [UIView
             animateWithDuration:0.3
             animations:^{
                 greyOut.alpha = 0.0;
             }
             completion:^(BOOL finished){
                 [greyOut removeFromSuperview];
             }];
        }
    }
    else if (object == gridController && [keyPath isEqualToString:@"title"]) {
        self.title = gridController.title;
    }
    else if (object == gridController && [keyPath isEqualToString:@"actionButtonItem"]) {
        [self updateToolbarItems];
    }
}

#pragma mark - button actions
- (void)doneAction {
    [self dismissModalViewControllerAnimated:YES];
}
- (void)popoverAction:(UIBarButtonItem *)sender {
    if (popoverController == nil) {
        GCImageBrowserViewController *controller = [[GCImageBrowserViewController alloc] init];
        controller.browser = listController;
        popoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
        popoverController.delegate = self;
        [popoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        [controller release];
    }
}

#pragma mark - popover delegate
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popover {
    if (popover == popoverController) {
        [popoverController release];
        popoverController = nil;
    }
}

@end