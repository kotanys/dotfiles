---
name: notify-send
description: Sends desktop notifications via notify-send
---

To send a notification to the user, call
```sh
notify-send --app-name=Opencode SUMMARY DETAILS
```

DETAILS may be omitted if they provide no more information than SUMMARY.

SUMMARY and DETAILS must not be written in all caps, that's scary as shit!

The user might have provided you with information on when to send
the event. If not, send it when you're finished with what you're doing.
