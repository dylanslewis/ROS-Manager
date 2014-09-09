//
//  SignupViewController.m
//  Manager
//
//  Created by Dylan Lewis on 08/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "SignupViewController.h"
#import <Parse/Parse.h>

@interface SignupViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *restaurantField;

@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation SignupViewController

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set the text field placeholders.
    [_usernameField setPlaceholder:@"username"];
    [_passwordField setPlaceholder:@"password"];
    [_emailField setPlaceholder:@"email address"];
    [_restaurantField setPlaceholder:@"restaurant name"];
    
    // Fix the keyboard and text entry types.
    [_usernameField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [_restaurantField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [_emailField setKeyboardType:UIKeyboardTypeEmailAddress];
    [_passwordField setSecureTextEntry:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didTouchSignupButton:(id)sender {
    // Get the text from the cells.
    NSString *username=[_usernameField text];
    NSString *password=[_passwordField text];
    NSString *email=[_emailField text];
    NSString *restaurant=[_restaurantField text];
    
    // Create the user.
    [self createNewUser:username withPassword:password withEmail:email withRestaurant:restaurant];
}

- (IBAction)didTouchCancelButton:(id)sender {
    // Dismiss the current view.
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Alert view handling

- (void)displayBasicAlertWithTitle:(NSString *)title withMessage:(NSString *)message {
    _alertView=[[UIAlertView alloc] initWithTitle:title
                                          message:message
                                         delegate:self
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil];
    [_alertView setAlertViewStyle:UIAlertViewStyleDefault];
    
    // Display the alert.
    [_alertView show];
}


#pragma mark - Parse

- (void)createNewUser:(NSString *)username withPassword:(NSString *)password withEmail:(NSString *)email withRestaurant:(NSString *)restaurant {
    NSString *errorTitle=@"";
    NSString *errorMessage=@"";
    
    BOOL localErrorsPresent=YES;
    
    // Deal with local errors.
    if ([self isEmptyString:username]) {
        errorTitle=@"Username not entered";
        errorMessage=@"Please enter a username";
    } else if ([self isEmptyString:password]) {
        errorTitle=@"Password not entered";
        errorMessage=@"Please enter a password";
    } else if ([self isEmptyString:email]) {
        errorTitle=@"Email address not entered";
        errorMessage=@"Please enter your email address";
    } else if ([self isEmptyString:restaurant]) {
        errorTitle=@"Restaurant name not entered";
        errorMessage=@"Please enter the name of your restaurant";
    } else if ([self isPasswordSecure:[_passwordField text]]) {
        errorTitle=@"Password not secure";
        errorMessage=@"Please ensure your password contains an uppercase letter, a lowercase letter, a number and is at least 8 characters long.";
    } else {
        localErrorsPresent=NO;
    }
    
    // If there are no local errors, try to create the user.
    if (!localErrorsPresent) {
        // Disable editing of the text cells.
        [_usernameField setUserInteractionEnabled:NO];
        [_passwordField setUserInteractionEnabled:NO];
        [_emailField setUserInteractionEnabled:NO];
        [_restaurantField setUserInteractionEnabled:NO];
        
        // Dismiss the keyboard.
        [_usernameField resignFirstResponder];
        [_passwordField resignFirstResponder];
        [_emailField resignFirstResponder];
        [_restaurantField resignFirstResponder];
        
        // Start the spinner and hide the 'signup' button.
        [_spinner startAnimating];
        [_signupButton setHidden:YES];
        
        // Create the new PFUser object.
        PFUser *user = [PFUser user];
        
        // Set the users's attributes.
        user.username = username;
        user.password = password;
        user.email = email;
        user[@"restaurant"] = restaurant;
        
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            NSString *errorTitle=@"";
            NSString *errorMessage=@"";
            
            // Hide the spinner.
            [_spinner stopAnimating];
            
            if (!error) {
                // Login was successful.
                NSLog(@"New restaurant added: %@", [user valueForKey:@"restaurant"]);
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                // Login failed.
                NSString *errorCode=[NSString stringWithFormat:@"%@", [[error userInfo] valueForKey:@"code"]];
                
                // Deal with unknown errors.
                if (![errorCode isEqualToString:@""]) {
                    errorTitle = @"Unknown error";
                    errorMessage = [[error userInfo] valueForKey:@"error"];
                }
                
                // Deal with username errors.
                if ([errorCode isEqualToString:@"202"]) {
                    // Username already taken.
                    [_usernameField setTextColor:[UIColor redColor]];
                    errorTitle = @"Username already taken";
                    errorMessage = @"Please enter a different username";
                } else {
                    // Reset to original colour.
                    [_usernameField setTextColor:[UIColor blackColor]];
                }
                
                // Deal with email address errors.
                if ([errorCode isEqualToString:@"125"]) {
                    // Invalid email address.
                    [_emailField setTextColor:[UIColor redColor]];
                    errorTitle = @"Invalid email address";
                    errorMessage = @"Please enter a valid email address";
                } else if ([errorCode isEqualToString:@"203"]) {
                    // Email address already taken.
                    [_emailField setTextColor:[UIColor redColor]];
                    errorTitle = @"Email address already taken";
                    errorMessage = @"Please enter a different email address";
                } else {
                    // Reset to original colour.
                    [_emailField setTextColor:[UIColor blackColor]];
                }
                
                // Display an alert detailing all the encountered errors.
                if (![errorMessage isEqualToString:@""]) {
                    [self displayBasicAlertWithTitle:errorTitle withMessage:errorMessage];
                }
                
                // Enable editing of the text cells.
                [_usernameField setUserInteractionEnabled:YES];
                [_passwordField setUserInteractionEnabled:YES];
                [_emailField setUserInteractionEnabled:YES];
                [_restaurantField setUserInteractionEnabled:YES];
                
                // Re-display the signup button.
                [_signupButton setHidden:NO];
            }
        }];
    } else {
        // Display local errors.
        [self displayBasicAlertWithTitle:errorTitle withMessage:errorMessage];
    }
}

#pragma mark - Basic operations

-(BOOL)isPasswordSecure:(NSString *)password {
    // A basic check that a password has the following characteristics:
    // - minimum of 8 letters
    // - minimum of 1 lowercase letter
    // - minimum of 1 uppercase letter
    // - minimum of 1 number.
    
    // Check that the length is >=8.
    if ([password length]<9) {
        return NO;
    }
    
    NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    NSRange range = [password rangeOfCharacterFromSet:characterSet];
    if (range.location == NSNotFound) {
        // No uppercase letter present.
        return NO;
    }
    
    characterSet = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz"];
    range = [password rangeOfCharacterFromSet:characterSet];
    if (range.location == NSNotFound) {
        // No lowercase letter present.
        return NO;
    }
    
    characterSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    range = [password rangeOfCharacterFromSet:characterSet];
    if (range.location == NSNotFound) {
        // No number present.
        return NO;
    }
    
    return YES;
}

- (BOOL)isEmptyString:(NSString *)string {
    // Method copied from: http://stackoverflow.com/questions/3436173/nsstring-is-empty
    // Returns YES if the string is nil or equal to @""
    // Note that [string length] == 0 can be false when [string isEqualToString:@""] is true, because these are Unicode strings.
    
    if (((NSNull *) string == [NSNull null]) || (string == nil) ) {
        return YES;
    }
    string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([string isEqualToString:@""]) {
        return YES;
    }
    
    return NO;
}

@end
