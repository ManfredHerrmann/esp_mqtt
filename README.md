**esp_mqtt**
========
This is MQTT client library for ESP8266, port from: [MQTT client library for Contiki](htps://github.com/esarr/contiki-mqtt) 

**Features:**
It operates asynchronously, creating a new process to handle communication with the message broker. It supports subscribing, publishing, authentication, will messages, keep alive pings and all 3 QoS levels. In short, it should be a fully functional client, though some areas haven't been well tested yet.

**Be careful:** This library is not fully supported  for too long messages

The Makerfile for windows support:

 - Create 2 file user1.bin and user2.bin for OTA (build_ota)
 - Flash user1.bin and booloader.bin

More information about compiler in Windows please see here: http://www.esp8266.com/viewtopic.php?f=9&t=820

**Status**
Under development. 

MQTT Broker for test: https://github.com/mcollina/mosca
MQQT Client for test: MQTTlens
**Author:** Tuan PM
