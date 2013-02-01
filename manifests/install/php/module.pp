# == Resource lamp::install::php::module
#
#   This resource handles the installation of php modules
#
define lamp::install::php::module {

    anchor{ "lamp::install::php::module::${name}::begin": }

    Exec { path => "/bin:/usr/bin:/usr/sbin" }

    if ( member(["curl", "mysql", "intl", "xsl"], $name) ) {
        ::php::module { $name:
            require => Anchor["lamp::install::php::module::${name}::begin"],
            before  => Anchor["lamp::install::php::module::${name}::end"]
        }
    } elsif ( member(["apc", "soap"], $name) ) {
        ::php::module { $name:
            module_prefix => "php-",
            version       => "latest",
            require       => Anchor["lamp::install::php::module::${name}::begin"],
            before        => Anchor["lamp::install::php::module::${name}::end"]
        }
    } elsif ( $name == "dbunit" ) {
        # Make sure Yaml version is below 2.2. PHPUnit fails with Yaml 2.2 as of
        # DBUnit v1.2.1.
        ::php::pear::module { "pear.symfony.com/Yaml-2.1.6":
            use_package => false,
            alldeps     => true,
            require     => Anchor["lamp::install::php::module::${name}::begin"]
        }
        -> ::php::pear::module { "pear.phpunit.de/DbUnit":
            use_package => false,
            alldeps     => true,
            before      => Anchor["lamp::install::php::module::${name}::end"]
        }
    } elsif ( $name == "git" ) {
        ::php::pear::module { "pear/VersionControl_Git":
            use_package      => false,
            preferred_state  => "alpha",
            require          => Anchor["lamp::install::php::module::${name}::begin"],
            before           => Anchor["lamp::install::php::module::${name}::end"]
        }
    } elsif ( $name == "oauth" ) {
        package { "libpcre3-dev":
            ensure  => "latest",
            require => Anchor["lamp::install::php::module::${name}::begin"]
        }
        -> ::php::pecl::module { "oauth":
            use_package => false,
            before      => Anchor["lamp::install::php::module::${name}::end"]
        }
        -> file { "/etc/php5/conf.d/oauth.ini":
            ensure  => file,
            content => "extension=oauth.so",
            notify  => Service["apache2"]
        }
    } elsif ( $name == "phing" ) {
        ::php::pear::module { "pear.phing.info/phing":
            use_package => false,
            require     => Anchor["lamp::install::php::module::${name}::begin"],
            before      => Anchor["lamp::install::php::module::${name}::end"]
        }
    } elsif ( $name == "xdebug" ) {
        ::php::pecl::module { "xdebug":
            use_package => false,
            before      => Anchor["lamp::install::php::module::${name}::end"]
        }
        -> file { "/etc/php5/conf.d/xdebug.ini":
            ensure  => file,
            content => template("lamp/php/xdebug.ini"),
            notify  => Service["apache2"]
        }
    } else {
        fail("PHP module \"${name}\" installation is not yet supported by devtrw-lamp")
    }

    anchor{ "lamp::install::php::module::${name}::end":
        require => Anchor["lamp::install::php::module::${name}::begin"]
    }
}