# == Resource: lamp::config::php::symfony2
#
#   Configures symfony 2 assets
#
define lamp::config::php::symfony2(
    $databaseHost,
    $databaseName,
    $databasePassword,
    $databaseUser,
    $secret,
    $sourceRoot = $name
) {
    file { "${sourceRoot}/app/config/parameters.yml":
        ensure => "file",
        content => template("lamp/symfony2/parameters.yml.erb")
    }
}