//
//  AddCourseViewController.m
//  Manager
//
//  Created by Dylan Lewis on 23/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "AddCourseViewController.h"
#import <Parse/Parse.h>

@interface AddCourseViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *foodOrDrinkControl;
@property (weak, nonatomic) IBOutlet UITextField *courseNameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation AddCourseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_courseNameTextField setPlaceholder:@"course name"];
    [_courseNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [_courseNameTextField setAutocorrectionType:UITextAutocorrectionTypeYes];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didTouchCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTouchDoneButton:(id)sender {
    NSString *name=[_courseNameTextField text];
    NSString *type;
    
    if (_foodOrDrinkControl.selectedSegmentIndex==0) {
        type = @"Food";
    } else {
        type = @"Drink";
    }
    
    [self createNewCourseWithName:name withType:type];
}

- (IBAction)didChangeFoodOrDrinkSetting:(id)sender {
    if (_foodOrDrinkControl.selectedSegmentIndex==0) {
        [_imageView setImage:[UIImage imageNamed:@"plate-and-cutlery-red"]];
    } else {
        [_imageView setImage:[UIImage imageNamed:@"wine-glass"]];
    }
}

#pragma mark - Parse

- (void)createNewCourseWithName:(NSString *)name withType:(NSString *)type {
    PFObject *object = [PFObject objectWithClassName:@"Course"];
    object[@"name"]=name;
    object[@"type"]=type;
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [object setACL:acl];
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Refresh the table when the object is done saving.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedCourse" object:nil];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

@end
