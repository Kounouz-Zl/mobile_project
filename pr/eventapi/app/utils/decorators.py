from functools import wraps
from flask import request, jsonify
from app.utils.supabase_client import supabase_client

def token_required(f):
    """
    Decorator to protect routes.
    Use this on routes that need authentication.
    
    Example:
    @token_required
    def my_route(current_user):
        # Only logged-in users can access
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from Authorization header
        # Format: "Authorization: Bearer eyJhbGc..."
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                # Split "Bearer <token>" and get token part
                token = auth_header.split(' ')[1]
            except IndexError:
                return jsonify({'error': 'Invalid token format'}), 401
        
        # If no token found
        if not token:
            return jsonify({'error': 'Authentication token is missing'}), 401
        
        try:
            # Verify token with Supabase
            user = supabase_client.get_user_from_token(token)
            if not user or not user.user:
                return jsonify({'error': 'Invalid or expired token'}), 401
            
            # Pass user to the route function
            return f(current_user=user, *args, **kwargs)
            
        except Exception as e:
            # Return detailed error for debugging (remove in production)
            error_msg = str(e)
            return jsonify({'error': f'Token validation failed: {error_msg}'}), 401
    
    return decorated

def organizer_required(f):
    """
    Decorator to restrict access to organizers only.
    Checks if user is authenticated AND has organizer role.
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(' ')[1]
            except IndexError:
                return jsonify({'error': 'Invalid token format'}), 401
        
        if not token:
            return jsonify({'error': 'Authentication required'}), 401
        
        try:
            # Verify token
            user = supabase_client.get_user_from_token(token)
            if not user or not user.user:
                return jsonify({'error': 'Invalid token'}), 401
            
            # Check if user has organizer role
            supabase = supabase_client.client
            result = supabase.table('users').select('role').eq('id', user.user.id).execute()
            
            if not result.data or result.data[0]['role'] != 'organizer':
                return jsonify({'error': 'Organizer access required'}), 403
            
            # User is authenticated and is organizer
            return f(current_user=user, *args, **kwargs)
            
        except Exception as e:
            error_msg = str(e)
            return jsonify({'error': f'Token validation failed: {error_msg}'}), 401
    
    return decorated