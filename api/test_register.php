<?php
// Test registration endpoint - for debugging
// This allows you to test registration directly from browser or Postman

require_once 'config.php';

// Allow GET for testing, but show instructions
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    ?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>Test Registration</title>
        <style>
            body { font-family: Arial; padding: 20px; }
            form { max-width: 400px; }
            input, button { width: 100%; padding: 10px; margin: 5px 0; }
            .result { margin-top: 20px; padding: 10px; border-radius: 5px; }
            .success { background: #d4edda; color: #155724; }
            .error { background: #f8d7da; color: #721c24; }
        </style>
    </head>
    <body>
        <h2>Test User Registration</h2>
        <p>Use this form to test registration directly:</p>
        <form method="POST">
            <input type="email" name="email" placeholder="Email" required>
            <input type="password" name="password" placeholder="Password (min 8 chars)" required>
            <input type="text" name="firebase_uid" placeholder="Firebase UID (optional)">
            <button type="submit">Register Test User</button>
        </form>
        
        <h3>Or use curl:</h3>
        <pre>
curl -X POST http://localhost/weathercropsapp/api/test_register.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'
        </pre>
    </body>
    </html>
    <?php
    exit;
}

// Handle POST request
header('Content-Type: application/json');

// Get input - support both form data and JSON
$input = [];
if ($_SERVER['CONTENT_TYPE'] === 'application/json') {
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);
} else {
    $input = $_POST;
}

// Validate
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

// Validate email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid email format'
    ]);
    exit;
}

// Validate password
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
    
    // Check if email exists
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
    
    // Hash password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    $created_at = date('Y-m-d H:i:s');
    
    // Insert user
    $stmt = $conn->prepare("INSERT INTO users (email, password, firebase_uid, created_at) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $email, $hashedPassword, $firebase_uid, $created_at);
    
    if ($stmt->execute()) {
        $userId = $conn->insert_id;
        $stmt->close();
        $conn->close();
        
        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'User registered successfully',
            'user_id' => $userId,
            'email' => $email,
            'created_at' => $created_at
        ], JSON_PRETTY_PRINT);
    } else {
        throw new Exception("Failed to insert user: " . $stmt->error);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Registration failed: ' . $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
