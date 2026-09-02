# Troubleshooting Log for SCADA

## 1. 18 Aug 2026

So far for Ignition

OPC UA Connection issues (downloading UAExpert, issues with UAExpert, fixing it, finding the issue of Authentication and Password for anonymous login ON THE CODESYS SIDE, not RPi or Ignition)

Codesys (going to device,see images above, making those fixes, OPC UA works now) 

Today - Ignition HMI

Using Coordinate Container for background, Flex Container for a few layouts

Using Symbol Factory (too complex on-off animations, abandoned)

Using Buttons (too complex, needs scripts which adds a point of failure, abandoned)

Used a label for output, toggle for inputs, LED for numeric value so far

Tag Binding issues because it did not update for a while

Did not update for a while because I added Tags BEFORE connecting Codesys and Ignition (???)

Or because I did not update the value in codesys in any way? Or I should poll instead of subscribe?

Deleting Tags in Ignition caused issues on the Codesys end? Fixed by rebuild

OPC UA dosen't get faulted when there is no Codesys or RPi, stale session

Making changes is hard because redundancy limit reached or something

Turn laptop off and on, remake OPC UA, okay, now it's a certificate issue, must delete a few files tomorrow

# 2. 19 Aug 2026

Okay, faulted OPC UA server AND data is not publishing from CODESYS to Ignition the Tag Binding, one publish and zero updates, it's a certificate issue

Time to use PowerShell

Deleted the Client Keystore certificate because it was corrupted and refused to use password, Ignition Gateway off and on, turns out it didn't get restored, not fun, loopback OPC UA also died

Try to create a new cert by hand, keyalg did not work

Okay, fix keyalg, password is still an issue, it's still corrupted OR it refuses to use the connection

Okay, delete entire keystore, turn Ignition off and on, it works now, loopback OPC UA is back, AHU OPC UA still faulted

The issue was Anonymous authentication being okay but password shouldn't have been "None", because it's password is for the certificate, NOT the connection between Codesys, RPi, Ignition which all have that "Anonymous, None vibe". None was supposed to be "No encryption" in CODESYS and RPi, "Anonymous" means no login with authentication yet it still needs a certificate, "None" is not about authentication credentials it's about the certificate, In Ignition it is for Keystore Password (certificate) which needs an embedding

Allllright, embed it with the wrong password, off and on, did not work

Next, embed it with the correct password, it worked for good

Current situation - Tag Binding works and updates

Kinda responds to CODESYS activations but wrongly, it can activate on the Ignition side but gets forced back to the CODESYS value or something?

Anyways, a connection is there, it's just getting things wrong

# 3. 20 Aug 2026

FINAL FIX - Modbus register mapping from 3 months ago overwrites bidirectional tag read/write, hence I had to remove Modbus register mapping to enable OPC UA bidirectional tag read/write

Hey, that fixes one issue I had in CODESYS this whole time. I had to force every value to run it, actually, as it turns out, if I remove Modbus register mapping I do NOT have to force values anymore. Seriously dumb mistake.

Final fix was so much simpler than a thought. A feature from 3 months ago?

# 4. Commissioning fault fixes

Okay, ResetCmd was not bidirectional, I figured that out during a commissioning trial run and fixed it. 
