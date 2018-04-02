# Bluetooth Presence Alerter

A bash based script to ping a list of devices and alert of the presence changes

## Getting Started

### Prerequisites

The following packages should be installed already, but if they aren't, then run the following:

```
sudo apt-get install vim
sudo apt-get install l2ping
```

### Global variables 

You will need to set the following global variable
```
BLUETOOTH_PRESENCE_ALERTER_ROOT
```
To set this, run the following command:
```
sudo vim /etc/environment
```
and add the following
```
export BLUETOOTH_PRESENCE_ALERTER_ROOT={THE FULL DIRECTORY WHERE YOUR "ping_bluetooth_address.sh" IS LOCATED}
```

### Configuration

The following configuration files are required:

```
device_list.lst
telegram_bot_properties.props
```

The contents for device_list.lst should contain the following. Multiple configurations are supported:

```
DeviceOwner=mac_address
DeviceOwner_2=mac_address_2
```

The contents for telegram_bot_properties.props should contain the following. 

If multiple entries are made, the alert will be sent to each config.

```
BOT_API_KEY|CHAT_ID
BOT_API_KEY_2|CHAT_ID_2
```

You may also want to set the bluetooth timeout interval on linux. This will stop the script from running for excessive amounts of time.
Do this as follows:

```
sudo hciconfig hci0 pageto 3200
```

### Bot Details

Your api key for your bot can be retrieved from bot_father on telegram.

To find your chat_id, do the following (Note: The following should be done ***without*** a responsive bot framework hosting your bot).
1. Create a group with your bot, or a private chat if you are not intending on using the bot in a group.
2. Send a inline message to the bot (A message starting with "/")
3. Run the following command:
```
curl -i -X GET https://api.telegram.org/bot{BOT_API_KEY}/getUpdates
```
You will get a response similar to the following. The chat_id is included in the "chat" section:
```
{
  "ok": true,
  "result": {
    "message_id": xxx,
    "from": {
      "id": xxx,
      "is_bot": true,
      "first_name": "xxx",
      "username": "xxx"
    },
    "chat": {
      "id": 12345, //This line contains the CHAT_ID
      "title": "xxx",
      "type": "xx",
      "all_members_are_administrators": true
    },
    "date": xx,
    "text": "xx"
  }
}
```
4. Use this value in the config file to send messages to this particular group/private chat.

### Scheduling
To schdule this to run every 30 seconds, you will need to make two entries in the crontab file.

Run the following:
```
export EDITOR=vim
```

Then run the following:
```
crontav -e
```

And add the following: (Edit the path to your script where necessary)

```
* * * * * /home/pi/apps/bluetooth_presence_alerter/ping_bluetooth_address.sh >> /tmp/ping_bluetooth_alerter.log
* * * * * ( sleep 30; /home/pi/apps/bluetooth_presence_alerter/ping_bluetooth_address.sh >> /tmp/ping_bluetooth_alerter.log )
```

