from flask import Blueprint, request, jsonify
from app.utils.supabase_client import supabase_client
from app.utils.decorators import token_required
from app.routes.notifications import create_notification

organizations_bp = Blueprint('organizations', __name__, url_prefix='/api/organizations')

# ========== GET ORGANIZATION PROFILE ==========
@organizations_bp.route('/<organization_id>/profile', methods=['GET'])
@token_required
def get_organization_profile(current_user, organization_id):
    """Get organization profile by user_id. Creates basic profile if doesn't exist."""
    try:
        supabase = supabase_client.client
        
        # Get user info first
        user = supabase.table('users').select('id, username, email, profile_photo_url, role').eq('id', organization_id).execute()
        if not user.data:
            return jsonify({'error': 'Organization not found'}), 404
        
        user_data = user.data[0]
        
        # Check if role is organization
        if user_data.get('role') != 'organization':
            return jsonify({'error': 'User is not an organization'}), 403
        
        # Get organization profile (may not exist)
        profile = supabase.table('organization_profiles').select('*').eq('user_id', organization_id).execute()
        
        # If profile doesn't exist, create a basic one with just the username
        if not profile.data:
            profile_data = {
                'user_id': organization_id,
                'name': user_data.get('username', 'Organization'),
                'bio': '',
                'field': '',
                'location': '',
            }
        else:
            profile_data = profile.data[0]
        
        # Check if current user follows this organization
        is_following = False
        if current_user.user.id != organization_id:
            follow = supabase.table('organization_follows').select('*').eq('follower_id', current_user.user.id).eq('organization_id', organization_id).execute()
            is_following = len(follow.data) > 0
        
        # Get follower count
        followers = supabase.table('organization_follows').select('id', count='exact').eq('organization_id', organization_id).execute()
        follower_count = followers.count if hasattr(followers, 'count') else len(followers.data) if followers.data else 0
        
        # Get events created by this organization
        events = supabase.table('events').select('*').eq('created_by', organization_id).order('created_at', desc=True).limit(10).execute()
        
        return jsonify({
            'profile': {
                **profile_data,
                'username': user_data['username'],
                'profile_photo_url': user_data.get('profile_photo_url'),
                'is_following': is_following,
                'follower_count': follower_count,
            },
            'events': events.data or []
        }), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== CREATE/UPDATE ORGANIZATION PROFILE ==========
@organizations_bp.route('/profile', methods=['POST', 'PUT'])
@token_required
def create_update_organization_profile(current_user):
    """Create or update organization profile"""
    try:
        # Check if user is an organization
        supabase = supabase_client.client
        user = supabase.table('users').select('role').eq('id', current_user.user.id).execute()
        
        if not user.data or user.data[0]['role'] != 'organization':
            return jsonify({'error': 'Only organizations can create profiles'}), 403
        
        data = request.get_json()
        name = data.get('name', '')
        bio = data.get('bio', '')
        field = data.get('field', '')
        location = data.get('location', '')
        
        if not name:
            return jsonify({'error': 'Name is required'}), 400
        
        # Check if profile exists
        existing = supabase.table('organization_profiles').select('*').eq('user_id', current_user.user.id).execute()
        
        profile_data = {
            'user_id': current_user.user.id,
            'name': name,
            'bio': bio,
            'field': field,
            'location': location,
            'updated_at': 'now()'
        }
        
        if existing.data:
            # Update existing profile
            result = supabase.table('organization_profiles').update(profile_data).eq('user_id', current_user.user.id).execute()
        else:
            # Create new profile
            result = supabase.table('organization_profiles').insert(profile_data).execute()
        
        return jsonify({
            'message': 'Organization profile saved successfully',
            'profile': result.data[0] if result.data else None
        }), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== FOLLOW ORGANIZATION ==========
@organizations_bp.route('/<organization_id>/follow', methods=['POST'])
@token_required
def follow_organization(current_user, organization_id):
    """Follow an organization"""
    try:
        supabase = supabase_client.client
        
        # Check if organization exists and is actually an organization
        org_user = supabase.table('users').select('role').eq('id', organization_id).execute()
        if not org_user.data:
            return jsonify({'error': 'Organization not found'}), 404
        
        if org_user.data[0]['role'] != 'organization':
            return jsonify({'error': 'User is not an organization'}), 400
        
        if current_user.user.id == organization_id:
            return jsonify({'error': 'Cannot follow yourself'}), 400
        
        # Check if already following
        existing = supabase.table('organization_follows').select('*').eq('follower_id', current_user.user.id).eq('organization_id', organization_id).execute()
        
        if existing.data:
                # Return current follower count
                followers = supabase.table('organization_follows').select('id', count='exact').eq('organization_id', organization_id).execute()
                follower_count = followers.count if hasattr(followers, 'count') else len(followers.data) if followers.data else 0
                return jsonify({'message': 'Already following this organization', 'follower_count': follower_count}), 200
        
        # Create follow
        supabase.table('organization_follows').insert({
            'follower_id': current_user.user.id,
            'organization_id': organization_id
        }).execute()

        # Return updated follower count
        followers = supabase.table('organization_follows').select('id', count='exact').eq('organization_id', organization_id).execute()
        follower_count = followers.count if hasattr(followers, 'count') else len(followers.data) if followers.data else 0

        print(f'User {current_user.user.id} followed organization {organization_id}. followers={follower_count}')

        return jsonify({'message': 'Successfully followed organization', 'follower_count': follower_count}), 201
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== UNFOLLOW ORGANIZATION ==========
@organizations_bp.route('/<organization_id>/unfollow', methods=['POST'])
@token_required
def unfollow_organization(current_user, organization_id):
    """Unfollow an organization"""
    try:
        supabase = supabase_client.client
        
        # Remove follow
        supabase.table('organization_follows').delete().eq('follower_id', current_user.user.id).eq('organization_id', organization_id).execute()

        # Return updated follower count
        followers = supabase.table('organization_follows').select('id', count='exact').eq('organization_id', organization_id).execute()
        follower_count = followers.count if hasattr(followers, 'count') else len(followers.data) if followers.data else 0

        print(f'User {current_user.user.id} unfollowed organization {organization_id}. followers={follower_count}')

        return jsonify({'message': 'Successfully unfollowed organization', 'follower_count': follower_count}), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== GET FOLLOWED ORGANIZATIONS ==========
@organizations_bp.route('/following', methods=['GET'])
@token_required
def get_followed_organizations(current_user):
    """Get list of organizations the user follows"""
    try:
        supabase = supabase_client.client
        
        # Get follows
        follows = supabase.table('organization_follows').select('organization_id').eq('follower_id', current_user.user.id).execute()
        
        if not follows.data:
            return jsonify({'organizations': []}), 200
        
        org_ids = [f['organization_id'] for f in follows.data]
        
        # Get organization profiles and user info for the org ids
        profiles_resp = supabase.table('organization_profiles').select('*').in_('user_id', org_ids).execute()
        users_resp = supabase.table('users').select('id, username, profile_photo_url').in_('id', org_ids).execute()

        profiles_map = {}
        if profiles_resp.data:
            for p in profiles_resp.data:
                profiles_map[p['user_id']] = p

        user_map = {}
        if users_resp.data:
            for u in users_resp.data:
                user_map[u['id']] = u

        result = []
        for oid in org_ids:
            profile = profiles_map.get(oid)
            user_info = user_map.get(oid, {})

            if profile:
                item = {**profile}
            else:
                # Construct a minimal profile if none exists
                item = {
                    'user_id': oid,
                    'name': user_info.get('username', 'Organization'),
                    'bio': '',
                    'field': '',
                    'location': '',
                }

            # Merge user info
            item['username'] = user_info.get('username')
            item['profile_photo_url'] = user_info.get('profile_photo_url')

            result.append(item)

        return jsonify({'organizations': result}), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== GET ORGANIZATION EVENTS ==========
@organizations_bp.route('/<organization_id>/events', methods=['GET'])
@token_required
def get_organization_events(current_user, organization_id):
    """Get all events created by an organization"""
    try:
        supabase = supabase_client.client
        
        events = supabase.table('events').select('*').eq('created_by', organization_id).order('created_at', desc=True).execute()
        
        return jsonify({'events': events.data or []}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

