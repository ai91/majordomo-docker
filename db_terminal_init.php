<?php
/**
* Initializes db_terminal database for new installations
*/

$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

if(!$mysqli->query("DESCRIBE settings")) {
	echo "Initializing database with db_terminal.sql content..." . PHP_EOL;
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
}
$mysqli->close();
