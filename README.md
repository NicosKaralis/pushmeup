## Pushmeup

### a gem for various push notification services.

## Goals

Pushmeup is an attempt to create an push notifications center that could send push to devices like:

- Android
- iOS
- Mac OS X
- Windows Phone
- And many others

Currently we have only support for ``iOS`` and ``Android`` but we are planning code for more plataforms.

## Installation

    gem install pushmeup
    
or add to your ``Gemfile``

    gem 'pushmeup'
    
and install it with

    bundle install

## APNS (Apple iOS)

### Configure

1. In Keychain access export your certificate and your private key as a ``p12``.

  ![Keychain Access](https://raw.github.com/NicosKaralis/pushmeup/master/Keychain Access.jpg)

2. Run the following command to convert the ``p12`` to a ``pem`` file

        openssl pkcs12 -in cert.p12 -out cert.pem -nodes -clcerts

3. After you have created your ``pem`` file. Set what host, port, certificate file location on the APNS class. You just need to set this once:

        APNS.host = 'gateway.push.apple.com' 
        # gateway.sandbox.push.apple.com is default
        
        APNS.port = 2195 
        # this is also the default. Shouldn't ever have to set this, but just in case Apple goes crazy, you can.

        APNS.pem  = '/path/to/pem/file'
        # this is the file you just created

        APNS.pass = ''
        # Just in case your pem need a password

### Usage

#### Sending a single notification:

        device_token = '123abc456def'
        APNS.send_notification(device_token, 'Hello iPhone!' )
        APNS.send_notification(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')

#### Sending multiple notifications

        device_token = '123abc456def'
        n1 = APNS::Notification.new(device_token, 'Hello iPhone!' )
        n2 = APNS::Notification.new(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')
        APNS.send_notifications([n1, n2])

#### Sending more information along

        APNS.send_notification(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default', 
                                            :other => {:sent => 'with apns gem', :custom_param => "value"})
                                            
this will result in a payload like this:

        {"aps":{"alert":"Hello iPhone!","badge":1,"sound":"default"},"sent":"with apns gem", "custom_param":"value"}

### Getting your iOS device token

    - (void)applicationDidFinishLaunching:(UIApplication *)application {
        // Register with apple that this app will use push notification
        ...
        
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
        
        ...
        
    }
    
    - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
        // Show the device token obtained from apple to the log
        NSLog("deviceToken: %", deviceToken);
    }

## GCM (Google Cloud Messaging)


## Build Status [![Build Status](https://secure.travis-ci.org/NicosKaralis/pushmeup.png?branch=master)](http://travis-ci.org/NicosKaralis/pushmeup) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/NicosKaralis/pushmeup)

## Dependency Status [![Dependency Status](https://gemnasium.com/NicosKaralis/pushmeup.png?travis)](https://gemnasium.com/NicosKaralis/pushmeup)

## License

Pushmeup is released under the MIT license:

http://www.opensource.org/licenses/MIT
