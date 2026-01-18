<?php
require_once 'config.php';

// Enable error logging for debugging
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);
ini_set('error_log', __DIR__ . '/register_errors.log');

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed. Use POST.'
    ]);
    exit;
}

// Get JSON input
$rawInput = file_get_contents('php://input');
$input = json_decode($rawInput, true);

// Log the incoming request for debugging
error_log("Registration attempt - Raw input: " . substr($rawInput, 0, 200));
error_log("Registration attempt - Parsed input: " . print_r($input, true));

// Validate input
if (!isset($input['email']) || !isset($input['password'])) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Email and password are required'
    ]);
    exit;
}

$email = trim($input['email']);
$password = $input['password'];
$firebase_uid = isset($input['firebase_uid']) ? trim($input['firebase_uid']) : null;
$created_at = date('Y-m-d H:i:s');

// Validate email format
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid email format'
    ]);
    exit;
}

// Validate password length
if (strlen($password) < 8) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Password must be at least 8 characters'
    ]);
    exit;
}

try {
    $conn = getDBConnection();
    
    // Check if email already exists
    $checkStmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
    $checkStmt->bind_param("s", $email);
    $checkStmt->execute();
    $result = $checkStmt->get_result();
    
    if ($result->num_rows > 0) {
        $checkStmt->close();
        $conn->close();
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'Email already registered'
        ]);
        exit;
    }
    $checkStmt->close();
    
    // Hash password for storage (using password_hash with PASSWORD_DEFAULT)
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    
    // Insert user into database
    $stmt = $conn->prepare("INSERT INTO users (email, password, firebase_uid, created_at) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $email, $hashedPassword, $firebase_uid, $created_at);
    
    if ($stmt->execute()) {
        $userId = $conn->insert_id;
        $stmt->close();
        $conn->close();
        
        // Log successful registration
        error_log("User registered successfully - ID: $userId, Email: $email");
        
        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'User registered successfully',
            'user_id' => $userId,
            'email' => $email
        ]);
    } else {
        $errorMsg = "Failed to insert user: " . $stmt->error;
        error_log("Registration failed: $errorMsg");
        throw new Exception($errorMsg);
    }
    
} catch (Exception $e) {
    error_log("Registration exception: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Registration failed: ' . $e->getMessage()
    ]);
}
?>
