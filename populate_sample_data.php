<?
error_reporting(0);
chdir("/var/www/bartlby-ui/");
include "config.php";
include "bartlby-ui.class.php";

$btl = new BartlbyUI($Bartlby_CONF, false);

$srv_obj = array(
        "server_name" => "Localhost",
        "server_ip" => "127.0.0.1",
        "server_port" => 9030,
        "server_icon" => "linux.gif",
        "server_enabled" => 1,
        "server_notify" => 1,
        "server_flap_seconds" =>120,
        "server_ssh_keyfile" => "",
        "server_ssh_passphrase" => "",
        "server_ssh_username" => "",
        "server_dead" => 0,
        "enabled_triggers" => "");

$add_server=bartlby_add_server($btl->RES, $srv_obj);
$btl->installPackage("default-pkg", $add_server, NULL, NULL);
echo "added a server with a default package for active checks";

 $svcgrp_obj = array(           "servicegroup_name" => "DEFAULT",
                                "servicegroup_active" => 1,
                                "servicegroup_notify" => 1,
                                "enabled_triggers" => "",
                                "servicegroup_members" => "",
                                "servicegroup_dead" => 0
                        );

                        $add_servergroup = bartlby_add_servicegroup($btl->RES, $svcgrp_obj);


$srvgrp_obj = array(
                                "servergroup_name" => "DEFAULT",
                                "servergroup_active" => 1,
                                "servergroup_notify" => 1,
                                "enabled_triggers" => "",
                                "servergroup_members" => "",
                                "servergroup_dead" => 0




                        );

                        $add_servergroup = bartlby_add_servergroup($btl->RES, $srvgrp_obj);

echo "added default server/service group";
