# `xx` - the X server starting script

Minimal script to start the X server manually from the text console (a lot
simplified annotated customization-friendly alternative to the startx).

<h3 align="center">
<tt>&nbsp;boot to console&nbsp;</tt> &nbsp;&rarr;&nbsp;
<tt>&nbsp;login&nbsp;</tt> &nbsp;&rarr;&nbsp;
<tt>&nbsp;run xx&nbsp;</tt> &nbsp; &nbsp; &nbsp; </h3>

The `xx` name is convenient when it has to be typed from a misconfigured
keyboard after arbitrary boot problem.  Single `x` would be even simpler, but it
would be also prone to launch unintentionally.  The `xx` script itself does:

1. Creates the session data directory `/tmp/X0`.
2. Starts user's dbus for the browser to work correctly.
3. Starts user's pulseaudio sound server.
4. Sets the xauthority authentication cookie for X.
5. Moves the `Xorg.0.log` to `/tmp/X0`.
6. Makes temporary xinitrc to start a window manager.
7. Runs the X server.
8. Removes all session data after the X is closed.

#### 1. `/tmp/X0` - runtime data and logs

All X runtime files will be created or redirected into `/tmp/X0`.  The `X0`
stands for the "X display 0".  Main runtime files will be:

```
/tmp/X0/dbus		-> dbus socket file
/tmp/X0/dbus.log	-> dbus log
/tmp/X0/xauthority	-> authentication cookie
/tmp/X0/xinitrc		-> xinitrc
/tmp/X0/xorg.log	-> standard X log
/tmp/X0/xorg.stdout	-> console messages from X
```
  
#### 2. `dbus` - for the browser

Unfortunately, user's session dbus daemon is needed for the browser to obtain
links from apps, or for some other bigger/container apps to interact with each
other.  Otherwise it is not needed.

The environment variable `$DBUS_SESSION_BUS_ADDRESS` needs to be exported to
define the path to a socket file.  The standard location
`DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"` is not reliable
(might be missing), so we use our `/tmp/X0/dbus` instead.

Before starting the `dbus-daemon` we kill the one hanging from previous
session.  In this step, potential stalled socket file was already removed, when
we removed a whole `/tmp/X0` directory in the previous step.  We log dbus info
into `/tmp/X0/dbus.log`, instead of the default syslog.

<i> Unfortunately, the `DBUS_SESSION_BUS_ADDRESS` name was chosen as the
standard, instead of a simple `DBUS`. </i>

#### 3. `pulseaudio` - for the browser

Unfortunately, a running audio server is needed for applications to be able to
play sound or just to not hang.  Often, `pulseaudio` is required.  Pulseaudio
saves its runtime stuff to `~/.config/pulse`, to `/var/run/user/ID/pulse` plus
syslog or journal.  To move it to `/tmp/pulse` we need to set
`PULSE_RUNTIME_PATH` and `XDG_CONFIG_HOME` and let pulseaudio clients know it in
the `/etc/pulse/clients.conf`:

```
extra-arguments = --log-target=stderr
cookie-file = /tmp/pulse/cookie
```

Main pulseaudio runtime files will be:

```
/tmp/pulse/cookie	-> authentication cookie
/tmp/pulse/socket	-> sound server socket
/tmp/pulse/pulse.log	-> sound server log file
/tmp/pulse/pid		-> sound server PID
```

We chosen `/tmp/pulse` instead of `/tmp/X0/pulse`, as the pulseaudio is
potentially independent from X.  Also, this path has to be referenced as a
string in `/etc/pulse/client.conf` and `/etc/pulse/default.pa`, which further
supports the simpler path choice.

The pulseaudio `--log-target=file` uses some logic to handle things, to avoid
to work around it we rather use the `--daemonize=no --log-target=stderr` and
point STDERR to a file.

Similarly to step 4. we can grant a group access to the `pulseaudio` by
changing the `/tmp/pulse` permissions, but we also need to negotiate common
socket file location by adding this line to `/etc/pulse/clients.conf`:

```
default-server = unix:/tmp/pulse/socket
```

and this line to `/etc/pulse/default.pa`:

```
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse/socket
```

To use the `/tmp/pulse/cookie` instead of creating new one in
`~/.config/pulse/cookie` the other users have to set the `$XDG_CONFIG_HOME` in
`.bashrc` or `.zshrc`:

```
export XDG_CONFIG_HOME=/tmp
```

Any custom pulseaudio setup, which will otherwise go into `~/config/pulse`
needs to be copied in the xx script to the `/tmp/pulse` similarly to the
xinitrc file from step 6.  Alternatively, things can be set directly in
`/etc/pulse` files.

On Ubuntu or other systemd based systems the pulseaudio daemon is started on
user's login, to stop it and use only the xx pulseaudio do something like:

```
ln -sf /dev/null /etc/systemd/user/default.target.wants/pulseaudio.service
ln -sf /dev/null /etc/systemd/user/sockets.target.wants/pulseaudio.socket
```

#### 4. `xauthority` - authentication cookie

Authentication cookie file is used to secure the X access to only a single user.
User-run applications can use the X only if they can read the cookie file.  In
this script, we can use the same cookie file for the X server and for the
client (user application), because we expect the server to be run by the user
too.

Location of the cookie file is revealed to clients by the `XAUTHORITY`
environment variable, and to the X server by the `-auth` switch.  Without the
`touch $XAUTHORITY` the `xx` will work but complain.  Without the manual
`xauth` setup, X will create and use the `~/.Xauthority` file.  For the host
based access the default `600` permissions set by `xauth` need to be overridden
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

The `ssh -X/Y` from remote to this host will create its own `~/.Xauthority`
cookie on this host.  This cookie is different from `/tmp/X0/xauthority`, it is
unique for every ssh session, and you can remove it after the ssh session.

<i> Why to have more users to share a single X session?  Modern trend is to
force multiuser operating systems to accept only a single user, or
support/suggest single-user usage scenarios.  However, it gradually becomes
more advantageous for a single human to use multiple user accounts concurrently.
Modern applications tend to automatically store settings, profiles, states,
caches, dependencies for a particular user and to modify their own
functionality accordingly.  But, people often work on several completely
different projects requiring to use tools in different ways, remember different
coworkers, different passwords, bookmarks, folders, etc.  Multiple user
accounts for a single human can help!  To fully use the advantage of multiple
accounts you need to be able to open windows from two accounts at the same time
to copy-paste, compare, etc. ...and it is easy! </i>

#### 5. `Xorg.0.log` - X server log file

The default location of user-run X server is in the user's home directory
`~/.local/share/xorg/Xorg.0.log`.  This path is hardcoded in the X server
program and the `-logfile` option is available only to the root user.  Thus to
move the user-run X log from `/home` to `/tmp/X0` we must use a symlink, which
is what we do in this step.

The log file of the root-run X, can be stored in the `/tmp/X0` using the
`-logfile`, but also by the symlink: `ln -s /var/log/Xorg.0.log /tmp/X0/xorg.log`.

<i> TODO: Hack the X server to allow to log directly to the `/tmp/X0` as user.</i>

#### 6. `xinitrc` - which window manager to start

In this step we just copy the `~/.xinitrc` to our runtime directory `/tmp/X0`.
However, instead of this copying, the xinitrc content can be generated on the
fly in the `xx` script to contain the whole X setup in a single file.  Like
this:

```
echo "setxkbmap dvorak"    > $XINITRC
echo "fvwm -f ~/.fvwmcfg" >> $XINITRC
```

Another mechanism to set up the X are the `/usr/share/X11/xorg.conf.d` files.
However, some things have to be set by the xinitrc even if they are already set
in xorg.conf.  For instance, if keyboard is configured only in the xorg.conf,
then the window manager which is run from the xinitrc might not have the
keyboard correctly configured in the time it is initialized.

#### 7. `Xorg` - start the X server

Here we run the X server `Xorg` through the `xinit` program for the display `:0`
reusing the current virtual console.  We also log the X servers stdout messages
to the `xorg.stdout` alongside its logfile `xorg.log`.

#### 8. cleanup at exit

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
modified `xx` for a group-based or for host-based access.  Default is the
single-user access mode.

### Group-based access

The X and pulseaudio group-based access used in steps 3 and 4 has the
primary-secondary roles: initiating user is the primary one with write
privileges, other users in the `xorg` group are secondary with only the read
access.  Instead of the `xorg`, a good name for the group would be the name of
primary user.

### `/tmp` directory

We try to put all X and pulseaudio runtime data to the `/tmp` and remove it at
end of session.  This way we achieve:

 * no waste data are stored,
 * data are together, easier to inspect!

### `rc` files

The `dbusrc` and `pulserc` files for the startup of daemons daemons allow the
"fire-and-forget" approach.  If something in these less-important services
fails, it will not stop the X from start, if something takes too long, it will
not slowdown the main routine.

### Limitations

This `xx` is written only for the display `:0`.

<br><div align=right><i>R.Jaksa 2023,2024</i></div>
