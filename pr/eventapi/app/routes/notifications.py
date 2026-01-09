from flask import Blueprint, request, jsonify
from app.utils.supabase_client import supabase_client
from app.utils.decorators import token_required
from datetime import datetime

notifications_bp = Blueprint('notifications', __name__, url_prefix='/api/notifications')

def create_notification(supabase, user_id, notif_type, title, message, related_id=None):
    """Helper function to create a notification"""
    try:
        # Build notification data (don't include created_at if it's auto-generated)
        notification_data = {
            'user_id': user_id,
            'type': notif_type,
            'title': title,
            'message': message,
            'related_id': related_id,
            'is_read': False
        }
        # Only include created_at if the column exists (Supabase often auto-generates timestamps)
        # notification_data['created_at'] = datetime.utcnow().isoformat()
        
        notification = supabase.table('notifications').insert(notification_data).execute()
        return notification.data[0] if notification.data else None
    except Exception as e:
        print(f'Error creating notification: {e}')
        return None

# ========== GET ALL NOTIFICATIONS ==========
@notifications_bp.route('/', methods=['GET'])
@token_required
def get_notifications(current_user):
    """Get all notifications for current user"""
    try:
        supabase = supabase_client.client
        
        # Order by id instead of created_at (since created_at column may not exist)
        notifications_result = supabase.table('notifications').select('*').eq('user_id', current_user.user.id).order('id', desc=True).execute()
        
        notifications_list = notifications_result.data if notifications_result.data else []
        
        return jsonify(notifications_list), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== MARK AS READ ==========
@notifications_bp.route('/<notification_id>/read', methods=['PUT'])
@token_required
def mark_as_read(current_user, notification_id):
    """Mark a notification as read"""
    try:
        supabase = supabase_client.client
        
        # Verify ownership
        notification = supabase.table('notifications').select('user_id').eq('id', notification_id).execute()
        if not notification.data:
            return jsonify({'error': 'Notification not found'}), 404
        
        if notification.data[0]['user_id'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Update
        supabase.table('notifications').update({'is_read': True}).eq('id', notification_id).execute()
        
        return jsonify({'message': 'Notification marked as read'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== DELETE NOTIFICATION ==========
@notifications_bp.route('/<notification_id>', methods=['DELETE'])
@token_required
def delete_notification(current_user, notification_id):
    """Delete a notification"""
    try:
        supabase = supabase_client.client
        
        # Verify ownership
        notification = supabase.table('notifications').select('user_id').eq('id', notification_id).execute()
        if not notification.data:
            return jsonify({'error': 'Notification not found'}), 404
        
        if notification.data[0]['user_id'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        supabase.table('notifications').delete().eq('id', notification_id).execute()
        
        return jsonify({'message': 'Notification deleted'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== DELETE ALL NOTIFICATIONS ==========
@notifications_bp.route('/all', methods=['DELETE'])
@token_required
def delete_all_notifications(current_user):
    """Delete all notifications for current user"""
    try:
        supabase = supabase_client.client
        
        supabase.table('notifications').delete().eq('user_id', current_user.user.id).execute()
        
        return jsonify({'message': 'All notifications deleted'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET UNREAD COUNT ==========
@notifications_bp.route('/unread-count', methods=['GET'])
@token_required
def get_unread_count(current_user):
    """Get count of unread notifications"""
    try:
        supabase = supabase_client.client
        
        result = supabase.table('notifications').select('id', count='exact').eq('user_id', current_user.user.id).eq('is_read', False).execute()
        
        count = result.count if hasattr(result, 'count') else len(result.data) if result.data else 0
        
        return jsonify({'count': count}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

