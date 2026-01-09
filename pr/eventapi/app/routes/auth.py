from flask import Blueprint, request, jsonify
from app.utils.supabase_client import supabase_client
from app.utils.decorators import token_required
import re
import random
from datetime import datetime, timedelta

from app.utils.email_utils import send_email

verification_codes = {} 
# Blueprint
auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


# ---------- HELPERS ----------
def validate_email(email):
    pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return re.match(pattern, email) is not None


def validate_username(username):
    pattern = r'^[a-zA-Z0-9_]{3,20}$'
    return re.match(pattern, username) is not None


# ---------- SIGNUP ----------
@auth_bp.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()
        username = data.get('username', '').strip().lower()
        password = data.get('password', '')
        role = data.get('role', 'participant')

        if not email or not username or not password:
            return jsonify({'error': 'Please fill all fields'}), 400

        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        if not validate_username(username):
            return jsonify({'error': 'Invalid username'}), 400

        if len(password) < 6:
            return jsonify({'error': 'Password too short'}), 400

        supabase = supabase_client.client

        # Check username
        existing_username = supabase.table('users').select('id').eq('username', username).execute()
        if existing_username.data:
            return jsonify({'error': 'Username already taken'}), 400

        # ✅ FIX: Create auth user with email confirmation DISABLED for development
        auth_response = supabase.auth.sign_up({
            'email': email,
            'password': password,
            'options': {
                'email_redirect_to': None,  # Disable email confirmation for development
            }
        })

        if not auth_response.user:
            return jsonify({'error': 'Failed to create account'}), 400

        # Insert public profile
        user_data = {
            'id': auth_response.user.id,
            'email': email,
            'username': username,
            'role': role,
            'selected_categories': [],
            'profile_photo_url': None,
            'is_email_verified': True  # ✅ Set to True for development
        }

        supabase.table('users').insert(user_data).execute()

        # ✅ Return session - user can login immediately
        # Check if session exists
        if not auth_response.session:
            return jsonify({'error': 'Signup failed: No session returned'}), 500

        return jsonify({
            'message': 'Signup successful',
            'user': {
                'id': auth_response.user.id,
                'email': email,
                'username': username,
                'role': role,
                'selectedCategories': [],
                'profilePhotoUrl': None,
            },
            'session': {
                'access_token': auth_response.session.access_token,
                'refresh_token': auth_response.session.refresh_token
            }
        }), 201

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/send-verification', methods=['POST'])
def send_verification():
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()
        if not email:
            return jsonify({'error': 'Email required'}), 400

        # Generate 6-digit code
        code = str(random.randint(100000, 999999))
        expiry = datetime.utcnow() + timedelta(minutes=10)

        # Store code and expiry
        verification_codes[email] = {"code": code, "expiry": expiry}

        # For demo: print code (replace with email sending logic)
        send_email(email, "Your Verification Code", f"Your verification code is: {code}")


        return jsonify({'message': 'Verification code sent'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------- LOGIN ----------
@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        username_or_email = data.get('username_or_email', '').strip()
        password = data.get('password', '')

        if not username_or_email or not password:
            return jsonify({'error': 'Missing credentials'}), 400

        # Use anon_client for auth operations (recommended for sign_in_with_password)
        supabase = supabase_client.anon_client
        supabase_admin = supabase_client.client

        email = None
        
        # Resolve username to email if needed
        if '@' not in username_or_email:
            # Username provided - look it up in users table
            result = supabase_admin.table('users').select('email').eq('username', username_or_email.lower()).execute()
            if not result.data:
                print(f'❌ Login failed: Username "{username_or_email}" not found')
                return jsonify({'error': 'Invalid credentials'}), 401
            # Use lowercase email to match what was stored during signup
            email = result.data[0]['email'].lower() if result.data[0]['email'] else None
            print(f'✅ Resolved username "{username_or_email}" to email "{email}"')
        else:
            # Email provided - convert to lowercase to match signup behavior
            email = username_or_email.lower()
            print(f'✅ Using email directly (lowercased): "{email}"')

        # Login user with Supabase auth
        try:
            print(f'🔐 Attempting login for email: {email}')
            auth_response = supabase.auth.sign_in_with_password({
                'email': email,
                'password': password
            })
            print(f'✅ Auth response received: user={auth_response.user is not None}, session={auth_response.session is not None}')
        except Exception as auth_error:
            # Handle Supabase auth errors - log the actual error
            error_type = type(auth_error).__name__
            error_msg = str(auth_error)
            print(f'❌ Auth error: {error_type} - {error_msg}')
            
            # Check for specific error messages
            error_str_lower = error_msg.lower()
            if 'invalid login credentials' in error_str_lower or 'invalid_credentials' in error_str_lower:
                return jsonify({'error': 'Invalid credentials'}), 401
            elif 'email not confirmed' in error_str_lower or 'email_not_confirmed' in error_str_lower:
                return jsonify({'error': 'Email not confirmed. Please verify your email.'}), 401
            elif 'user not found' in error_str_lower:
                return jsonify({'error': 'Invalid credentials'}), 401
            else:
                # Return the actual error for debugging (in production, you might want to hide this)
                return jsonify({'error': f'Login failed: {error_msg}'}), 401

        if not auth_response or not auth_response.user:
            print('❌ No user in auth response')
            return jsonify({'error': 'Invalid credentials'}), 401

        if not auth_response.session:
            print('❌ No session in auth response')
            return jsonify({'error': 'Login failed: no session returned'}), 401

        # Fetch user profile from our users table
        profile = supabase_admin.table('users').select('*').eq('id', auth_response.user.id).execute()
        if not profile.data:
            print(f'❌ User profile not found for ID: {auth_response.user.id}')
            return jsonify({'error': 'User profile not found'}), 404

        user_profile = profile.data[0]
        print(f'✅ Login successful for user: {user_profile["username"]} ({user_profile["email"]})')

        return jsonify({
            'message': 'Login successful',
            'user': {
                'id': user_profile['id'],
                'email': user_profile['email'],
                'username': user_profile['username'],
                'role': user_profile['role'],
                'selectedCategories': user_profile.get('selected_categories', []),
                'profilePhotoUrl': user_profile.get('profile_photo_url'),
                'isEmailVerified': user_profile.get('is_email_verified', True),
            },
            'session': {
                'access_token': auth_response.session.access_token,
                'refresh_token': auth_response.session.refresh_token
            }
        }), 200

    except Exception as e:
        error_type = type(e).__name__
        error_msg = str(e)
        print(f'❌ Unexpected login error: {error_type} - {error_msg}')
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Login failed: {error_msg}'}), 500



# ---------- LOGOUT ----------
@auth_bp.route('/logout', methods=['POST'])
@token_required
def logout(current_user):
    try:
        supabase = supabase_client.client
        supabase.auth.sign_out()
        return jsonify({'message': 'Logout successful'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ---------- GET CURRENT USER ----------
@auth_bp.route('/me', methods=['GET'])
@token_required
def get_current_user(current_user):
    try:
        supabase = supabase_client.client
        profile = supabase.table('users').select('*').eq('id', current_user.user.id).execute()

        if not profile.data:
            return jsonify({'error': 'User not found'}), 404

        user_profile = profile.data[0]

        # Return response with properly formatted user data (consistent format)
        return jsonify({
            'user': {
                'id': user_profile['id'],
                'email': user_profile['email'],
                'username': user_profile['username'],
                'role': user_profile['role'],
                'selectedCategories': user_profile.get('selected_categories', []),
                'profilePhotoUrl': user_profile.get('profile_photo_url'),
                'isEmailVerified': user_profile.get('is_email_verified', True),
            }
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ---------- RESET PASSWORD ----------
@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    try:
        data = request.get_json()
        email = data.get('email', '').strip()

        if not email:
            return jsonify({'error': 'Email required'}), 400

        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400

        supabase = supabase_client.client
        supabase.auth.reset_password_email(email)

        return jsonify({'message': 'Password reset email sent'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ---------- EMAIL VERIFICATION ----------
@auth_bp.route('/verify-email', methods=['POST'])
def verify_email():
    """
    Verify email with custom verification code and create user account.
    This endpoint accepts verification_code, email, username, password, and role.
    The verification code is verified client-side before calling this endpoint.
    """
    try:
        data = request.get_json()
        
        # Get all required fields
        email = data.get('email', '').strip().lower()
        username = data.get('username', '').strip().lower()
        password = data.get('password', '')
        verification_code = data.get('verification_code', '').strip()
        role = data.get('role', 'participant')
        # --------- SERVER-SIDE VERIFICATION CODE CHECK ---------
        stored = verification_codes.get(email)
        if not stored:
         return jsonify({'error': 'Invalid or expired verification code'}), 400

        if datetime.utcnow() > stored['expiry']:
         del verification_codes[email]
         return jsonify({'error': 'Verification code expired'}), 400

        if verification_code != stored['code']:
          return jsonify({'error': 'Invalid verification code'}), 400

# Remove code after successful verification
        del verification_codes[email]
# --------------------------------------------------------

        # Validate required fields
        if not email or not username or not password or not verification_code:
            return jsonify({'error': 'Missing required fields'}), 400
        
        if not validate_email(email):
            return jsonify({'error': 'Invalid email format'}), 400
        
        if not validate_username(username):
            return jsonify({'error': 'Invalid username'}), 400
        
        if len(password) < 6:
            return jsonify({'error': 'Password too short'}), 400
        
        if len(verification_code) != 6:
            return jsonify({'error': 'Invalid verification code format'}), 400

        supabase = supabase_client.client

        # Check if username already exists
        existing_username = supabase.table('users').select('id').eq('username', username).execute()
        if existing_username.data:
            return jsonify({'error': 'Username already taken'}), 400

        # Check if email already exists
        existing_email = supabase.table('users').select('id').eq('email', email).execute()
        if existing_email.data:
            return jsonify({'error': 'Email already registered'}), 400

        # Create auth user in Supabase
        # Note: Verification code is verified client-side, so we proceed with account creation
        auth_response = supabase.auth.sign_up({
            'email': email,
            'password': password,
            'options': {
                'email_redirect_to': None,  # Disable email confirmation
            }
        })

        if not auth_response.user:
            return jsonify({'error': 'Failed to create account'}), 400

        user_id = auth_response.user.id

        # Insert public profile
        user_data = {
            'id': user_id,
            'email': email,
            'username': username,
            'role': role,
            'selected_categories': [],
            'profile_photo_url': None,
            'is_email_verified': True  # Set to True since verification code was verified
        }

        supabase.table('users').insert(user_data).execute()

        # If no session was returned from sign_up (happens when email confirmation is enabled),
        # sign in the user to get a session
        if not auth_response.session:
            # Sign in to get session tokens
            login_response = supabase.auth.sign_in_with_password({
                'email': email,
                'password': password
            })
            
            if not login_response.session:
                return jsonify({'error': 'Account created but failed to get session. Please try logging in.'}), 500
            
            session = login_response.session
        else:
            session = auth_response.session

        # Get the created user profile
        profile = supabase.table('users').select('*').eq('id', user_id).execute()
        
        if not profile.data:
            return jsonify({'error': 'Failed to retrieve user profile'}), 500

        user_profile = profile.data[0]

        # Return response with properly formatted user data
        return jsonify({
            'message': 'Email verified successfully',
            'user': {
                'id': user_profile['id'],
                'email': user_profile['email'],
                'username': user_profile['username'],
                'role': user_profile['role'],
                'selectedCategories': user_profile.get('selected_categories', []),
                'profilePhotoUrl': user_profile.get('profile_photo_url'),
                'isEmailVerified': user_profile.get('is_email_verified', True),
            },
            'session': {
                'access_token': session.access_token,
                'refresh_token': session.refresh_token
            }
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ---------- CHECK USERNAME ----------
@auth_bp.route('/check-username', methods=['GET'])
def check_username():
    try:
        username = request.args.get('username', '').strip().lower()

        if not username:
            return jsonify({'error': 'Username is required'}), 400

        supabase = supabase_client.client
        result = supabase.table('users').select('id').eq('username', username).execute()

        return jsonify({'exists': len(result.data) > 0}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ---------- RESEND VERIFICATION EMAIL ----------
@auth_bp.route('/resend-verification', methods=['POST'])
def resend_verification():
    """Resend verification email"""
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()
        
        if not email:
            return jsonify({'error': 'Email required'}), 400

        supabase = supabase_client.client
        supabase.auth.resend({
            'type': 'signup',
            'email': email
        })

        return jsonify({'message': 'Verification email sent'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
