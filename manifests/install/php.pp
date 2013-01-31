# == lamp::install::php
#
#   This class installs php
#
class lamp::install::php (
    $defaultTimezone,
    $developmentEnvironment,
    $modules,
    $settings,
    $version
) {
    if ($developmentEnvironment == true) {
        $displayErrors         = "on"
        $displayStartupErrors  = "on"
    } else {
        $displayErrors         = "off"
        $displayStartupErrors  = "off"
    }

    $defaultSettings = {
        "Date/date.timezone"         => $defaultTimezone,
        "PHP/display_errors"         => $displayErrors,
        "PHP/display_startup_errors" => $displayStartupErrors,
        "PHP/error_reporting"        => "E_ALL",
        "PHP/log_errors"             => "on",
        "PHP/short_open_tag"         => "off"
    }
    $mergedSettings = merge($defaultSettings, $settings)
    $settingTargets = keys($mergedSettings)

    anchor{ "lamp::install::php::begin": }
    -> class { "::php": version => $version }
    -> lamp::install::php::module { $modules: }
    -> lamp::config::php::ini { $settingTargets: settings => $mergedSettings }
    -> anchor { "lamp::install::php::end": }
}