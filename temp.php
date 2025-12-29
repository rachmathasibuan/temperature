<?php
/*
 * Simple Sensor Data Receiver (JSON Output)
 *
 * Copyright (c) 2025 John
 * All rights reserved.
 */

define('API_KEY', 'wlksdnfUBDlkndfjbdjfSDJBmdflmdf');
header('Content-Type: application/json');

$apiKey =
    $_SERVER['HTTP_X_API_KEY']
    ?? $_POST['key']
    ?? $_GET['key']
    ?? null;

if ($apiKey !== API_KEY) {
    http_response_code(401);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid API Key"
    ]);
    exit;
}

$conn = new mysqli(
    "103.125.103.155",
    "leonor",
    "805@leonor",
    "temp",
    33061
);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode([
        "status" => "error",
        "message" => "Database connection failed"
    ]);
    exit;
}

$temp = $_POST['temp'] ?? $_GET['temp'] ?? null;
$hum  = $_POST['hum']  ?? $_GET['hum']  ?? null;

if (!is_numeric($temp) || !is_numeric($hum)) {
    http_response_code(400);
    echo json_encode([
        "status" => "error",
        "message" => "Invalid data"
    ]);
    exit;
}

$stmt = $conn->prepare(
    "INSERT INTO data (temp, hum) VALUES (?, ?)"
);
$stmt->bind_param("dd", $temp, $hum);
$stmt->execute();

$result = $conn->query(
    "SELECT temp, hum, event
     FROM data
     ORDER BY id DESC
     LIMIT 1"
);

$row = $result->fetch_assoc();
$conn->close();

echo json_encode([
    "status" => "success",
    "current" => [
        "temperature" => (float)$row['temp'],
        "humidity"    => (float)$row['hum'],
        "event"       => $row['event']
    ]
]);
