<?php
// Quick script to check all users in the database
require_once 'config.php';

header('Content-Type: application/json');

try {
    $conn = getDBConnection();
    
    $result = $conn->query("SELECT id, email, firebase_uid, created_at FROM users ORDER BY created_at DESC");
    
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
    
    $conn->close();
    
    echo json_encode([
        'success' => true,
        'count' => count($users),
        'users' => $users
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
