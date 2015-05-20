<?

chdir("/var/www/bartlby-ui/");
include "config.php";
include "layout.class.php";
include "bartlby-ui.class.php";

$btl = new BartlbyUI($Bartlby_CONF, false);


$server_dummy = array(
                                        "server_name" => "localhost",
                                        "server_ip" => "localhost",
                                        "server_port" => 9030,
                                        "server_icon" => "linux.gif",
                                        "server_enabled" => 1,
                                        "server_notify" => 1,
                                        "server_flap_seconds" => 122,
                                        "server_ssh_keyfile" => "",
                                        "server_ssh_passphrase" => "",
                                        "server_ssh_username" => "",
                                        "server_dead" => 0,
                                        "exec_plan" => "",
                                        "enabled_triggers" => "",
                                        "default_service_type" => 1,
                                        "orch_id" => 0,
                                        "web_hooks" => "",
                                        'json_endpoint' => "",
                                        'web_hooks_level' => 0

                                );

$add_server=bartlby_add_server($btl->RES, $server_dummy);


$p = $btl->installPackage("default-pkg", $add_server, NULL, NULL);
echo "added a server with a default package for active checks";


$servergroup_dummy = array(
                                "servergroup_name" => "DEFAULT",
                                "servergroup_active" => 1,
                                "servergroup_notify" => 1,
                                "enabled_triggers" => "",
                                "servergroup_members" => "",
                                "servergroup_dead" => 0,
                                "orch_id" => 0

                        );
                        $servicegroup_dummy = array(
                                "servicegroup_name" => "DEFAULT",
                                "servicegroup_active" => 1,
                                "servicegroup_notify" => 1,
                                "enabled_triggers" => "",
                                "servicegroup_members" => "",
                                "servicegroup_dead" => 0,
                                "orch_id" => 0

                        );


                        $add_servergroup = bartlby_add_servicegroup($btl->RES, $servicegroup_dummy);


                        $add_servergroup = bartlby_add_servergroup($btl->RES, $servergroup_dummy);

echo "added default server/service group";
