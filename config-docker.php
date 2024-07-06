<?php
/**
* Project Config for docker container
*/

// a helper function to lookup "env_FILE", "env", then fallback
if (!function_exists('getenv_docker')) {
	function getenv_docker($env, $default) {
		if ($fileEnv = getenv($env . '_FILE')) {
			return rtrim(file_get_contents($fileEnv), "\r\n");
		}
		else if (($val = getenv($env)) !== false) {
			return $val;
		}
		else {
			return $default;
		}
	}
}

// a helper function to define constant based on environment variable
if (!function_exists('define_docker')) {
	function define_docker($env, $default) {
		$val = getenv_docker('MAJORDOMO_'.$env, $default);
		if (!is_null($val) && !defined($env)) {
			define($env, $val);
		}
	}
}

date_default_timezone_set('UTC');

foreach ($_ENV as $key => $value) {
    if (strpos($key, 'MAJORDOMO_') === 0) {
        $customEnvVar = substr($key, strlen('MAJORDOMO_'));
        define_docker($customEnvVar, null);
    }
}

define_docker('DB_HOST', 'localhost');
define_docker('DB_NAME', 'db_terminal');
define_docker('DB_USER', 'root');
define_docker('DB_PASSWORD', '');
define_docker('DIR_TEMPLATES', "./templates/");
define_docker('DIR_MODULES', "./modules/");
define_docker('DEBUG_MODE', 1);
define_docker('UPDATES_REPOSITORY_NAME', 'smarthome');
define_docker('PROJECT_TITLE', 'MajordomoSL');
define_docker('PROJECT_BUGTRACK', "bugtrack@smartliving.ru");
define_docker('DOC_ROOT', dirname(__FILE__));
define_docker('SERVER_ROOT', '/var/www/html');
define_docker('PATH_TO_PHP', 'php');
define_docker('PATH_TO_MYSQLDUMP', "mysqldump");
define_docker('BASE_URL', 'http://127.0.0.1:80');              
define_docker('ROOT', DOC_ROOT."/");
define_docker('ROOTHTML', "/");
define_docker('PROJECT_DOMAIN', isset($_SERVER['SERVER_NAME']) ? $_SERVER['SERVER_NAME'] : php_uname("n"));
define_docker('GIT_URL', 'https://github.com/sergejey/majordomo/');
define_docker('MASTER_UPDATE_URL', GIT_URL.'archive/master.tar.gz');
define_docker('GETURL_WARNING_TIMEOUT',5);

$restart_threads = explode(',', getenv_docker('MAJORDOMO_RESTART_THREADS', 'cycle_execs.php,cycle_main.php,cycle_ping.php,cycle_scheduler.php,cycle_states.php,cycle_webvars.php'));
$aditional_git_urls = explode(',', getenv_docker('MAJORDOMO_ADITIONAL_GIT_URLS', ''));

