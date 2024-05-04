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
		if (!is_null($val)) {
			define($env, $val);
		}
	}
}

date_default_timezone_set('UTC');

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
define_docker('DOC_ROOT', dirname(__FILE__));              // Your htdocs location (should be detected automatically)
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

define_docker('USE_PROXY', null);
define_docker('USE_PROXY_AUTH', null);
define_docker('HISTORY_NO_OPTIMIZE', null);
define_docker('ONEWIRE_SERVER', null);
define_docker('HOME_NETWORK', null);
define_docker('EXT_ACCESS_USERNAME', null);
define_docker('EXT_ACCESS_PASSWORD', null);
define_docker('DROPBOX_SHOPPING_LIST', null);
define_docker('WAIT_FOR_MAIN_CYCLE', null);
define_docker('TRACK_DATA_CHANGES', null);
define_docker('TRACK_DATA_CHANGES_IGNORE', null);
define_docker('SEPARATE_HISTORY_STORAGE',null);
define_docker('LOG_DIRECTORY', null);
define_docker('LOG_MAX_SIZE', null);
define_docker('LOG_CYCLES', null);
define_docker('PATH_TO_FFMPEG', null);
define_docker('ENABLE_PANEL_ACCELERATION', null);
define_docker('VERBOSE_LOG', null);
define_docker('VERBOSE_LOG_IGNORE', null);
define_docker('DISABLE_SIMPLE_DEVICES', null);
define_docker('AUDIO_PLAYER', null);
define_docker('ENABLE_FORK', null);
define_docker('PYTHON_PATH', null);
define_docker('LOCAL_IP', null);
define_docker('BTRACED', null);
define_docker('LOWER_BACKGROUND_PROCESSES', null);
define_docker('USE_REDIS', null);
define_docker('LOG_FILES_EXPIRE', null);
define_docker('BACKUP_FILES_EXPIRE', null);
define_docker('CACHED_FILES_EXPIRE', null);
define_docker('SETTINGS_ERRORS_KEEP_HISTORY', null);

include_once("./db_terminal_init.php");