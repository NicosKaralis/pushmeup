# Pushmeup

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

    $ gem install pushmeup
    
or add to your ``Gemfile``

    gem 'pushmeup'
    
and install it with

    $ bundle install

## APNS (Apple iOS)

### Configure

1. In Keychain access export your certificate and your private key as a ``p12``.

  ![Keychain Access](https://raw.github.com/NicosKaralis/pushmeup/master/Keychain Access.jpg)

2. Run the following command to convert the ``p12`` to a ``pem`` file

        $ openssl pkcs12 -in cert.p12 -out cert.pem -nodes -clcerts

3. After you have created your ``pem`` file. We create an APNS application object with our application config

		APNSApp = APNS::Application.new(host,pem,port,pass, persistent)

        APNSApp.host = 'gateway.push.apple.com' 
        # gateway.sandbox.push.apple.com is default
        
        APNSApp.port = 2195 
        # this is also the default. Shouldn't ever have to set this, but just in case Apple goes crazy, you can.

        APNSApp.pem  = '/path/to/pem/file'
        # this is the file you just created

        APNSApp.pass = ''
        # Just in case your pem need a password

### Usage

#### Sending a single notification:

        device_token = '123abc456def'
        APNSApp.send_notification(device_token, 'Hello iPhone!' )
        APNSApp.send_notification(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')

#### Sending multiple notifications

        device_token = '123abc456def'
        n1 = APNS::Notification.new(device_token, 'Hello iPhone!' )
        n2 = APNS::Notification.new(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')
        APNSApp.send_notifications([n1, n2])

#### Sending more information along

        APNSApp.send_notification(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default', 
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

### Configure
Like APNS, we've to create a GCM application object with our config.

		GCMApp = GCM::Application.new(host,format,key)

		GCMApp.host = 'https://android.googleapis.com/gcm/send'
		# https://android.googleapis.com/gcm/send is default

		GCMApp.format = :json
		# :json is default and only available at the moment

		GCMApp.key = "123abc456def"
		# this is the apiKey obtained from here https://code.google.com/apis/console/
		
### Usage

#### Sending a single notification:

		destination = ["device1", "device2", "device3"]
		# can be an string or an array of strings containing the regIds of the devices you want to send

		data = {:key => "value", :key2 => ["array", "value"]}
		# must be an hash with all values you want inside you notification

		GCMApp.send_notification( destination )
		# Empty notification

		GCMApp.send_notification( destination, data )
		# Notification with custom information

		GCMApp.send_notification( destination, data, :collapse_key => "placar_score_global", :time_to_live => 3600, :delay_while_idle => false )
		# Notification with custom information and parameters

for more information on parameters check documentation: [GCM | Android Developers](http://developer.android.com/guide/google/gcm/gcm.html#request)

#### Sending multiple notifications:

		destination1 = "device1"
		destination2 = ["device2"]
		destination3 = ["device1", "device2", "device3"]
		# can be an string or an array of strings containing the regIds of the devices you want to send

		data1 = {:key => "value", :key2 => ["array", "value"]}
		# must be an hash with all values you want inside you notification
		
		options1 = {:collapse_key => "placar_score_global", :time_to_live => 3600, :delay_while_idle => false}
		# options for the notification
		
		n1 = GCM::Notification.new(destination1, data1, options1)
		n2 = GCM::Notification.new(destination2, data2)
		n3 = GCM::Notification.new(destination3, data3, options2)

		GCMApp.send_notifications( [n1, n2, n3] )
		# In this case, every notification has his own parameters
	
for more information on parameters check documentation: [GCM | Android Developers](http://developer.android.com/guide/google/gcm/gcm.html#request)

#### Getting your Android device token (regId)

Check this link [GCM: Getting Started](http://developer.android.com/guide/google/gcm/gs.html)

### (Optional) You can add multiple keys for GCM

You can use multiple keys to send notifications, to do it just do this changes in the code 

#### Configure

		GCMApp.key = { :key1 => "123abc456def", :key2 => "456def123abc" }
		# the ``:key1`` and the ``:key2`` can be any object, they can be the projectID, the date, the version, doesn't matter.
		# The only restrain is: they need to be valid keys for a hash.

#### Usage

		# For single notification
		GCMApp.send_notification( destination, :identity => :key1 )
		# Empty notification

		GCMApp.send_notification( destination, data, :identity => :key1 )
		# Notification with custom information

		GCMApp.send_notification( destination, data, :collapse_key => "placar_score_global", :time_to_live => 3600, :delay_while_idle => false, :identity => :key1 )
		# Notification with custom information and parameters

		# For multiple notifications
		options1 = {}
		options2 = {..., :identity => :key2}
		n1 = GCM::Notification.new(destination1, data1, options1.merge({:identity => :key2}))
		n2 = GCM::Notification.new(destination2, data2, :identity => :key1)
		n3 = GCM::Notification.new(destination3, data3, options2)

		GCMApp.send_notifications( [n1, n2, n3] )
		# In this case, every notification has his own parameters, options and key

## Status

#### Build Status [![Build Status](https://secure.travis-ci.org/NicosKaralis/pushmeup.png?branch=master)](http://travis-ci.org/NicosKaralis/pushmeup) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/NicosKaralis/pushmeup)

#### Dependency Status [![Dependency Status](https://gemnasium.com/NicosKaralis/pushmeup.png?travis)](https://gemnasium.com/NicosKaralis/pushmeup)

## Contributing

We would be very pleased if you want to help us!

Currently we need a lot of testing so if you are good at writing tests please help us

## License

Pushmeup is released under the MIT license:

http://www.opensource.org/licenses/MIT
