# `xx` - the X server starting script

Minimal script to start the X server manually from the text console (a lot
simplified customization-friendly alternative to the startx).

<p align="center">
<tt>boot to console</tt> &nbsp;&rarr;&nbsp; <tt>login</tt> &nbsp;&rarr;&nbsp; <tt>run xx</tt>
&nbsp; &nbsp; &nbsp; </p>

<div align=right>

</div>

The `xx` name is convenient when it has to be typed from a misconfigured
keyboard after arbitarry boot problem.  Single `x` would be even simplier, but it
would be also prone to launch unintentionaly.  The `xx` script itself does:

1. Creates the session data directory `/tmp/X0`.
2. Starts user's dbus for the browser to work correctly.
3. Sets the xauthority authentication cookie for X.
4. Moves the `Xorg.0.log` to `/tmp/X0`.
5. Makes temporary xinitrc to start a window manager.
6. Runs the X server.
7. Removes all session data after the X is closed.

#### 1. `/tmp/X0` - runtime data and logs

All X runtime files will be created or redirected into `/tmp/X0` (or to the
`/tmp/X0-user`).  For every new session the old stalled directory will be
removed, and new one created.

```
/tmp/X0/dbus		-> dbus socket file
/tmp/X0/dbus.log	-> dbus log
/tmp/X0/xauthority	-> authentication cookie
/tmp/X0/xinitrc		-> xinitrc
/tmp/X0/xorg.log	-> standard X log
/tmp/X0/xorg-stdout.log	-> console messages from X
```

The `X0` means "X display 0".
  
#### 2. `dbus` - for the browser

Unfortunately, user's session dbus daemon is needed for the browser to obtain
links from apps, or for some other bigger/container apps to interact with each
other.  Otherwise it is not needed.

The environbent variable `$DBUS_SESSION_BUS_ADDRESS` needs to be exported to
define the path to a socket file.  The standard location
`DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"` is not reliable
(might be missing), so we use our `/tmp/X0/dbus` instead.

Before starting the `dbus-daemon` we kill the one hanging from previous
session.  In this step, potential stalled socket file was already removed, when
we removed a whole `/tmp/X0` directory in the previous step.  We log dbus info
into `/tmp/X0/dbus.log`, instead of the default syslog.

<i> Unfortunately, the `DBUS_SESSION_BUS_ADDRESS` name was chosen as the
standard, instead of a simple `DBUS`. </i>

#### 3. `xauthority` - authentication cookie

Authentication cookie file is used to secure the X acces to only a single user.
User-run applications can use the X only if they can read the cookie file.  In
this script, we can use the same cookie file for the X server and for the
client (user application), because we expect the server to be run by the user
too.

Location of the cookie file is revealed to clients by the `XAUTHORITY`
environment variable, and to the X server by the `-auth` switch.  Without the
`touch $XAUTHORITY` the `xx` will work but complain.  Without the manual
`xauth` setup, X will create and use the `~/.Xauthority` file.  For the host
based access the default `600` permisions set by `xauth` need to be owerriden
to allow other users to read the cookie too by adding: `chmod 644 $XAUTHORITY`
to the `xx` script.

Similarly, the group based access can be granted by creating a group `xorg`
(for instance) and assigning users to it by `echo "xorg:x:200:user1,user2" >>
/etc/group` (for instance).  Then, re-login is needed to activate the `xorg`
group.  Finally, we can grant the access to the cookie for a whole group in the
`xx` script by adding:

```
chgrp xorg $XAUTHORITY
chmod 640 $XAUTHORITY
```

<i> Why to have more users to share a single X session?  In opposition to the
trend of forcing multiuser operating system to accept only a single user, it
actually become advantageous for a single human to use multiple user accounts
in parallel.  Modern applications tend to automatically store settings,
profiles, states, caches, dependencies for a particular human and they modify
their functionality accordingly.  However, we humans are not so simple!  Ones
we are at work, other times not!  We might work on three completely different
projects requiring to use tools in different way.  We might want apps to
remember different coworkers for diffelent projets, etc...  Then multiple user
accounts for a single human can help!  And also being able to open windows from
two accounts at the same time to be able to copy-paste is useful... </i>

#### 4. `Xorg.0.log` - X server log file

The default location of user-run X server is in the user's home directory
`~/.local/share/xorg/Xorg.0.log`.  This path is hardcoded in the X server
program and the `-logfile` option is available only to the root user.  Thus to
move the user-run X log from `/home` to `/tmp/X0` we must use a symlink, which
is what we do in this step.

The log file of the root-run X, can be stored in the `/tmp/X0` using the
`-logfile`, but also by the symlink: `ln -s /var/log/Xorg.0.log /tmp/X0/xorg.log`.

<i> TODO: Hack the X server to allow to log directly to the `/tmp/X0` as user.</i>

#### 5. `xinitrc` - which window manager to start

In this step we just copy the `~/.xinitrc` to our runtime directory `/tmp/X0`.
However, instead of this copying, the xinitrc content can be generated on the
fly in the `xx` script to cantain whole X setup in a single file.  Like this:

```
echo "setxkbmap dvorak"    > $XINITRC
echo "fvwm -f ~/.fvwmcfg" >> $XINITRC
```

Another mechanism to setup X are the `/usr/share/X11/xorg.conf.d` files.
However, some things have to be set by the xinitrc even if they are already set
in xorg.conf.  For instance, if the keyboard is only set in xorg.conf, the
window manager which is run from the xinitrc might not get the keyboard
correctly configured in the time it is initialized.

#### 6. `Xorg` - start the X server

Here we run the X server `Xorg` throgh the `xinit` program for the display `:0`
reusing the current virtual console.  We also log the X servers stdout messages
to the `xorg-stdout.log` alongside its logfile `xorg.log`.

#### 7. cleanup at exit

In this step we clean up everything what we created for the X to run:

 * kill the dbus daemon,
 * remove all runtime and log files, all of which we placed into `/tmp/X0`.

The X server also creates `/tmp/.X11-unix` and `/tmp/.ICE-unix` which we cannot
remove due to their root privileges.  Also, if the X is run as root the log is
stored in `/var/log/Xorg.0.log` and can be removed only by root.

---

### Install

 1. Edit the `xinitrc` part of `xx`, see section 5.,
 2. `make install` to copy the `xx` to `~/bin`.

Alternatively use `make install4group` or `make install4host` to install the
modified `xx` for a group-based or for host-based authentication.  By default
the single-user authentication mode is provided.

### Limitations

The `xx` is written only for the display `:0`.

If you need the `~/.Xauthority` file for the `ssh` from remote to allow to run
x commands, use: `ln -s /tmp/X0/xauthority ~/.Xauthority`.

<br><div align=right><i>R.Jaksa 2023,2024</i></div>
