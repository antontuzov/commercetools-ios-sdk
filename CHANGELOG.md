# Change Log
All changes to this project will be documented in this file.

#### 0.x Releases
- `0.5.x` Releases - [0.5.0](#050) | [0.5.1](#051) | [0.5.2](#052) | [0.5.3](#053) | [0.5.4](#054) | [0.5.5](#055) | [0.5.6](#056)
- `0.4.x` Releases - [0.4.0](#040) | [0.4.1](#041) | [0.4.2](#042)
- `0.3.x` Releases - [0.3.0](#030)
- `0.2.x` Releases - [0.2.0](#020)
- `0.1.x` Releases - [0.1.0](#010)
- `0.0.x` Releases - [0.0.1](#001) | [0.0.2](#002) | [0.0.3](#003)

---

## [0.5.6](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.5.6)
Released on 2017-03-20.

#### Added
- Support for `ShippingMethod` endpoint.

## [0.5.5](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.5.5)
Released on 2017-03-01.

#### Added
- Public modifier for the dictionary config initializer.

#### Updated
- Scope to be optional configuration parameter.
- Improved WatchConnectivity communication.

## [0.5.4](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.5.4)
Released on 2017-02-20.

#### Added
- `taxRoundingMode` field to `Cart` and `Order` endpoints.
- Support for multiple filters for product projection search.
- `deleteDaysAfterLastModification` to the `Cart` endpoint.
- Fixes for Swift Package Manager.

## [0.5.3](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.5.3)
Released on 2017-01-23.

#### Added
- Support for `Category` assets.
- `productType` reference for cart line items.

## [0.5.2](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.5.2)
Released on 2017-01-02.

#### Added
- `shippingAddressIds` and `billingAddressIds` to `Customer` model.
- Update actions for `addShippingAddressId`, `removeShippingAddressId`, `addBillingAddressId`, and `removeBillingAddressId`.
- Extensions parameter for `Customer` profile endpoint.
- `geoLocation` field to `Channel` model.

## [0.5.1](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.5.1)
Released on 2016-12-09.

#### Added
- Token sharing between `iOS` and `watchOS` app using WatchConnectivity.

#### Updated
- Updated User-Agent header to properly identify newly added platforms.

## [0.5.0](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.5.0)
Released on 2016-11-27.

#### Added
- Support for `watchOS`, `tvOS`, and `macOS` platforms.

## [0.4.2](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.4.2)
Released on 2016-11-09.

#### Added
- Support for keychain sharing configuration when using the SDK for multiple apps, or apps and extension(s).
- `externalId` to the Address struct.
- `ProductProjection` endpoint now conforms to `ByKeyEndpoint` protocol.

## [0.4.1](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.4.1)
Released on 2016-10-31.

#### Added
- Support for carts and orders migration on successful log in or sign up, if using an anonymous session.
- Centralized customer authorization methods.

#### Removed
- Direct access to `AuthManager` `login` and `logut` method. From now on, `Commercetools.loginCustomer` and `Commercetools.logoutCustomer` should be used.
- Direct access to `Customer` `signUp` method. From now on, `Commercetools.signUpCustomer` should be used.

## [0.4.0](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.4.0)
Released on 2016-10-25.

#### Added
- Updated `Endpoint` protocol and `Result` enum to support model objects.
- Updated `Create`, `Delete`, `ById`, `ByKey`, and `UpdateByKey` endpoints to support models.
- Support for obtaining model and JSON dictionary results
- Added `NoMapping` type for easy endpoint creation where no domain model exists.
- `Cart`, `Category`, `Customer`, `Order`, `ProductProjection`, `ProductType` response models.
- Draft models for creating resources on `Cart`, `Customer`, and `Order` endpoint.
- Actions for updating `Cart` and `Customer` objects.
- Updated User-Agent header format.

## [0.3.0](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.3.0)
Released on 2016-09-23.

#### Added
- Migrated codebase to Swift 3.
- Introduced `CTError` type providing more flexible error handling.
- Updated project for Alamofire v4.0.

## [0.2.0](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.2.0)
Released on 2016-07-08.

#### Added
- Support for retrieving active cart.
- Anonymous sessions support, with flexible configuration.
- Multi target app support.
- Improved error handling.

## [0.1.0](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.1.0)
Released on 2016-05-12.

#### Added
- Product projections search functionality.
- Suggestions from product projections endpoint.
- Support for Swift package manager.
- Product type endpoint.
- Support for categories endpoint.

## [0.0.3](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.0.3)
Released on 2016-05-06.

#### Added
- Support for byKey retrieve and update endpoints.
- Customer profile endpoint and sign up.
- Advanced customer actions - account verification, password reset.
- Support for orders endpoint.
- Product projection endpoint query and retrieval functionality.

## [0.0.2](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.0.2)
Released on 2016-04-28.

#### Added
- Complete shopping cart support.
- Support for query endpoints.
- Support for byId endpoints.
- Support for delete endpoints.
- Support for create endpoints.

## [0.0.1](https://github.com/commercetools/commercetools-ios-sdk/releases/tag/0.0.1)
Released on 2016-04-21.

#### Added
- Initial release of the Commercetools SDK.
- Easy and customizable commercetools project configuration.
- Authentication manager completely abstracting away the entire auth process.