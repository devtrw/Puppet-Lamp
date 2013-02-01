# == Resource: lamp::app
#
#   This resource handles installing and configuring php/mysql app
#   TODO:
#       $serverAliases
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
# [*composerDir*]
#   The directory where composer configuration is stored and installed to if
#   enabled. Installs downloads composer.phar and installs composer assets into
#   vendor directory if not present. Defaults to [*sourceLocation*]. If
#   [*symfony2app*] is true it will be set to [*symfony2root*]
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
#   a vhost will be created for each value present.
#
# [*symfony2App*]
#   If set to true will configure the application for symfony2
#
# [*symfony2Root*]
#   The application root for the symfony2 install, defaults to [*sourceLocation*]
#
# [*symfony2secret*]
#   The key used for the symfony 2 configuration. This is required for symfony2
#   apps
#
# [*useSsl*]
#   If set to true, additional vhosts will be created on port 443 for the hosts
#   in [*sslVhosts*]
#
define lamp::app (
    $databasePassword,
    $sourceLocation,
    $apacheDirectives  = {},
    $apacheLogLevel    = "warn",
    $apacheLogRoot     = "/var/log/apache2",
    $composerDir       = $sourceLocation,
    $databaseHost      = "localhost",
    $databaseName      = $name,
    $databaseUser      = $name,
    $documentRoot      = $sourceLocation,
    $installComposer   = false,
    $serverName        = $::lamp::serverName,
    $serverAliases     = ["www.${serverName}"],
    $sslVhosts         = {
        "${serverName}" => {
            "cert" => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
            "key"  => "/etc/ssl/private/ssl-cert-snakeoil.key"
        }
    },
    $symfony2App       = false,
    $symfony2Root      = $sourceLocation,
    $symfony2Secret    = "UNSET",
    $useSsl            = false
) {
    validate_absolute_path(
        $apacheLogRoot, $composerDir, $documentRoot, $sourceLocation,
        $symfony2Root
    )
    validate_array($serverAliases)
    validate_bool($installComposer, $symfony2App, $useSsl)
    validate_hash($apacheDirectives, $sslVhosts)
    validate_string(
        $apacheLogLevel, $databaseHost, $databaseName, $databasePassword,
        $databaseUser, $serverName
    )

    if ($::lamp::developmentEnvironment == false)
    and ($databasePassword == "password") {
        fail(
"The \$lamp::app::database password cannot be \"password\" in a production \
environment"
        )
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

    # Create user for app if necessary
    if ( !defined(User[$name]) )
    {
        user { $name:
            ensure     => "present",
            managehome => "true"
        }
    }

    # Setup database
    ::mysql::user { $databaseUser:
        mysql_host     => $databaseHost,
        mysql_password => $databasePassword,
        mysql_user     => $databaseUser
    }
    -> ::mysql::grant { $databaseName:
        mysql_host     => $databaseHost,
        mysql_db       => $databaseName,
        mysql_password => $databasePassword,
        mysql_user     => $databaseUser
    }

    $defaultApacheDirectives = {
        "Options"       => "-Indexes +FollowSymLinks",
        "AllowOverride" => "ALL",
        "Order"         => "Allow,Deny",
        "Allow"         => "from all"
    }
    $realApacheDirectives = merge ($defaultApacheDirectives, $apacheDirectives)

    # Setup virtual host
    ::lamp::config::apache::vhost { "${serverName}-80":
        directives     => $realApacheDirectives,
        documentRoot   => $documentRoot,
        serverAliases  => $serverAliases,
        serverName     => $serverName,
        vhostLogLevel  => $apacheLogLevel,
        vhostLogRoot   => $apacheLogRoot
    }

    # Setup ssl vhosts if necessary
    if ($useSsl == true) {
        $sslDomains = keys($sslVhosts)
        ::lamp::config::apache::vhost { $sslDomains:
            directives     => $realApacheDirectives,
            documentRoot   => $documentRoot,
            vhostLogLevel  => $apacheLogLevel,
            vhostLogRoot   => $apacheLogRoot,
            sslVhosts      => $sslVhosts,
            useSsl         => true
        }
    }

    # Install composer if necessary
    $realComposerDir = $symfony2app ? {
        true    => $symfony2root,
        default => $composerDir
    }
    if ($installComposer) {
        class { "::composer": installLocation => $composerDir }
    }

    # Create symfony config if specified
    if ($symfony2App ) {
        if ($symfony2Secret == "UNSET") {
            fail( "\n\
symfony2Secret must be defined for symfony2 applications. The \
following command can generate one for you: \n\n\
< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c\${1:-32};echo;\n\n")
        }
        ::lamp::config::php::symfony2 { $symfony2Root:
            databaseHost     => $databaseHost,
            databaseName     => $databaseName,
            databasePassword => $databasePassword,
            databaseUser     => $databaseUser,
            secret           => $symfony2Secret
        }
    }
}