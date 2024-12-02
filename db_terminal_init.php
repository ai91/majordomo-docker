<?php
/**
* Initializes db_terminal database for new installations
*/

chdir(dirname(__FILE__));

include_once("./config.php");

// keep trying to connect during 2 minutes
$retryInterval = 6;
$maxRetries = 20;
$retryCount = 0;

echo "Initializing database with db_terminal.sql content..." . PHP_EOL;
while ($retryCount < $maxRetries) {
	try {
		$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
		$dbConnectError = $mysqli->connect_error;
	} catch (mysqli_sql_exception $e) {
		$dbConnectError = true;
	}
	if ($dbConnectError) {
		echo "Connection failed: " . $mysqli->connect_error . ". Is database still starting up?" . PHP_EOL;
		echo "Retrying in $retryInterval seconds..." . PHP_EOL;
		sleep($retryInterval);
		$retryCount++;
	} else {
		echo "Connected successfully." . PHP_EOL;
		try {
			$dbInitialized = $mysqli->query("DESCRIBE classes");
		} catch (mysqli_sql_exception $e) {
			$dbInitialized = false;
		}
		if($dbInitialized) {
			echo "Database is good, skipping." . PHP_EOL;
		} else {
			$db_dump = file_get_contents('db_terminal.sql');
			$sqlsArray = preg_split('/;[\n\r]/', $db_dump);
			foreach($sqlsArray as $sql) {
				$sql = trim($sql);
				if (!empty($sql)) {
					if ($mysqli->multi_query($sql)) {
						do {
							if ($result = $mysqli->store_result()) {
								$result->free();
							}
						} while ($mysqli->more_results() && $mysqli->next_result());
					}
					if ($mysqli->errno) {
						echo "Initialization failed." . PHP_EOL;
						var_dump($mysqli->error);
						break;
					}
				}
			}
			if (!$mysqli->errno) {
				echo "Initializing database done" . PHP_EOL;
			}
		}
		$mysqli->close();
		break;
	}
}

if ($retryCount === $maxRetries) {
	echo "Unable to connect to the database after $maxRetries retries. Exiting..." . PHP_EOL;
	exit(1);
}
