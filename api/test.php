<?php
require_once 'config.php';

// Simple test endpoint to verify API is working
header('Content-Type: application/json');

$response = [
    'success' => true,
    'message' => 'API is working!',
    'timestamp' => date('Y-m-d H:i:s'),
    'database_status' => 'unknown'
];

// Test database connection
try {
    $conn = getDBConnection();
    $response['database_status'] = 'connected';
    $response['database_name'] = DB_NAME;
    
    // Check if users table exists
    $result = $conn->query("SHOW TABLES LIKE 'users'");
    if ($result->num_rows > 0) {
        $response['table_exists'] = true;
        
        // Get user count
        $countResult = $conn->query("SELECT COUNT(*) as count FROM users");
        $countRow = $countResult->fetch_assoc();
        $response['user_count'] = $countRow['count'];
    } else {
        $response['table_exists'] = false;
        $response['message'] = 'Database connected but users table does not exist. Please run database.sql';
    }
    
    $conn->close();
} catch (Exception $e) {
    $response['database_status'] = 'failed';
    $response['database_error'] = $e->getMessage();
    $response['message'] = 'Database connection failed';
}

echo json_encode($response, JSON_PRETTY_PRINT);
?>
