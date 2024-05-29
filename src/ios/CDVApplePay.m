#import "CDVApplePay.h"
@import PassKit;

@implementation CDVApplePay

@synthesize paymentCallbackId;

- (void)canMakePayments:(CDVInvokedUrlCommand*)command
{
    if ([PKPaymentAuthorizationController canMakePayments]) {
        if (@available(iOS 9.0, *)) {
            if (command.arguments[0] != [NSNull null] && [command.arguments[0] objectForKey:@"supportedNetworks"] != nil) {
                if ([command.arguments[0] objectForKey:@"merchantCapabilities"] != nil) {
                    if ([PKPaymentAuthorizationController
                            canMakePaymentsUsingNetworks:[self supportedNetworksFromArguments:command.arguments]
                                            capabilities:[self merchantCapabilitiesFromArguments:command.arguments]]) {
                        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"This device can make payments and has a supported card."];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                        return;
                    } else {
                        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device can make payments but has no supported card."];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                        return;
                    }
                } else { // merchantCapabilities is nil
                    if ([PKPaymentAuthorizationController canMakePaymentsUsingNetworks:[self supportedNetworksFromArguments:command.arguments]]) {
                        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"This device can make payments and has a supported card."];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                        return;
                    } else {
                        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device can make payments but has no supported card."];
                        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                        return;
                    }
                }
            } else { // supportedNetworks is nil
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"This device can make payments."];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            }
        } else {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device cannot make payments."];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device cannot make payments."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
}

- (NSString *)countryCodeFromArguments:(NSArray *)arguments
{
    NSString *countryCode = [[arguments objectAtIndex:0] objectForKey:@"countryCode"];
    return countryCode;
}

- (NSString *)merchantIdentifierFromArguments:(NSArray *)arguments
{
    NSString *merchantIdentifier = [[arguments objectAtIndex:0] objectForKey:@"merchantIdentifier"];
    return merchantIdentifier;
}

- (NSString *)currencyCodeFromArguments:(NSArray *)arguments
{
    NSString *currencyCode = [[arguments objectAtIndex:0] objectForKey:@"currencyCode"];
    return currencyCode;
}

- (PKShippingType)shippingTypeFromArguments:(NSArray *)arguments
{
    NSString *shippingType = [[arguments objectAtIndex:0] objectForKey:@"shippingType"];

    if ([shippingType isEqualToString:@"shipping"]) {
        return PKShippingTypeShipping;
    } else if ([shippingType isEqualToString:@"delivery"]) {
        return PKShippingTypeDelivery;
    } else if ([shippingType isEqualToString:@"store"]) {
        return PKShippingTypeStorePickup;
    } else if ([shippingType isEqualToString:@"service"]) {
        return PKShippingTypeServicePickup;
    }

    return PKShippingTypeShipping;
}

- (NSSet<PKContactField> *)shippingAddressRequirementFromArguments:(NSArray *)arguments
{
    NSArray *shippingAddressRequirements = [[arguments objectAtIndex:0] objectForKey:@"shippingAddressRequirement"];
    NSMutableSet<PKContactField> *requiredFields = [NSMutableSet set];

    for (id requirement in shippingAddressRequirements) {
        if ([requirement isKindOfClass:[NSString class]]) {
            if ([requirement isEqualToString:@"all"]) {
                [requiredFields addObjectsFromArray:@[PKContactFieldPostalAddress, PKContactFieldName, PKContactFieldEmailAddress, PKContactFieldPhoneNumber]];
            } else if ([requirement isEqualToString:@"postcode"]) {
                [requiredFields addObject:PKContactFieldPostalAddress];
            } else if ([requirement isEqualToString:@"name"]) {
                [requiredFields addObject:PKContactFieldName];
            } else if ([requirement isEqualToString:@"email"]) {
                [requiredFields addObject:PKContactFieldEmailAddress];
            } else if ([requirement isEqualToString:@"phone"]) {
                [requiredFields addObject:PKContactFieldPhoneNumber];
            }
        }
    }

    return [requiredFields copy];
}

- (NSSet<PKContactField> *)billingAddressRequirementFromArguments:(NSArray *)arguments
{
    NSArray *billingAddressRequirement = [[arguments objectAtIndex:0] objectForKey:@"billingAddressRequirement"];
    NSMutableSet<PKContactField> *requiredFields = [NSMutableSet set];

    for (id requirement in billingAddressRequirement) {
        if ([requirement isKindOfClass:[NSString class]]) {
            if ([requirement isEqualToString:@"all"]) {
                [requiredFields addObjectsFromArray:@[PKContactFieldPostalAddress, PKContactFieldName, PKContactFieldEmailAddress, PKContactFieldPhoneNumber]];
            } else if ([requirement isEqualToString:@"postcode"]) {
                [requiredFields addObject:PKContactFieldPostalAddress];
            } else if ([requirement isEqualToString:@"name"]) {
                [requiredFields addObject:PKContactFieldName];
            } else if ([requirement isEqualToString:@"email"]) {
                [requiredFields addObject:PKContactFieldEmailAddress];
            } else if ([requirement isEqualToString:@"phone"]) {
                [requiredFields addObject:PKContactFieldPhoneNumber];
            }
        }
    }

    return [requiredFields copy];
}


- (NSArray *)itemsFromArguments:(NSArray *)arguments
{
    NSArray *itemDescriptions = [[arguments objectAtIndex:0] objectForKey:@"items"];

    NSMutableArray *items = [[NSMutableArray alloc] init];

    for (NSDictionary *item in itemDescriptions) {

        NSString *label = [item objectForKey:@"label"];

        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[[item objectForKey:@"amount"] decimalValue]];

        PKPaymentSummaryItem *newItem = [PKPaymentSummaryItem summaryItemWithLabel:label amount:amount];

        [items addObject:newItem];
    }

    return items;
}

- (PKMerchantCapability)merchantCapabilitiesFromArguments:(NSArray *)arguments
{
    NSArray *capabilities = [arguments[0] objectForKey:@"merchantCapabilities"];

    PKMerchantCapability merchantCapability = 0;

    for (NSString *capability in capabilities) {
        if ([capability isEqualToString:@"3ds"]) {
            merchantCapability |= PKMerchantCapability3DS;
        } else if ([capability isEqualToString:@"credit"]) {
            merchantCapability |= PKMerchantCapabilityCredit;
        } else if ([capability isEqualToString:@"debit"]) {
            merchantCapability |= PKMerchantCapabilityDebit;
        } else if ([capability isEqualToString:@"emv"]) {
            merchantCapability |= PKMerchantCapabilityEMV;
        }
    }

    return merchantCapability;
}

- (NSArray<NSString *>*)supportedNetworksFromArguments:(NSArray *)arguments
{
    NSArray *networks = [arguments[0] objectForKey:@"supportedNetworks"];

    NSMutableArray<NSString *>* paymentNetworks = [[NSMutableArray alloc] init];

    for (NSString *network in networks) {
        if ([network isEqualToString:@"visa"]) {
            [paymentNetworks addObject:PKPaymentNetworkVisa];
        } else if ([network isEqualToString:@"discover"]) {
            [paymentNetworks addObject:PKPaymentNetworkDiscover];
        } else if ([network isEqualToString:@"masterCard"]) {
            [paymentNetworks addObject:PKPaymentNetworkMasterCard];
        } else if ([network isEqualToString:@"amex"]) {
            [paymentNetworks addObject:PKPaymentNetworkAmex];
        }
        // TODO: add the rest
    }

    return paymentNetworks;
}

- (NSArray *)shippingMethodsFromArguments:(NSArray *)arguments
{
    NSArray *shippingDescriptions = [[arguments objectAtIndex:0] objectForKey:@"shippingMethods"];

    NSMutableArray *shippingMethods = [[NSMutableArray alloc] init];

    for (NSDictionary *desc in shippingDescriptions) {

        NSString *identifier = [desc objectForKey:@"identifier"];
        NSString *detail = [desc objectForKey:@"detail"];
        NSString *label = [desc objectForKey:@"label"];

        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[[desc objectForKey:@"amount"] decimalValue]];

        PKShippingMethod *newMethod = [PKShippingMethod summaryItemWithLabel:label amount:amount];
        newMethod.identifier = identifier;
        newMethod.detail = detail;

        [shippingMethods addObject:newMethod];
    }

    return shippingMethods;
}

- (PKPaymentAuthorizationStatus)paymentAuthorizationStatusFromArgument:(NSString *)argument
{
    if ([argument isEqualToString:@"success"]) {
        return PKPaymentAuthorizationStatusSuccess;
    } else if ([argument isEqualToString:@"failure"]) {
        return PKPaymentAuthorizationStatusFailure;
    } else if ([argument isEqualToString:@"invalid-billing-address"]) {
        return PKPaymentAuthorizationStatusInvalidBillingPostalAddress;
    } else if ([argument isEqualToString:@"invalid-shipping-address"]) {
        return PKPaymentAuthorizationStatusInvalidShippingPostalAddress;
    } else if ([argument isEqualToString:@"invalid-shipping-contact"]) {
        return PKPaymentAuthorizationStatusInvalidShippingContact;
    } else if ([argument isEqualToString:@"require-pin"]) {
        return PKPaymentAuthorizationStatusPINRequired;
    } else if ([argument isEqualToString:@"incorrect-pin"]) {
        return PKPaymentAuthorizationStatusPINIncorrect;
    } else if ([argument isEqualToString:@"locked-pin"]) {
        return PKPaymentAuthorizationStatusPINLockout;
    }

    return PKPaymentAuthorizationStatusFailure;
}

- (void)makePaymentRequest:(CDVInvokedUrlCommand*)command
{
    if (![PKPaymentAuthorizationController canMakePayments]) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"This device cannot make payments."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    paymentRequest.merchantIdentifier = [self merchantIdentifierFromArguments:command.arguments];
    paymentRequest.countryCode = [self countryCodeFromArguments:command.arguments];
    paymentRequest.currencyCode = [self currencyCodeFromArguments:command.arguments];
    paymentRequest.supportedNetworks = [self supportedNetworksFromArguments:command.arguments];
    paymentRequest.merchantCapabilities = [self merchantCapabilitiesFromArguments:command.arguments];
    paymentRequest.paymentSummaryItems = [self itemsFromArguments:command.arguments];
    paymentRequest.requiredBillingContactFields = [self billingAddressRequirementFromArguments:command.arguments];
    paymentRequest.requiredShippingContactFields = [self shippingAddressRequirementFromArguments:command.arguments];
    paymentRequest.shippingMethods = [self shippingMethodsFromArguments:command.arguments];
    paymentRequest.shippingType = [self shippingTypeFromArguments:command.arguments];

    self.paymentCallbackId = command.callbackId;

    if (@available(iOS 12.0, *)) {
        PKPaymentAuthorizationController *paymentAuthorizationController = [[PKPaymentAuthorizationController alloc] initWithPaymentRequest:paymentRequest];
        paymentAuthorizationController.delegate = self;
        [paymentAuthorizationController presentWithCompletion:^(BOOL success) {
            if (!success) {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Error presenting payment sheet."];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            }
        }];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Apple Pay is not supported on this device."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }
}

- (void)paymentAuthorizationController:(PKPaymentAuthorizationController *)controller
                   didAuthorizePayment:(PKPayment *)payment
                            completion:(void (^)(PKPaymentAuthorizationResult *result))completion
{
    NSMutableDictionary *paymentResponse = [[NSMutableDictionary alloc] init];
    [paymentResponse setObject:payment.token.transactionIdentifier forKey:@"transactionIdentifier"];
    [paymentResponse setObject:[NSString stringWithUTF8String:payment.token.paymentData.bytes] forKey:@"paymentData"];

    NSMutableDictionary *billingContact = [[NSMutableDictionary alloc] init];
    billingContact[@"emailAddress"] = payment.billingContact.emailAddress;
    billingContact[@"phoneNumber"] = payment.billingContact.phoneNumber.stringValue;
    billingContact[@"name"] = [NSString stringWithFormat:@"%@ %@", payment.billingContact.name.givenName, payment.billingContact.name.familyName];
    billingContact[@"address"] = payment.billingContact.postalAddress.street;
    billingContact[@"city"] = payment.billingContact.postalAddress.city;
    billingContact[@"state"] = payment.billingContact.postalAddress.state;
    billingContact[@"postalCode"] = payment.billingContact.postalAddress.postalCode;
    billingContact[@"country"] = payment.billingContact.postalAddress.country;
    [paymentResponse setObject:billingContact forKey:@"billingContact"];

    NSMutableDictionary *shippingContact = [[NSMutableDictionary alloc] init];
    shippingContact[@"emailAddress"] = payment.shippingContact.emailAddress;
    shippingContact[@"phoneNumber"] = payment.shippingContact.phoneNumber.stringValue;
    shippingContact[@"name"] = [NSString stringWithFormat:@"%@ %@", payment.shippingContact.name.givenName, payment.shippingContact.name.familyName];
    shippingContact[@"address"] = payment.shippingContact.postalAddress.street;
    shippingContact[@"city"] = payment.shippingContact.postalAddress.city;
    shippingContact[@"state"] = payment.shippingContact.postalAddress.state;
    shippingContact[@"postalCode"] = payment.shippingContact.postalAddress.postalCode;
    shippingContact[@"country"] = payment.shippingContact.postalAddress.country;
    [paymentResponse setObject:shippingContact forKey:@"shippingContact"];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:paymentResponse];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:self.paymentCallbackId];

    completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusSuccess errors:nil]);
}

- (void)paymentAuthorizationControllerDidFinish:(PKPaymentAuthorizationController *)controller
{
    [controller dismissWithCompletion:nil];
}

@end
