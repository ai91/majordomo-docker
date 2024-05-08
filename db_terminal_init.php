<?php
/**
* Initializes db_terminal database for new installations
*/

chdir(dirname(__FILE__));

include_once("./config.php");

// temporary for debugging purposes. TODO remove this echoes
echo "DB_HOST = " . DB_HOST . PHP_EOL;
echo "DB_USER = " . DB_USER . PHP_EOL;
echo "DB_PASSWORD = " . DB_PASSWORD . PHP_EOL;
echo "DB_NAME = " . DB_NAME . PHP_EOL;

$retryInterval = 5;
$maxRetries = 10;
$retryCount = 0;

echo "Initializing database with db_terminal.sql content..." . PHP_EOL;
while ($retryCount < $maxRetries) {
	$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
	if ($mysqli->connect_error) {
		echo "Connection failed: " . $mysqli->connect_error . "\n";
		echo "Retrying in $retryInterval seconds...\n";
		sleep($retryInterval);
		$retryCount++;
	} else {
		echo "Connected successfully!\n";
		if(!$mysqli->query("DESCRIBE classes")) {
			$sql = file_get_contents('db_terminal.sql');
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
			} else {
				echo "Initializing database done" . PHP_EOL;
			}
		} else {
			echo "Database is good, skipping." . PHP_EOL;
		}
		$mysqli->close();
		break;
	}
}

if ($retryCount === $maxRetries) {
	echo "Unable to connect to the database after $maxRetries retries. Exiting...\n";
	exit(1);
}
