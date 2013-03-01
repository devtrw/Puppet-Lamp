# == Resource: lamp::app
#
#   This resource handles installing and configuring php/mysql app
#
# === Parameters
#
# ==== Required
#
# [*databasePassword*]
#   The password for the application database
#
# [*sourceLocation*]
#   The root of the application source.
#
# ==== Optional
#
# [*apacheDirectives*]
#   A hash of directives for the virtual host directory. Any value passed in
#   will override the default values. The defaults set are:
#   {
#       "Options" => "-Indexes +FollowSymLinks",
#       "AllowOverride" => "ALL",
#       "Order"         => "Allow,Deny",
#       "Allow"         => "from all"
#   }
#
# [*apacheLogLevel*]
#   Defaults to "warn"
#
# [*apacheLogRoot*]
#   The log root for apache, defaults to /var/log/apache2 . Logs will be named
#   [*serverName*]-error_log and [*serverName*]-access_log
#
# [*createDatabase*]
#   Set to false to disable creation of the database and user
#
# [*createUser*]
#   Will create a user with the name of this resource. Default is true
#
# [*databaseHost*]
#   The host for the database
#
# [*databaseName*]
#   The name for the database of the application. Defaults to [*name*]
#
# [*databaseUser*]
#   The user for the database of the application. Defaults to [*name*]
#
# [*documentRoot*]
#   The document root for the application. Defaults to [*sourceLocation*]
#
# [*installComposer*]
#   Installs composer and vendors into [*composerDir*] if enabled. Disabled by
#   default
#
# [*serverName*]
#   The server name to be used for the virtual host. Defaults to
#   [*::lamp::serverName*]
#
# [*serverAliases*]
#   An array of aliases for the virtual host. Default is ["www.${serverName}"]
#
# [*sslVhosts*]
#   A hash of vhosts and their key/cert locations. If [*useSsl*] is set to true
#   a vhost will be created for each value present. For example:
#   {
#       "example.com" => {
#           "cert" => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
#           "key"  => "/etc/ssl/private/ssl-cert-snakeoil.key"
#       }
#   }
#
# [*useSsl*]
#   If set to true, additional vhosts will be created on port 443 for the hosts
#   in [*sslVhosts*]
#
define lamp::app (
    $documentRoot,
    $apacheDirectives  = {},
    $apacheLogLevel    = "warn",
    $apacheLogRoot     = "/var/log/apache2",
    $apachePriority    = "UNSET",
    $createUser        = true,
    $createDatabase    = true,
    $databaseHost      = "localhost",
    $databaseName      = $name,
    $databasePassword  = "UNSET",
    $databaseUser      = $name,
    $serverName        = $::lamp::serverName,
    $serverAliases     = [],
    $sslVhosts         = {},
    $useSsl            = false
) {
    validate_absolute_path($apacheLogRoot, $documentRoot)
    validate_array($serverAliases)
    validate_bool($createUser, $createDatabase, $useSsl)
    validate_hash($apacheDirectives, $sslVhosts)
    validate_string(
        $apacheLogLevel,
        $apachePriority,
        $databaseHost,
        $databaseName,
        $databasePassword,
        $databaseUser,
        $serverName
    )

    if ($createDatabase == true) and ($databasePassword == "UNSET") {
        fail("A database password must be set unless \$createDatabase is false")
    }

    if ($useSsl == true) {
        if ($::lamp::apacheModSsl != true) {
            fail("Apache mod ssl must be enabled. See \$lamp::apacheModSsl")
        } elsif ($sslVhosts == {}) {
            fail(
"To enable ssl you must specify which hosts in the \$sslVhosts param"
            )
        }
    }

    anchor { "lamp::app::${name}::begin": }

    # Create user for app if necessary
    if (!defined(User[$name])) and ($createUser == true)
    {
        user { $name:
            before     => Anchor["lamp::app::${name}::end"],
            ensure     => "present",
            managehome => "true",
            require    => Anchor["lamp::app::${name}::begin"]
        }
    }

    # Setup database
    if ($createDatabase == true) {
        ::mysql::user { $databaseUser:
            before         => Anchor["lamp::app::${name}::end"],
            mysql_host     => $databaseHost,
            mysql_password => $databasePassword,
            mysql_user     => $databaseUser,
            require        => Anchor["lamp::app::${name}::begin"]
        }
        -> ::mysql::grant { $databaseName:
            before         => Anchor["lamp::app::${name}::end"],
            mysql_host     => $databaseHost,
            mysql_db       => $databaseName,
            mysql_password => $databasePassword,
            mysql_user     => $databaseUser,
            require        => Anchor["lamp::app::${name}::begin"]
        }
    }

    $defaultApacheDirectives = {
        "Options"       => "-Indexes +FollowSymLinks",
        "AllowOverride" => "ALL",
        "Order"         => "Allow,Deny",
        "Allow"         => "from all"
    }
    $realApacheDirectives = merge($defaultApacheDirectives, $apacheDirectives)

    # Setup virtual host
    ::lamp::config::apache::vhost { "${serverName}-80":
        before         => Anchor["lamp::app::${name}::end"],
        directives     => $realApacheDirectives,
        documentRoot   => $documentRoot,
        priority       => $apachePriority,
        serverAliases  => $serverAliases,
        serverName     => $serverName,
        vhostLogLevel  => $apacheLogLevel,
        vhostLogRoot   => $apacheLogRoot,
        require        => Anchor["lamp::app::${name}::begin"]
    }

    # Setup ssl vhosts if necessary
    if ($useSsl == true) {
        $sslDomains = keys($sslVhosts)
        ::lamp::config::apache::vhost { $sslDomains:
            before         => Anchor["lamp::app::${name}::end"],
            directives     => $realApacheDirectives,
            documentRoot   => $documentRoot,
            priority       => $apachePriority,
            vhostLogLevel  => $apacheLogLevel,
            vhostLogRoot   => $apacheLogRoot,
            require        => Anchor["lamp::app::${name}::begin"],
            sslVhosts      => $sslVhosts,
            useSsl         => true
        }
    }

    anchor { "lamp::app::${name}::end":
        require => Anchor["lamp::app::${name}::begin"]
    }
}
