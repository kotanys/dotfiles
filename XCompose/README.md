## My .XCompose file

#### Linux
```sh
cp repo/XCompose ~/.XCompose
```
or set `$XCOMPOSEFILE` to the whatever file path in `.profile`.

- In GNOME enable Compose key in keyboard settings.
- To enable via XKB (e.g. in Niri), add `compose:ralt` to the config. See `xkeyboard-config(7)`.

#### Windows
Install the [WinCompose](https://github.com/samhocevar/wincompose/releases/latest) project.

```bat
copy repo\XCompose %USERPROFILE%\.XCompose
copy repo\settings.ini %APPDATA%\WinCompose\settings.ini
```
The `.XCompose` may have .txt extension.
