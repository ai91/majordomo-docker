<?php
/**
* Initializes db_terminal database for new installations
*/

$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

if(!$mysqli->query("DESCRIBE settings")) {
	$sql = file_get_contents('db_terminal.sql');
	$mysqli->multi_query($sql);
}
