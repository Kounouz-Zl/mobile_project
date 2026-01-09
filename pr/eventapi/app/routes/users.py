
from flask import Blueprint, request, jsonify
from app.utils.supabase_client import supabase_client
from app.utils.decorators import token_required
import re

users_bp = Blueprint('users', __name__, url_prefix='/api/users')

def validate_username(username):
    pattern = r'^[a-zA-Z0-9_]{3,20}'
    return re.match(pattern, username) is not None

# ========== GET USER BY ID ==========
@users_bp.route('/<user_id>', methods=['GET'])
@token_required
def get_user(current_user, user_id):
    """Get user profile by ID"""
    try:
        supabase = supabase_client.client
        result = supabase.table('users').select('*').eq('id', user_id).execute()
        
        if not result.data:
            return jsonify({'error': 'User not found'}), 404
        
        return jsonify({'user': result.data[0]}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== UPDATE USERNAME ==========
@users_bp.route('/profile/username', methods=['PUT'])
@token_required
def update_username(current_user):
    """
    Update username.
    
    Request Body:
    {
        "username": "newusername"
    }
    """
    try:
        data = request.get_json()
        username = data.get('username', '').strip()
        
        if not username:
            return jsonify({'error': 'Username cannot be empty'}), 400
        
        if not validate_username(username):
            return jsonify({'error': 'Username must be 3-20 characters, letters, numbers, and underscores only'}), 400
        
        supabase = supabase_client.client
        
        # Check if username exists (excluding current user)
        existing = supabase.table('users').select('id').eq('username', username.lower()).execute()
        
        if existing.data and existing.data[0]['id'] != current_user.user.id:
            return jsonify({'error': 'Username already taken'}), 400
        
        # Update username
        result = supabase.table('users').update({'username': username.lower()}).eq('id', current_user.user.id).execute()
        
        return jsonify({
            'message': 'Username updated successfully',
            'user': result.data[0]
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== UPLOAD PROFILE PHOTO ==========
@users_bp.route('/profile/photo/upload', methods=['POST'])
@token_required
def upload_profile_photo(current_user):
    """Upload profile photo to Supabase storage"""
    try:
        if 'photo' not in request.files:
            return jsonify({'error': 'No photo file provided'}), 400
        
        file = request.files['photo']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Validate file type
        allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
        from werkzeug.utils import secure_filename
        import uuid
        filename = secure_filename(file.filename)
        file_ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else ''
        
        if file_ext not in allowed_extensions:
            return jsonify({'error': f'Invalid file type. Allowed: {", ".join(allowed_extensions)}'}), 400
        
        # Generate unique filename
        unique_filename = f"{uuid.uuid4()}.{file_ext}"
        file_path = f"profiles/{current_user.user.id}/{unique_filename}"
        
        supabase = supabase_client.client
        
        # Read file content
        file_content = file.read()
        
        # Determine content type
        content_type = f'image/{file_ext}' if file_ext != 'jpg' else 'image/jpeg'
        
        # Upload to Supabase storage
        try:
            # Upload to profiles bucket
            response = supabase.storage.from_('profiles').upload(
                file_path,
                file_content,
                file_options={'content-type': content_type, 'upsert': 'true'}
            )
            
            # Get public URL
            public_url = supabase.storage.from_('profiles').get_public_url(file_path)
            
            # Update user profile with new photo URL
            result = supabase.table('users').update({'profile_photo_url': public_url}).eq('id', current_user.user.id).execute()
            
            return jsonify({
                'message': 'Profile photo uploaded successfully',
                'url': public_url,
                'user': result.data[0] if result.data else None
            }), 200
            
        except Exception as storage_error:
            print(f'Storage upload error: {storage_error}')
            return jsonify({'error': f'Failed to upload photo: {str(storage_error)}'}), 500
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== UPDATE PROFILE PHOTO ==========
@users_bp.route('/profile/photo', methods=['PUT'])
@token_required
def update_profile_photo(current_user):
    """
    Update profile photo URL.
    
    Request Body:
    {
        "photo_url": "https://..."
    }
    """
    try:
        data = request.get_json()
        photo_url = data.get('photo_url', '')
        
        supabase = supabase_client.client
        result = supabase.table('users').update({'profile_photo_url': photo_url}).eq('id', current_user.user.id).execute()
        
        return jsonify({
            'message': 'Profile photo updated successfully',
            'user': result.data[0]
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== DELETE PROFILE PHOTO ==========
@users_bp.route('/profile/photo', methods=['DELETE'])
@token_required
def delete_profile_photo(current_user):
    """Delete profile photo"""
    try:
        supabase = supabase_client.client
        result = supabase.table('users').update({'profile_photo_url': None}).eq('id', current_user.user.id).execute()
        
        return jsonify({'message': 'Profile photo deleted successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ========== UPDATE CATEGORIES ==========
@users_bp.route('/profile/categories', methods=['PUT'])
@token_required
def update_categories(current_user):
    """
    Update selected categories.
    
    Request Body:
    {
        "categories": ["Music", "Sports", "Tech"]
    }
    """
    try:
        data = request.get_json()
        categories = data.get('categories', [])
        
        if not isinstance(categories, list):
            return jsonify({'error': 'Categories must be an array'}), 400
        
        supabase = supabase_client.client
        result = supabase.table('users').update({'selected_categories': categories}).eq('id', current_user.user.id).execute()
        
        return jsonify({
            'message': 'Categories updated successfully',
            'user': result.data[0]
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET FAVORITES ==========
@users_bp.route('/favorites', methods=['GET'])
@token_required
def get_favorites(current_user):
    """Get user's favorite events"""
    try:
        supabase = supabase_client.client
        
        # Get favorite event IDs
        favorites = supabase.table('favorites').select('event_id').eq('user_id', current_user.user.id).execute()
        
        if not favorites.data:
            return jsonify({'favorites': []}), 200
        
        event_ids = [f['event_id'] for f in favorites.data]
        
        # Get events
        events = supabase.table('events').select('*').in_('id', event_ids).execute()
        
        return jsonify({'favorites': events.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== ADD FAVORITE ==========
@users_bp.route('/favorites/<event_id>', methods=['POST'])
@token_required
def add_favorite(current_user, event_id):
    """Add event to favorites"""
    try:
        supabase = supabase_client.client
        
        # Check if already favorited
        existing = supabase.table('favorites').select('*').eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        if existing.data:
            return jsonify({'message': 'Event already in favorites'}), 200
        
        supabase.table('favorites').insert({
            'event_id': event_id,
            'user_id': current_user.user.id
        }).execute()
        
        return jsonify({'message': 'Event added to favorites'}), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== REMOVE FAVORITE ==========
@users_bp.route('/favorites/<event_id>', methods=['DELETE'])
@token_required
def remove_favorite(current_user, event_id):
    """Remove event from favorites"""
    try:
        supabase = supabase_client.client
        supabase.table('favorites').delete().eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        return jsonify({'message': 'Event removed from favorites'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== CHECK IF FAVORITED ==========
@users_bp.route('/favorites/<event_id>/check', methods=['GET'])
@token_required
def check_favorite(current_user, event_id):
    """Check if event is favorited"""
    try:
        supabase = supabase_client.client
        result = supabase.table('favorites').select('*').eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        return jsonify({'is_favorited': len(result.data) > 0}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ========== CREATE ORGANIZER REQUEST ==========
@users_bp.route('/organizer-request', methods=['POST'])
@token_required
def create_organizer_request(current_user):
    """
    Create organizer request.
    
    Request Body:
    {
        "organization_name": "My Organization",
        "social_media_link": "https://..."
    }
    """
    try:
        data = request.get_json()
        organization_name = data.get('organization_name', '')
        social_media_link = data.get('social_media_link', '')
        
        if not organization_name or not social_media_link:
            return jsonify({'error': 'Organization name and social media link are required'}), 400
        
        supabase = supabase_client.client
        
        # Check if request already exists
        existing = supabase.table('organizer_requests').select('*').eq('user_id', current_user.user.id).execute()
        
        if existing.data:
            return jsonify({'error': 'Request already exists'}), 400
        
        result = supabase.table('organizer_requests').insert({
            'user_id': current_user.user.id,
            'organization_name': organization_name,
            'social_media_link': social_media_link,
            'status': 'pending'
        }).execute()
        
        return jsonify({
            'message': 'Organizer request submitted successfully',
            'request': result.data[0]
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET ORGANIZER STATUS ==========
@users_bp.route('/organizer-request/status', methods=['GET'])
@token_required
def get_organizer_status(current_user):
    """Get organizer request status"""
    try:
        supabase = supabase_client.client
        result = supabase.table('organizer_requests').select('*').eq('user_id', current_user.user.id).execute()
        
        if not result.data:
            return jsonify({'status': None}), 200
        
        return jsonify({'request': result.data[0]}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== REQUEST ACCOUNT DELETION ==========
@users_bp.route('/delete-account/request', methods=['POST'])
@token_required
def request_account_deletion(current_user):
    """Request account deletion - sends verification code to email"""
    try:
        from app.utils.email_utils import send_email
        import random
        from datetime import datetime, timedelta
        
        supabase = supabase_client.client
        
        # Get user email
        user = supabase.table('users').select('email').eq('id', current_user.user.id).execute()
        if not user.data:
            return jsonify({'error': 'User not found'}), 404
        
        email = user.data[0]['email']
        
        # Generate 6-digit verification code
        code = str(random.randint(100000, 999999))
        
        # Store code with expiry (10 minutes)
        from app.routes.auth import verification_codes
        verification_codes[f'delete_{email}'] = {
            'code': code,
            'expiry': datetime.utcnow() + timedelta(minutes=10),
            'user_id': current_user.user.id
        }
        
        # Send email with verification code
        email_body = f"""
Hello,

You have requested to delete your account. 

Your verification code is: {code}

This code will expire in 10 minutes.

If you did not request this, please ignore this email.

Best regards,
Event Team
"""
        send_email(email, 'Account Deletion Verification Code', email_body)
        
        return jsonify({
            'message': 'Verification code sent to your email',
            'expires_in': 600  # 10 minutes in seconds
        }), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== CONFIRM ACCOUNT DELETION ==========
@users_bp.route('/delete-account/confirm', methods=['POST'])
@token_required
def confirm_account_deletion(current_user):
    """Confirm account deletion with verification code"""
    try:
        from datetime import datetime
        from app.routes.auth import verification_codes
        
        data = request.get_json()
        verification_code = data.get('verification_code', '').strip()
        
        if not verification_code:
            return jsonify({'error': 'Verification code is required'}), 400
        
        supabase = supabase_client.client
        
        # Get user email
        user = supabase.table('users').select('email').eq('id', current_user.user.id).execute()
        if not user.data:
            return jsonify({'error': 'User not found'}), 404
        
        email = user.data[0]['email']
        
        # Verify code
        stored = verification_codes.get(f'delete_{email}')
        if not stored:
            return jsonify({'error': 'Invalid or expired verification code'}), 400
        
        if datetime.utcnow() > stored['expiry']:
            del verification_codes[f'delete_{email}']
            return jsonify({'error': 'Verification code expired'}), 400
        
        if verification_code != stored['code']:
            return jsonify({'error': 'Invalid verification code'}), 400
        
        # Verify user_id matches
        if stored['user_id'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Delete code
        del verification_codes[f'delete_{email}']
        
        # Delete user from auth (this will cascade delete from users table due to ON DELETE CASCADE)
        # Note: We need to use admin client for this
        try:
            # Get auth user ID
            auth_user = supabase.auth.admin.get_user_by_id(current_user.user.id)
            if auth_user:
                # Delete auth user (this requires admin privileges)
                supabase.auth.admin.delete_user(current_user.user.id)
        except Exception as auth_error:
            # If admin delete fails, at least delete from public.users
            # The auth user will remain but public profile will be deleted
            print(f'Warning: Could not delete auth user: {auth_error}')
        
        # Delete user profile (cascade will handle related data)
        supabase.table('users').delete().eq('id', current_user.user.id).execute()
        
        return jsonify({'message': 'Account deleted successfully'}), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500