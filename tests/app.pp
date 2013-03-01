class { "lamp":
    apacheListenPorts      => [80, 443],
    apacheModSsl           => true,
    developmentEnvironment => true,
    serverName             => 'puppet-lamp.dev',
    phpModules             => [
        "curl", "gd", "intl", "mysql", "xsl",
        "imagick",
        "apc", "soap",
        "git",
        "oauth",
        "phing",
        "phpcs",
        "phpcpd",
        "phpmd",
        "xdebug",
        "phpunit"
    ]
}


lamp::app { "minimal":
    documentRoot     => "/vagrant/tests/web/minimal",
    createUser       => false,
    createDatabase   => false,
    serverName       => "minimal.puppet-lamp.dev"
}

lamp::app { "full":
    documentRoot     => "/vagrant/tests/web/full",
    apacheDirectives => { "Options" => "+Indexes +FollowSymLinks" },
    apacheLogRoot    => "/vagrant/tests/web/full/logs",
    apachePriority   => "99",
    createUser       => true,
    createDatabase   => true,
    databaseName     => "full",
    databasePassword => "password",
    databaseUser     => "full",
    serverAliases    => ["alias.puppet-lamp.dev"],
    serverName       => "full.puppet-lamp.dev",
    useSsl           => true,
    sslVhosts        => {
        "ssl1.puppet-lamp.dev" => {
             "cert" => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
             "key"  => "/etc/ssl/private/ssl-cert-snakeoil.key"
        },
        "ssl2.puppet-lamp.dev" => {
             "cert" => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
             "key"  => "/etc/ssl/private/ssl-cert-snakeoil.key"
        }
    }
}
