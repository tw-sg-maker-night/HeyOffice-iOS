# HeyOffice-iOS
iOS companion app for Hey Office

## Getting Started

### Dependencies

- Xcode 9+
- Ruby 2.4.0

```
bundle install
pod install
```

## Installing onto a development device

To install the app on your phone you'll first need to register your phone with
the apple developer portal [here](http://developer.apple.com).

Then download the development signing certs:
```
bundle exec fastlane get_apns_dev_certs
```
and install `apns_dev.p12` and `apns_dev.pem` into your keychain.

Install the provisioning profile with:
```
bundle exec fastlane match development
```
You should now be able to install the app on your phone via xcode 🤞.
