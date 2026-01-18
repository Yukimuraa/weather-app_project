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
    