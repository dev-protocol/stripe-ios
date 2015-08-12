//
//  PaymentViewController.m
//
//  Created by Alex MacCaw on 2/14/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "ViewController.h"
#import "MBProgressHUD.h"

#import "PaymentViewController.h"

@interface PaymentViewController () <STPPaymentCardTextFieldDelegate>
@property (weak, nonatomic) STPPaymentCardTextField *paymentView;
@end

@implementation PaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Checkout";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    // Setup save button
    NSString *title = [NSString stringWithFormat:@"Pay $%@", self.amount];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:self action:@selector(save:)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    saveButton.enabled = NO;
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = saveButton;

    // Setup checkout
    STPPaymentCardTextField *paymentView = [[STPPaymentCardTextField alloc] initWithFrame:CGRectMake(15, 20, 345, 44)];
    paymentView.delegate = self;
    paymentView.placeholderColor = [UIColor lightGrayColor];
    self.paymentView = paymentView;
    [self.view addSubview:paymentView];
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = textField.isValid;
}

- (void)cancel:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)save:(id)sender {
    [self.paymentView resignFirstResponder];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.paymentView clear];
    });
//    if (![self.paymentView isValid]) {
//        return;
//    }
//    if (![Stripe defaultPublishableKey]) {
//        NSError *error = [NSError errorWithDomain:StripeDomain
//                                             code:STPInvalidRequestError
//                                         userInfo:@{
//                                             NSLocalizedDescriptionKey: @"Please specify a Stripe Publishable Key in Constants.m"
//                                         }];
//        [self.delegate paymentViewController:self didFinish:error];
//        return;
//    }
//    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//    STPCard *card = [[STPCard alloc] init];
//    card.number = self.paymentView.card.number;
//    card.expMonth = self.paymentView.card.expMonth;
//    card.expYear = self.paymentView.card.expYear;
//    card.cvc = self.paymentView.card.cvc;
//    [[STPAPIClient sharedClient] createTokenWithCard:card
//                                          completion:^(STPToken *token, NSError *error) {
//                                              [MBProgressHUD hideHUDForView:self.view animated:YES];
//                                              if (error) {
//                                                  [self.delegate paymentViewController:self didFinish:error];
//                                              }
//                                              [self.backendCharger createBackendChargeWithToken:token
//                                                                                     completion:^(STPBackendChargeResult result, NSError *error) {
//                                                                                         if (error) {
//                                                                                             [self.delegate paymentViewController:self didFinish:error];
//                                                                                             return;
//                                                                                         }
//                                                                                         [self.delegate paymentViewController:self didFinish:nil];
//                                                                                     }];
//                                          }];
}

@end
