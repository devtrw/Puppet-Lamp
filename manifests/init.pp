# == Class: lamp
#
#   This class handles common assets for a LAMP stack running php 5.4
#
#   If you are curious about the anchors all over the place see:
#   http://projects.puppetlabs.com/issues/8040
#   Be careful when modifying this script
#
# === Parameters
#
# [*apacheListenPorts*]
#   An array specifying which ports apache should listen to. It will add
#   NameVirtualHost *:<PORT> and Listen entries to the apache ports.conf file.
#   Duplicate ports are ignore.
#
# [*apacheModSsl*]
#   Enables the ssl mod for Apache and adds port 443 to [*apacheListenPorts*]
#
# [*apacheModRewrite*]
#   Enables Apache's mod rewrite
#
# [*aptRepositories*]
#   Any additional apt repositories you would like added to the system
#
# [*developmentEnvironment*]
#   Sets up the environment for development:
#     * Sets the php.ini defaults to display errors
#     * Installs PHPUnit/DBUnit
#     * Installs xdebug
#     * Installs phpcs
#
# [*mysqlConfig*]
#   Sets configuration directives in the /etc/mysql/conf.d/settings.conf file.
#   For example to add:
#       [mysqld]
#       wait_timeout = 31536000
#   Pass in:
#   {
#       "mysqld" => {
#           "wait_timeout" => "31536000"
#       }
#   }
#
# [*mysqlRootPassword]
#   The password set for the mysql root user. If set to "auto" a randomly
#   generated number will be used as the root password. This password is stored
#   in /root/.my.cnf and backed up to /root/.my.cnf.backup when changed.
#
# [*phpIniSettings*]
#   This is a hash of php ini settings to set. The format is:
#   { "Section/target_setting" => "value" }
#   For example, to change the display_errors setting under the [PHP] section:
#   { "PHP/display_errors" => "A_ALL" }
#
# [*phpModules*]
#   An array of php modules to install
#
# [*serverName*]
#   Is set as the Apache HostName entry in httpd.conf
#
# [*timezone*]
#   This is used to set the system time and the php time zone. The current
#   supported values are: PST
#
class lamp (
    $apacheListenPorts      = [80],
    $apacheModSsl           = false,
    $apacheModRewrite       = true,
    $aptRepositories        = [],
    $developmentEnvironment = true,
    $mysqlConfig            = {},
    $mysqlRootPassword      = "auto",
    $phpIniSettings         = {},
    $phpModules             = [],
    $phpVersion             = "5.4.14-1~precise+1",
    $serverName             = $::fqdn,
    $timezone               = "PST"
) {
    validate_array($apacheListenPorts, $aptRepositories, $phpModules)
    validate_bool($apacheModSsl, $apacheModRewrite, $developmentEnvironment)
    validate_hash($phpIniSettings, $mysqlConfig)
    validate_string($mysqlRootPassword, $phpVersion, $serverName, $timezone)

    # Ensure ubuntu
    if ($::operatingsystem != "ubuntu") {
        fail("This module currently only supports ubuntu")
    }

    # Ensure server name is set
    if ($serverName == undef) {
        fail("\
\$serverName must be defined, this defaults to \$::fqdn which is not \
present. This is usually because factor could not find it.")
    }

    # Ensure valid timezone
    $timezones = {
        "PST" => {
            localtimePath => "/usr/share/zoneinfo/PST8PDT",
            phpTimezone   => "America/Los_Angeles"
        }
    }
    if (!has_key($timezones, $timezone))
    {
        fail("The timezone ${timezone} is not supported")
    }

    if ( member($phpModules, "dev") ) {
            fail("\
The php dev module is installed automatically, please remove it from \
\$phpModules")
    }

    anchor { "init::begin": }

    # Configure the server
    class { "lamp::config::system":
        before   => Anchor["init::end"],
        require  => Anchor["init::begin"],
        timezone => $timezones[$timezone][localtimePath]
    }

    $defaultRepositories = ["ppa:ondrej/php5"]
    $allAptRepositories = flatten($defaultRepositories, $aptRepositories)
    include ::apt
    ::apt::ppa { $allAptRepositories:
        require => Class["lamp::config::system"]
    }

    # Install apache
    class { "lamp::install::apache":
        listenPorts            => $apacheListenPorts,
        developmentEnvironment => $developmentEnvironment,
        enableModRewrite       => $apacheModRewrite,
        enableModSsl           => $apacheModSsl,
        serverName             => $serverName,
        require                => ::Apt::Ppa[$allAptRepositories],
        before                 => Anchor["init::end"]
    }

    # Install mysql
    class { "lamp::install::mysql":
        config       => $mysqlConfig,
        rootPassword => $mysqlRootPassword,
        require      => ::Apt::Ppa[$allAptRepositories],
        before       => Anchor["init::end"]
    }

    # Install php
    class { "lamp::install::php":
        defaultTimezone        => $timezones[$timezone][phpTimezone],
        developmentEnvironment => $developmentEnvironment,
        modules                => $phpModules,
        settings               => $phpIniSettings,
        version                => $phpVersion,
        require                => ::Apt::Ppa[$allAptRepositories],
        before                 => Anchor["init::end"]
    }

    anchor { "init::end": require => Anchor["init::begin"] }
}
