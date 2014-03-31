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

3. After you have created your ``pem`` file. Set the host, port and certificate file location on the APNS class. You just need to set this once:

        APNS.host = 'gateway.push.apple.com' 
        # gateway.sandbox.push.apple.com is default and only for development
        # gateway.push.apple.com is only for production
        
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
        
> All notifications passed as a parameter will be sent on a single connection, this is done to improve
> reliability with APNS servers.

#### Another way to send multiple notifications is to send notifications in a persistent connection (thread safe)

    # Define that you want persistent connection
    APNS.start_persistence

    device_token = '123abc456def'
    
    # Send single notifications
    APNS.send_notification(device_token, 'Hello iPhone!' )
    APNS.send_notification(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')
    
    # Send multiple notifications
    n1 = APNS::Notification.new(device_token, 'Hello iPhone!' )
    n2 = APNS::Notification.new(device_token, :alert => 'Hello iPhone!', :badge => 1, :sound => 'default')
    APNS.send_notifications([n1, n2])
    
    ...
    
    # Stop persistence, from this point each new push will open and close connections
    APNS.stop_persistence

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

### Configure

		GCM.host = 'https://android.googleapis.com/gcm/send'
		# https://android.googleapis.com/gcm/send is default

		GCM.format = :json
		# :json is default and only available at the moment

		GCM.key = "123abc456def"
		# this is the apiKey obtained from here https://code.google.com/apis/console/
		
### Usage

#### Sending a single notification:

		destination = ["device1", "device2", "device3"]
		# can be an string or an array of strings containing the regIds of the devices you want to send

		data = {:key => "value", :key2 => ["array", "value"]}
		# must be an hash with all values you want inside you notification

		GCM.send_notification( destination )
		# Empty notification

		GCM.send_notification( destination, data )
		# Notification with custom information

		GCM.send_notification( destination, data, :collapse_key => "placar_score_global", :time_to_live => 3600, :delay_while_idle => false )
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

		GCM.send_notifications( [n1, n2, n3] )
		# In this case, every notification has his own parameters
	
for more information on parameters check documentation: [GCM | Android Developers](http://developer.android.com/guide/google/gcm/gcm.html#request)

#### Getting your Android device token (regId)

Check this link [GCM: Getting Started](http://developer.android.com/guide/google/gcm/gs.html)

### (Optional) You can add multiple keys for GCM

You can use multiple keys to send notifications, to do it just do this changes in the code 

#### Configure

		GCM.key = { :key1 => "123abc456def", :key2 => "456def123abc" }
		# the ``:key1`` and the ``:key2`` can be any object, they can be the projectID, the date, the version, doesn't matter.
		# The only restrain is: they need to be valid keys for a hash.

#### Usage

		# For single notification
		GCM.send_notification( destination, :identity => :key1 )
		# Empty notification

		GCM.send_notification( destination, data, :identity => :key1 )
		# Notification with custom information

		GCM.send_notification( destination, data, :collapse_key => "placar_score_global", :time_to_live => 3600, :delay_while_idle => false, :identity => :key1 )
		# Notification with custom information and parameters

		# For multiple notifications
		options1 = {}
		options2 = {..., :identity => :key2}
		n1 = GCM::Notification.new(destination1, data1, options1.merge({:identity => :key2}))
		n2 = GCM::Notification.new(destination2, data2, :identity => :key1)
		n3 = GCM::Notification.new(destination3, data3, options2)

		GCM.send_notifications( [n1, n2, n3] )
		# In this case, every notification has his own parameters, options and key

## Status

#### Build Status 
[![Build Status](https://travis-ci.org/NicosKaralis/pushmeup.png?branch=master)](https://travis-ci.org/NicosKaralis/pushmeup)
[![Code Climate](https://codeclimate.com/github/NicosKaralis/pushmeup.png)](https://codeclimate.com/github/NicosKaralis/pushmeup)

#### Dependency Status [![Dependency Status](https://gemnasium.com/NicosKaralis/pushmeup.png?travis)](https://gemnasium.com/NicosKaralis/pushmeup)

## Contributing

We would be very pleased if you want to help us!

Currently we need a lot of testing so if you are good at writing tests please help us

## License

Pushmeup is released under the MIT license:

http://www.opensource.org/licenses/MIT


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/NicosKaralis/pushmeup/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

