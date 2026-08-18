# Ignition OPC UA – Complete Error Log (Full History)

This document chronologically records every error encountered from the moment you started setting up the Ignition OPC UA connection, including the early UAExpert issues, CODESYS side configuration, and the ongoing HMI and tag binding challenges.

---

## Phase 0: UAExpert & Initial Discovery

### Error 1 – UAExpert Localhost Timeout

```
Discovery FindServers on opc.tcp://localhost:4840 failed (BadTimeout)
```

**Context:** UAExpert attempted to discover a local OPC UA server.

**Cause:** No server was running on localhost (expected).

**Resolution:** Ignored – this was normal behaviour.

---

### Error 2 – Endpoint Mismatch in UAExpert

```
DiscoveryUrl[0] of FindServers (opc.tcp://192.168.137.100:4840) differs from the one received in GetEndpoints (opc.tcp://rpi-abdmoiz18:4840)
```

**Context:** UAExpert discovered the CODESYS server but found a mismatch.

**Cause:** The server advertises itself with hostname, but UAExpert used IP.

**Resolution:** Added `192.168.137.100 rpi-abdmoiz18` to Windows hosts file.

---

### Error 3 – UAExpert UserIdentityTokens Empty

```
Endpoint with Url opc.tcp://rpi-abdmoiz18:4840 returned an empty list of UserIdentityTokens - fallback to Anonymous.
Check the server configuration for a valid configuration of available UserIdentityTokens.
```

**Context:** UAExpert attempted to connect to CODESYS server.

**Cause:** CODESYS OPC UA server was not exposing any authentication policies.

**Resolution:** This was fixed on the CODESYS side (see Phase 1).

---

## Phase 1: CODESYS Side Configuration

### Error 4 – No Anonymous Token Policy in CODESYS

```
java.lang.Exception: no anonymous token policy found
```

**Context:** Ignition or UAExpert tried to connect to CODESYS OPC UA server.

**Cause:** Anonymous login was not enabled in the CODESYS OPC UA server.

**Fix:** In CODESYS, went to Device → Communication Settings → OPC UA Server → ensured Anonymous was enabled. Also added `PoliciesForAnonymousLogin=1` and `UserTokenPolicies=0` to `CODESYSControl_User.cfg`.

---

### Error 5 – No UserTokenPolicy with UserTokenType.UserName

```
java.lang.Exception: no UserTokenPolicy with UserTokenType.UserName found
```

**Context:** Ignition tried to authenticate with Username/Password.

**Cause:** The server did not have a UserName policy configured.

**Resolution:** Added a user in the CODESYS OPC UA Server object (Users tab) and ensured UserName policy was enabled.

---

### Error 6 – Server Not Publishing Tags

**Context:** Tags were imported but not updating.

**Cause:** The CODESYS OPC UA server was not publishing subscription data.

**Resolution:** Checked OPC UA Server settings in CODESYS – ensured "Enable Publishing" was checked. Also changed tag Data Mode to Polled temporarily to force updates.

---

## Phase 2: Ignition Connection Attempts

### Error 7 – Ignition OPC UA Connection Faulted (Initial)

```
Connection status: Faulted
```

**Context:** Ignition OPC UA connection was created but immediately faulted.

**Cause:** Endpoint mismatch, authentication issues, or missing keystore.

**Resolution:** This initiated the entire debugging process – eventually resolved via certificate trust and keystore fixes.

---

### Error 8 – No Anonymous Token Policy in Ignition

```
java.lang.Exception: no anonymous token policy found
```

**Context:** Ignition attempted to connect to CODESYS.

**Cause:** The server was not exposing anonymous login.

**Resolution:** Fixed on CODESYS side (see Error 4).

---

### Error 9 – Hostname Resolution Failure in Ignition

```
Discovery FindServers on opc.tcp://localhost:4840 failed (BadTimeout)
```

**Context:** Ignition tried to discover a server on localhost.

**Cause:** No server on localhost (expected).

**Resolution:** Ignored.

---

### Error 10 – Certificate Hostname Check Failure

```
DefaultClientCertificateValidator: check suppressed: certificate failed hostname check: C=US,ST=CA,L=Folsom,O=Inductive Automation,CN=Ignition OPC UA Server
```

**Context:** Ignition validated the server certificate.

**Cause:** The certificate's Common Name did not match the endpoint URL.

**Resolution:** Disabled certificate validation in Ignition OPC UA connection settings.

---

## Phase 3: Keystore & Certificate Errors

### Error 11 – Unable to Retrieve KeyPair (Incorrect Password)

```
java.lang.IllegalArgumentException: Unable to retrieve KeyPair for alias 'client'. Incorrect password?
Caused by: java.security.UnrecoverableKeyException: Get Key failed: Given final block not properly padded.
Caused by: javax.crypto.BadPaddingException: Given final block not properly padded.
```

**Context:** Ignition tried to access the client keystore.

**Cause:** The keystore password did not match the encryption password.

**Resolution:** Generated a new keystore with password `password` and set the connection password to `password`.

---

### Error 12 – Certificate Chain Not Found

```
Certificate chain not found for alias 'client'. Verify the keystore contains this alias.
```

**Context:** Ignition could not find the `client` alias in the keystore.

**Cause:** The keystore was empty, corrupted, or missing the correct alias.

**Resolution:** Recreated the keystore with alias `client`.

---

### Error 13 – Keytool Missing -keyalg Option

```
keytool error: java.lang.Exception: The -keyalg option must be specified.
```

**Context:** Generating a keystore with `keytool`.

**Cause:** The `-keyalg` parameter was omitted.

**Resolution:** Added `-keyalg RSA` to the command.

---

### Error 14 – Keystore Password Incorrect (Keytool)

```
keytool error: java.io.IOException: keystore password was incorrect
```

**Context:** Running `keytool` to generate a new keystore.

**Cause:** The existing keystore had a different password.

**Resolution:** Deleted the existing keystore before regenerating.

---

## Phase 4: Subscription & Communication Errors

### Error 15 – Receive Failed for Unknown Request

```
OpcTcpClientTransport: Receive failed for unknown request, requestId=5754
OpcTcpClientTransport: Receive failed for unknown request, requestId=5753
```

**Context:** Ignition sent a request to the OPC UA server.

**Cause:** The server did not respond to a request, or the request ID was not recognised.

**Resolution:** Resolved after connection stabilised.

---

### Error 16 – Watchdog Timer Elapsed

```
OpcUaSubscriptionManager: onWatchdogTimerElapsed()
```

**Context:** The subscription watchdog timer expired.

**Cause:** The OPC UA server stopped sending data to Ignition.

**Resolution:** Resolved after connection stabilised and tag subscriptions were refreshed.

---

### Error 17 – Subscription Deletion Failure

```
OpcUaSubscriptionManager: onWatchdogTimerElapsed(): subscription deletion failure
```

**Context:** Ignition attempted to delete a failed subscription.

**Cause:** The server did not acknowledge the deletion request.

**Resolution:** Resolved after connection stabilised.

---

### Error 18 – Connection Aborted by Host

```
UascClientMessageHandler: [remote=localhost/127.0.0.1:62541] Exception caught: An established connection was aborted by the software in your host machine
```

**Context:** The OPC UA connection was closed unexpectedly.

**Cause:** The server was restarted, or the connection timed out.

**Resolution:** Resolved after restarting both CODESYS and the Ignition Gateway.

---

## Phase 5: Tag Binding & HMI Errors

### Error 19 – Unknown Last Tag Value / Uncertain_InitialValue

```
Last value: [null, Uncertain_InitialValue, ...]
Last value: [false, Uncertain_LastKnownValue, ...]
```

**Context:** Ignition tags were not receiving updates.

**Cause:** Tags were added before the OPC UA connection was fully established, or the subscription was not working.

**Resolution:** Deleted and recreated tags after connection was established. Set Data Mode to Polled temporarily to force updates.

---

### Error 20 – Tags Added Before CODESYS Connection

**Context:** Tags were created in Ignition before the OPC UA connection was fully functional.

**Cause:** The connection was not ready when tags were added.

**Resolution:** Deleted and recreated tags after connection was established.

---

### Error 21 – Deleting Tags Caused Issues on CODESYS End

**Context:** Deleting tags in Ignition caused errors on the CODESYS side.

**Cause:** The OPC UA server may have been in an inconsistent state.

**Resolution:** Rebuilt the CODESYS project and restarted the runtime.

---

### Error 22 – Polling vs Subscribe Confusion

**Context:** Tags were not updating regularly.

**Cause:** Data Mode was set to Subscribe, but the server was not publishing. Setting to Polled forced updates.

**Resolution:** Changed Data Mode to Polled with a Poll Rate of 1000 ms temporarily. Will switch back to Subscribe once stable.

---

### Error 23 – OPC UA Stale Session (CODESYS Off)

**Context:** OPC UA connection did not fault immediately when CODESYS was turned off.

**Cause:** OPC UA sessions have a keep‑alive timeout.

**Resolution:** Ignored – this is expected behaviour.

---

### Error 24 – Redundancy Limit Reached

```
Route Concurrency Limit Reached
```

**Context:** Creating or modifying OPC UA connections.

**Cause:** CODESYS session limit was reached.

**Resolution:** Restarted the CODESYS runtime and closed UAExpert to free up sessions.

---

### Error 25 – HMI Writes Showing "Pending" and Reverting

**Context:** Toggle Switch in HMI writes to CODESYS tags.

**Cause:** Tag may be read-only, or the OPC UA server is not accepting writes.

**Status:** 🔴 Under investigation – manual writes from Tag Browser pending.

---

## Summary Table

| # | Error | Phase | Status |
|---|-------|-------|--------|
| 1 | UAExpert localhost timeout | Discovery | ⚠️ Expected |
| 2 | UAExpert endpoint mismatch | Discovery | ✅ Resolved |
| 3 | UAExpert UserIdentityTokens empty | Authentication | ✅ Resolved |
| 4 | CODESYS no anonymous token | CODESYS | ✅ Resolved |
| 5 | CODESYS no UserName policy | CODESYS | ✅ Resolved |
| 6 | CODESYS not publishing tags | CODESYS | ✅ Resolved |
| 7 | Ignition connection faulted | Ignition | ✅ Resolved |
| 8 | Ignition no anonymous token | Ignition | ✅ Resolved |
| 9 | Ignition localhost timeout | Ignition | ⚠️ Expected |
| 10 | Certificate hostname check | Security | ✅ Resolved |
| 11 | Unable to retrieve KeyPair | Keystore | ✅ Resolved |
| 12 | Certificate chain not found | Keystore | ✅ Resolved |
| 13 | -keyalg missing | Keystore | ✅ Resolved |
| 14 | Keystore password incorrect | Keystore | ✅ Resolved |
| 15 | Receive failed for unknown request | Communication | ✅ Resolved |
| 16 | Watchdog timer elapsed | Subscription | ✅ Resolved |
| 17 | Subscription deletion failure | Subscription | ✅ Resolved |
| 18 | Connection aborted | Communication | ✅ Resolved |
| 19 | Uncertain tag values | Tag Binding | ✅ Resolved |
| 20 | Tags added before connection | Tag Binding | ✅ Resolved |
| 21 | Deleting tags caused CODESYS issues | Tag Binding | ✅ Resolved |
| 22 | Polling vs Subscribe confusion | Tag Binding | ✅ Resolved |
| 23 | OPC UA stale session | Session | ✅ Resolved |
| 24 | Redundancy limit reached | Session | ✅ Resolved |
| 25 | HMI writes pending | Write Direction | 🔴 Under investigation |

---

## Current Status

- **OPC UA Connection:** ✅ Connected
- **Read Direction (CODESYS → Ignition):** ✅ Working
- **Write Direction (Ignition → CODESYS):** 🔴 Not working (pending)
- **Tag Values:** ✅ Visible, updating (when polled)
- **HMI Writes:** 🔴 Pending, reverting to original values

---

*End of complete error log – connection established, writes pending.*
