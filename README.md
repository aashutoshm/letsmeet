# Letsmeet (Customized Greenlight 2)

```shell
git clone https://github.com/odelanit/letsmeet.git
cd letsmeet
bundle install
```

##### redis install

```shell
sudo add-apt-repository ppa:chris-lea/redis-server
sudo apt-get update
sudo apt-get install redis-server
```

##### letsmeet.service

```editorconfig
[Unit]
Description=letsmeet
# start us only once the network and logging subsystems are available,
# consider adding redis-server.service if Redis is local and systemd-managed.
After=syslog.target network.target

# See these pages for lots of options:
# http://0pointer.de/public/systemd-man/systemd.service.html
# http://0pointer.de/public/systemd-man/systemd.exec.html
[Service]
Type=simple
WorkingDirectory=/home/ubuntu/letsmeet
# If you use rbenv or rvm:
ExecStart=/bin/bash -lc 'bundle exec rails server -b 127.0.0.1 -p 5000 -e development'
# If you use the system's ruby:
# ExecStart=bundle exec sidekiq -e production
User=ubuntu
Group=ubuntu
UMask=0002

# if we crash, restart
RestartSec=1
Restart=on-failure

# output goes to /var/log/syslog
StandardOutput=syslog
StandardError=syslog

# This will default to "bundler" if we don't specify it
SyslogIdentifier=letsmeet

[Install]
WantedBy=multi-user.target
```
letsmeet-sidekiq.service
```editorconfig
[Unit]
Description=letsmeet-sidekiq
# start us only once the network and logging subsystems are available,
# consider adding redis-server.service if Redis is local and systemd-managed.
After=syslog.target network.target

# See these pages for lots of options:
# http://0pointer.de/public/systemd-man/systemd.service.html
# http://0pointer.de/public/systemd-man/systemd.exec.html
[Service]
Type=simple
WorkingDirectory=/home/ubuntu/letsmeet
# If you use rbenv or rvm:
ExecStart=/bin/bash -lc 'bundle exec sidekiq -q default -q mailers'
# If you use the system's ruby:
# ExecStart=bundle exec sidekiq -e production
User=ubuntu
Group=ubuntu
UMask=0002

# if we crash, restart
RestartSec=1
Restart=on-failure

# output goes to /var/log/syslog
StandardOutput=syslog
StandardError=syslog

# This will default to "bundler" if we don't specify it
SyslogIdentifier=letsmeet-sidekiq

[Install]
WantedBy=multi-user.target
```