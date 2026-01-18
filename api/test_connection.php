<?php
// Simple connection test - returns success if API is reachable
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

echo json_encode([
    'success' => true,
    'message' => 'Connection successful!',
    'timestamp' => date('Y-m-d H:i:s'),
    'server' => $_SERVER['SERVER_NAME'] ?? 'unknown',
    'method' => $_SERVER['REQUEST_METHOD'] ?? 'unknown'
], JSON_PRETTY_PRINT);
?>
