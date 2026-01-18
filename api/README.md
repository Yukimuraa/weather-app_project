# Database Setup Instructions

This guide will help you set up the MySQL database for user registration.

## Step 1: Create the Database

1. Open phpMyAdmin in your browser: `http://localhost/phpmyadmin`
2. Click on the "SQL" tab
3. Copy and paste the contents of `database.sql` file
4. Click "Go" to execute

Alternatively, you can import the `database.sql` file directly:
- Click on "Import" tab in phpMyAdmin
- Choose the `database.sql` file
- Click "Go"

## Step 2: Configure Database Connection

If your MySQL settings are different from the default XAMPP settings, edit `config.php`:

```php
define('DB_HOST', 'localhost');  // Change if needed
define('DB_USER', 'root');       // Change if you have a different username
define('DB_PASS', '');           // Change if you have a password
define('DB_NAME', 'weathercropsapp'); // Database name
```

## Step 3: Update Flutter App URL

Edit `lib/services/database_service.dart` and update the `baseUrl`:

### For Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2/weathercropsapp/api';
```

### For Physical Device:
1. Find your computer's IP address:
   - Windows: Open Command Prompt and type `ipconfig`
   - Look for "IPv4 Address" (e.g., 192.168.1.100)
2. Update the URL:
```dart
static const String baseUrl = 'http://192.168.1.100/weathercropsapp/api';
```

### For Web:
```dart
static const String baseUrl = 'http://localhost/weathercropsapp/api';
```

## Step 4: Test the API

You can test the registration endpoint using a tool like Postman or curl:

```bash
curl -X POST http://localhost/weathercropsapp/api/register.php \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test1234!"}'
```

## How It Works

1. When a user registers in the Flutter app:
   - First, the user is registered with Firebase Authentication
   - Then, the user data is saved to your MySQL database via the PHP API
   - The user's email, hashed password, and Firebase UID (if available) are stored

2. The registration data will appear in phpMyAdmin:
   - Open phpMyAdmin
   - Select the `weathercropsapp` database
   - Click on the `users` table
   - You'll see all registered users with their email, creation date, etc.

## Troubleshooting

### Connection Refused Error
- Make sure XAMPP Apache and MySQL services are running
- Check that the URL in `database_service.dart` is correct for your platform

### Database Connection Failed
- Verify MySQL is running in XAMPP
- Check database credentials in `config.php`
- Ensure the database `weathercropsapp` exists

### Email Already Exists
- The API checks for duplicate emails
- Each email can only be registered once

## Security Notes

- Passwords are hashed using PHP's `password_hash()` function
- Never store plain text passwords
- The API includes basic validation for email format and password length
- For production, consider adding:
  - Rate limiting
  - HTTPS/SSL
  - More robust input validation
  - API authentication tokens
